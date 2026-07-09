package main

import "core:math"
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
	world:       b3.WorldId,
	camera:      rl.Camera3D,
	race_phase:  RacePhase,
	countdown:   f32,
	race_time:   f64,
}

state: State

init :: proc() {
	rl.SetConfigFlags({.VSYNC_HINT})
	rl.InitWindow(WIDTH, HEIGHT, "raylib-6-jam")
	rl.InitAudioDevice()

	world_def := b3.DefaultWorldDef()
	world_def.gravity = {0, -10, 0}
	state.world = b3.CreateWorld(world_def)

	init_track()
	init_stance()
	init_time()
	init_broom()
	init_telemetry()

	state.camera = rl.Camera3D {
		position   = {12, 8, 12},
		target     = {0, 1, 0},
		up         = {0, 1, 0},
		fovy       = 60,
		projection = .PERSPECTIVE,
	}

	state.race_phase = .Countdown
	state.countdown = 3.0
	state.race_time = 0

	rl.SetTargetFPS(60)
}

update :: proc() -> bool {
	dt := rl.GetFrameTime()
	telemetry.accumulator += dt

	if rl.IsKeyPressed(.TAB) || rl.IsKeyPressed(.R) {
		restart_race()
	}

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
	rl.EndMode3D()

	draw_hud()

	hand_status := hand_tracking_status()
	rl.DrawText(strings.clone_to_cstring(hand_tracking_status_text(hand_status), context.temp_allocator), 10, 10, 14, rl.DARKGRAY)

	if hand_tracking_state.num_hands > 0 {
		rl.DrawCircleV(hand_tip_screen_pos(0), 12, rl.GREEN)
	}

	rl.DrawFPS(10, 140)
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
	surface_colors := [Surface]rl.Color{
		.Dirt     = {120, 80, 40, 255},
		.Pavement = {80, 80, 80, 255},
		.Sand     = {180, 160, 100, 255},
		.Grass    = {60, 140, 60, 255},
	}

	tiles := get_tiles()
	for tile in tiles {
		col := surface_colors[tile.surface]
		samples := generate_centerline(tile.template, tile.dy, context.temp_allocator)
		if len(samples) < 2 { continue }

		dir_angle := f32(tile.rotation) * math.PI * 0.5
		q_tile := b3.MakeQuatFromAxisAngle(b3.Vec3_axisY, dir_angle)
		origin := tile_world_origin(tile.gx, tile.gy, tile.gz)

		n := len(samples)
		for i in 0 ..< n - 1 {
			p0 := samples[i].pos
			p1 := samples[i + 1].pos

			r0 := b3.RotateVector(q_tile, p0)
			r1 := b3.RotateVector(q_tile, p1)

			w0 := rl.Vector3{
				origin[0] + r0[0],
				origin[1] + r0[1],
				origin[2] + r0[2],
			}
			w1 := rl.Vector3{
				origin[0] + r1[0],
				origin[1] + r1[1],
				origin[2] + r1[2],
			}

			mid := rl.Vector3{
				(w0.x + w1.x) / 2,
				(w0.y + w1.y) / 2,
				(w0.z + w1.z) / 2,
			}

			dx := w1.x - w0.x
			dz := w1.z - w0.z
			depth := math.sqrt(dx * dx + dz * dz)

			rl.DrawCube(mid, ROAD_WIDTH, 0.4, depth, col)
		}
	}

	checkpoints := get_checkpoints()
	for cp in checkpoints {
		rl.DrawCube(cp.position + {0, -0.2, 0}, 0.5, 0.1, 0.5, rl.YELLOW)
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
	rl.CloseAudioDevice()
	rl.CloseWindow()
}
