package main

import rl "vendor:raylib"

ControlsState :: struct {
	steer:        f32,
	accelerate:   bool,
	brake:        bool,
}

controls_state: ControlsState

update_controls :: proc() {
	controls_state.steer = 0
	if rl.IsKeyDown(.RIGHT) || rl.IsKeyDown(.D) {
		controls_state.steer += 1
	}
	if rl.IsKeyDown(.LEFT) || rl.IsKeyDown(.A) {
		controls_state.steer -= 1
	}
	controls_state.accelerate = rl.IsKeyDown(.UP) || rl.IsKeyDown(.W)
	controls_state.brake = rl.IsKeyDown(.DOWN) || rl.IsKeyDown(.S)

	// Dev stance keys (bypass pentagram lock).
	if rl.IsKeyPressed(.ONE) {
		switch_stance_unchecked(.Speed)
	}
	if rl.IsKeyPressed(.TWO) {
		switch_stance_unchecked(.Drift)
	}
	if rl.IsKeyPressed(.THREE) {
		switch_stance_unchecked(.Fist)
	}
	if rl.IsKeyPressed(.FOUR) {
		switch_stance_unchecked(.OK)
	}
	if rl.IsKeyPressed(.FIVE) {
		switch_stance_unchecked(.Advance)
	}
}
