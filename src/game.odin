package main

import "core:strings"
import rl "vendor:raylib"
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
	init_audio()
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
			start_engine()
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
	rl.DrawCube(finish + {0, -0.2, 0}, DEFAULT_TILE_SIZE * 0.8, 0.5, 0.2, rl.WHITE)
	rl.DrawCube(finish + {0, 0.3, 0}, DEFAULT_TILE_SIZE * 0.8, 0.1, 0.2, {200, 200, 200, 255})
}

draw_broom :: proc() {
	pos := get_broom_position()
	fwd := get_broom_forward()
	steer := controls_state.steer
	speed := get_broom_speed()
	draw_motorcycle(pos, fwd, steer, speed)
}

restart_race :: proc() {
	finish_run()
	stop_engine()
	reset_broom()
	init_stance()
	init_time()
	state.race_phase = .Countdown
	state.countdown = 3.0
	state.race_time = 0
}

shutdown :: proc() {
	finish_run()
	stop_engine()
	shutdown_audio()

	for i in 0 ..< len(current_track.models) {
		rl.UnloadModel(current_track.models[i])
	}
	delete(current_track.models)
	delete(current_track.model_paths)
	rl.UnloadModel(current_track.motorcycle)
	rl.UnloadTexture(current_track.colormap)

	b3.DestroyWorld(state.world)

	delete(current_track.blocks)
	delete(current_track.instances)

	rl.UnloadModel(debug_test_model)
	rl.CloseAudioDevice()
	rl.CloseWindow()
}
