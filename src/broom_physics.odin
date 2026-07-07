package main

import "core:math"
import rl "vendor:raylib"
import b3 "box3d"

ACCEL_MULT :: 1.35
DRIFT_TURN_MULT :: 1.6
TURN_SPEED_BASE :: 1.8
ACCEL_FORCE :: 8.0
BRAKE_FORCE :: 12.0
DRAG_COAST :: 2.0

BroomState :: struct {
	body_id:  u64,
	speed:    f32,
	forward:  rl.Vector3,
	position: rl.Vector3,
}

broom_state: BroomState

init_broom :: proc() {
	pos := get_start_position()
	broom_state.body_id = b3.bw_create_body(state.world, pos.x, pos.y, pos.z, .Dynamic)
	b3.bw_create_box_shape(broom_state.body_id, 0.4, 0.2, 0.6)
	broom_state.speed = 0
	broom_state.forward = {0, 0, 1}
	broom_state.position = pos
}

update_broom :: proc(dt: f32) {
	surface := get_surface_at(broom_state.position)
	stance := get_current_stance()
	effect := get_effect(surface, stance)
	profile := surface_profiles[surface]

	steer_input := controls_state.steer
	accelerating := controls_state.accelerate
	braking := controls_state.brake

	// Turn.
	turn_speed := TURN_SPEED_BASE * clamp(broom_state.speed / 5.0, 0.3, 1.0)
	if effect == .Drift {
		turn_speed *= DRIFT_TURN_MULT
	}
	turn_rate := steer_input * turn_speed * dt
	cos_a := math.cos(turn_rate)
	sin_a := math.sin(turn_rate)
	fwd := broom_state.forward
	broom_state.forward = {
		fwd.x * cos_a - fwd.z * sin_a,
		0,
		fwd.x * sin_a + fwd.z * cos_a,
	}
	broom_state.forward = rl.Vector3Normalize(broom_state.forward)

	// Acceleration / braking.
	target_speed := profile.max_speed
	if accelerating {
		accel := profile.accel * ACCEL_FORCE
		if effect == .Accel {
			accel *= ACCEL_MULT
		}
		broom_state.speed += accel * dt
	} else if braking {
		broom_state.speed -= profile.drag * BRAKE_FORCE * dt
	} else {
		broom_state.speed -= profile.drag * DRAG_COAST * dt
	}
	broom_state.speed = clamp(broom_state.speed, 0, target_speed)

	// Drift: reduce effective speed during turns for slide feel.
	effective_speed := broom_state.speed
	if effect == .Drift && steer_input != 0 {
		effective_speed *= 0.55
	}

	// Apply movement.
	pos := broom_state.position
	pos.x += broom_state.forward.x * effective_speed * dt
	pos.z += broom_state.forward.z * effective_speed * dt
	pos.y = 0.5

	broom_state.position = pos

	// Sync Box3D body for future collision use.
	b3.bw_set_body_transform(broom_state.body_id, pos.x, pos.y, pos.z, 0, 0, 0)
}

get_broom_position :: proc() -> rl.Vector3 {
	return broom_state.position
}

get_broom_forward :: proc() -> rl.Vector3 {
	return broom_state.forward
}

get_broom_speed :: proc() -> f32 {
	return broom_state.speed
}

reset_broom :: proc() {
	pos := get_start_position()
	broom_state.position = pos
	broom_state.speed = 0
	broom_state.forward = {0, 0, 1}
	b3.bw_set_body_transform(broom_state.body_id, pos.x, pos.y, pos.z, 0, 0, 0)
}
