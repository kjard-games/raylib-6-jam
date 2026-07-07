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
	blocks := get_track_blocks()
	for block in blocks {
		surface_colors := [Surface]rl.Color{
			.Dirt     = {120, 80, 40, 255},
			.Pavement = {80, 80, 80, 255},
			.Sand     = {180, 160, 100, 255},
			.Grass    = {60, 140, 60, 255},
		}
		col := surface_colors[block.surface]
		half_w := block.width / 2
		half_l := block.length / 2
		cx := block.start.x + block.curvature * block.length * 0.3
		cz := block.start.z + half_l
		rl.DrawCube({cx, -0.5, cz}, block.width, 0.5, block.length, col)
		rl.DrawCubeWires({cx, -0.5, cz}, block.width, 0.5, block.length, rl.BLACK)
	}

	checkpoints := get_checkpoints()
	for cp in checkpoints {
		rl.DrawCube(cp.position + {0, -0.2, 0}, 0.5, 0.1, 0.5, rl.YELLOW)
	}
}

draw_broom :: proc() {
	pos := get_broom_position()
	fwd := get_broom_forward()

	rl.DrawCube(pos, 0.1, 0.1, 0.6, rl.DARKBROWN)
	rl.DrawCube(pos + fwd * 0.35, 0.15, 0.05, 0.1, {100, 60, 30, 255})

	rider_pos := pos - fwd * 0.15
	rider_pos.y += 0.2
	rl.DrawCylinder(rider_pos, 0.02, 0.12, 0.25, 6, rl.DARKGREEN)

	col := stance_colors[get_current_stance()]
	col.a = 100
	rl.DrawSphere(pos, 0.4, col)
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
	rl.CloseAudioDevice()
	rl.CloseWindow()
}
