package main

import "core:strings"
import rl "vendor:raylib"
import rlgl "vendor:raylib/rlgl"
import b3 "vendor:box3d"

WIDTH  :: 720
HEIGHT :: 720

RacePhase :: enum i32 {
	Countdown,
	Racing,
	Finished,
}

State :: struct {
	world:         b3.WorldId,
	camera:        rl.Camera3D,
	race_phase:    RacePhase,
	countdown:     f32,
	race_time:     f64,
	finish_sensor: b3.ShapeId,
}

state: State
frame_count: int

DebugFlags :: struct {
	wireframe:   bool,
	no_cull:     bool,
	show_origin: bool,
	show_test:   bool,
}
debug := DebugFlags{wireframe = true, show_origin = true, show_test = true}
debug_test_model: rl.Model  // reference model for pipeline verification

init :: proc() {
	rl.SetConfigFlags({.VSYNC_HINT})
	rl.InitWindow(WIDTH, HEIGHT, "raylib-6-jam")
	rl.InitAudioDevice()

	world_def := b3.DefaultWorldDef()
	world_def.gravity = b3.Vec3{0, -10, 0}
	state.world = b3.CreateWorld(world_def)

	init_track()
	init_stance()
	init_time()
	init_broom()
	init_telemetry()

	start := get_start_position()
	state.camera = rl.Camera3D {
		position   = start + {-30, 30, -30},
		target     = start,
		up         = {0, 1, 0},
		fovy       = 60,
		projection = .PERSPECTIVE,
	}

	state.race_phase = .Countdown
	state.countdown = 3.0
	state.race_time = 0

	test_mesh := rl.GenMeshPlane(10, 10, 1, 1)
	debug_test_model = rl.LoadModelFromMesh(test_mesh)

	rl.SetTargetFPS(60)
}

update :: proc() -> bool {
	dt := rl.GetFrameTime()
	telemetry.accumulator += dt

	if rl.IsKeyPressed(.TAB) || rl.IsKeyPressed(.R) {
		restart_race()
	}
	if rl.IsKeyPressed(.V)    { debug.wireframe = !debug.wireframe }
	if rl.IsKeyPressed(.C)    { debug.no_cull = !debug.no_cull }
	if rl.IsKeyPressed(.G)    { debug.show_origin = !debug.show_origin }
	if rl.IsKeyPressed(.T)    { debug.show_test = !debug.show_test }
	if rl.IsKeyPressed(.N)    { debug.no_cull = true; debug.wireframe = false }

	if state.race_phase == .Countdown {
		state.countdown -= dt
		if state.countdown <= 0 {
			state.race_phase = .Racing
			state.countdown = 0
		}
	}

	for telemetry.accumulator >= FIXED_DT {
		telemetry.accumulator -= FIXED_DT
		if !tick() {
			break
		}
	}

	rl.BeginDrawing()
	rl.ClearBackground(rl.SKYBLUE)

	rl.BeginMode3D(state.camera)
	draw_track()
	draw_finish_line()
	draw_broom()
	if debug.show_origin {
		rl.DrawSphere({0, 0, 0}, 0.5, rl.RED)
		rl.DrawCube({0, 0, 0}, 0.2, 0.2, 0.2, rl.WHITE)
		rl.DrawGrid(20, 10)
	}
	if debug.show_test {
		rl.DrawModelWires(debug_test_model, {6, 0, 0}, 1, rl.BLUE)
	}
	rl.EndMode3D()

	draw_hud()

	hand_status := hand_tracking_status()
	rl.DrawText(strings.clone_to_cstring(hand_tracking_status_text(hand_status), context.temp_allocator), 10, 10, 14, rl.DARKGRAY)

	if hand_tracking_state.num_hands > 0 {
		rl.DrawCircleV(hand_tip_screen_pos(0), 12, rl.GREEN)
	}

	if frame_count == 1 { rl.TakeScreenshot("screenshot.png") }
	frame_count += 1
	if rl.IsKeyPressed(.S) { rl.TakeScreenshot("screenshot.png") }
	rl.DrawFPS(10, 170)
	rl.EndDrawing()

	when ODIN_OS == .JS {
		return true
	} else {
		return !rl.WindowShouldClose()
	}
}



draw_finish_line :: proc() {
	finish := get_track_finish()
	rl.DrawCube(finish + {0, -0.2, 0}, 10, 0.5, 0.2, rl.WHITE)
	rl.DrawCube(finish + {0, 0.3, 0}, 10, 0.1, 0.2, {200, 200, 200, 255})
}

draw_track :: proc() {
	model := get_track_mesh_model()
	if model.meshes == nil {
		rl.DrawText("NO MESH", 10, 80, 14, rl.RED)
		return
	}
	m := model.meshes[0]
	rl.DrawText(rl.TextFormat("verts=%d tris=%d", m.vertexCount, m.triangleCount), 10, 80, 14, rl.RED)

	cam := state.camera
	start := get_start_position()
	finish := get_track_finish()
	rl.DrawText(rl.TextFormat("cam=(%.1f,%.1f,%.1f) tgt=(%.1f,%.1f,%.1f)", cam.position.x, cam.position.y, cam.position.z, cam.target.x, cam.target.y, cam.target.z), 10, 95, 14, rl.YELLOW)
	rl.DrawText(rl.TextFormat("start=(%.1f,%.1f,%.1f)", start.x, start.y, start.z), 10, 110, 14, rl.YELLOW)
	rl.DrawText(rl.TextFormat("finish=(%.1f,%.1f,%.1f)", finish.x, finish.y, finish.z), 10, 125, 14, rl.YELLOW)
	rl.DrawText(rl.TextFormat("dbg: [V]wf=%v [C]nocull=%v [G]grid=%v [T]test=%v [N]solid", debug.wireframe, debug.no_cull, debug.show_origin, debug.show_test), 10, 140, 14, rl.LIME)
	rl.DrawText(rl.TextFormat("vaoId=%d vboId[0]=%d", model.meshes[0].vaoId, model.meshes[0].vboId[0] if model.meshes[0].vboId != nil else 0), 10, 155, 14, rl.ORANGE)

	if debug.no_cull {
		rlgl.DisableBackfaceCulling()
	}
	defer if debug.no_cull {
		rlgl.EnableBackfaceCulling()
	}

	if debug.wireframe {
		rl.DrawModelWires(model, {0, 0, 0}, 1, rl.WHITE)
	} else {
		rl.DrawModel(model, {0, 0, 0}, 1, rl.WHITE)
	}
}

draw_broom :: proc() {
	pos := get_broom_position()
	fwd := get_broom_forward()

	hover_y := pos.y + 0.6
	hover_pos := rl.Vector3{pos.x, hover_y, pos.z}

	rl.DrawCube(hover_pos, 0.1, 0.1, 0.6, rl.DARKBROWN)
	rl.DrawCube(hover_pos + fwd * 0.35, 0.15, 0.05, 0.1, {100, 60, 30, 255})

	rider_pos := hover_pos - fwd * 0.15
	rider_pos.y += 0.2
	rl.DrawCylinder(rider_pos, 0.02, 0.12, 0.25, 6, rl.DARKGREEN)

	col := stance_colors[get_current_stance()]
	col.a = 100
	rl.DrawSphere(hover_pos, 0.4, col)
}

restart_race :: proc() {
	finish_run()
	reset_broom()
	init_stance()
	init_time()
	state.race_phase = .Countdown
	state.countdown = 3.0
	state.race_time = 0
}

shutdown :: proc() {
	finish_run()
	b3.DestroyWorld(state.world)
	if current_track.collision_mesh != nil {
		b3.DestroyMesh(current_track.collision_mesh)
		current_track.collision_mesh = nil
	}
	rl.UnloadModel(debug_test_model)
	rl.CloseAudioDevice()
	rl.CloseWindow()
}
