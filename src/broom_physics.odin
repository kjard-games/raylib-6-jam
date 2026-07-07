package main

import "core:math"
import rl "vendor:raylib"
import b3 "vendor:box3d"

ACCEL_MULT :: 1.35
DRIFT_TURN_MULT :: 1.6
TURN_SPEED_BASE :: 1.8
ACCEL_FORCE :: 8.0
BRAKE_FORCE :: 12.0
SPEED_DRAG :: 0.33
COAST_MULT :: 2.0

BroomState :: struct {
	body_id:  b3.BodyId,
	speed:    f32,
	forward:  rl.Vector3,
	position: rl.Vector3,
}

broom_state: BroomState

init_broom :: proc() {
	pos := get_start_position()

	def := b3.DefaultBodyDef()
	def.position = {pos.x, pos.y, pos.z}
	def.type = b3.BodyType.dynamicBody
	def.gravityScale = 0
	def.linearDamping = 0.5
	broom_state.body_id = b3.CreateBody(state.world, def)

	shape_def := b3.DefaultShapeDef()
	shape_def.density = 1.0
	hull := b3.MakeBoxHull(0.4, 0.2, 0.6)
	_ = b3.CreateHullShape(broom_state.body_id, shape_def, &hull.base)

	broom_state.speed = 0
	broom_state.forward = {0, 0, 1}
	broom_state.position = pos

	build_track_collision()
}

build_track_collision :: proc() {
	OVERLAP :: 2.0
	TRACK_LENGTH :: 500.0

	ground_def := b3.DefaultBodyDef()
	ground_def.position = {5, -0.75, TRACK_LENGTH / 2}
	ground_def.type = b3.BodyType.staticBody
	ground_body := b3.CreateBody(state.world, ground_def)
	ground_shape := b3.DefaultShapeDef()
	ground_hull := b3.MakeBoxHull(30, 0.25, TRACK_LENGTH / 2 + 20)
	_ = b3.CreateHullShape(ground_body, ground_shape, &ground_hull.base)

	l_wall_def := b3.DefaultBodyDef()
	l_wall_def.position = {-10, 1.5, TRACK_LENGTH / 2}
	l_wall_def.type = b3.BodyType.staticBody
	l_wall_body := b3.CreateBody(state.world, l_wall_def)
	l_wall_shape := b3.DefaultShapeDef()
	l_wall_hull := b3.MakeBoxHull(0.5, 2, TRACK_LENGTH / 2 + 20)
	_ = b3.CreateHullShape(l_wall_body, l_wall_shape, &l_wall_hull.base)

	r_wall_def := b3.DefaultBodyDef()
	r_wall_def.position = {20, 1.5, TRACK_LENGTH / 2}
	r_wall_def.type = b3.BodyType.staticBody
	r_wall_body := b3.CreateBody(state.world, r_wall_def)
	r_wall_shape := b3.DefaultShapeDef()
	r_wall_hull := b3.MakeBoxHull(0.5, 2, TRACK_LENGTH / 2 + 20)
	_ = b3.CreateHullShape(r_wall_body, r_wall_shape, &r_wall_hull.base)

	blocks := get_track_blocks()
	for block in blocks {
		center := block_center(block)
		hw := block.width / 2
		hl := block.length / 2

		floor_def := b3.DefaultBodyDef()
		floor_def.position = {center.x, -0.45, center.z}
		floor_def.type = b3.BodyType.staticBody
		floor_body := b3.CreateBody(state.world, floor_def)
		floor_shape := b3.DefaultShapeDef()
		floor_hull := b3.MakeBoxHull(hw + OVERLAP, 0.05, hl + OVERLAP)
		_ = b3.CreateHullShape(floor_body, floor_shape, &floor_hull.base)
	}
}

simulate_broom :: proc(dt: f32) {
	surface := get_surface_at(broom_state.position)
	stance := get_current_stance()
	effect := get_effect(surface, stance)
	profile := surface_profiles[surface]

	steer_input := controls_state.steer
	accelerating := controls_state.accelerate
	braking := controls_state.brake

	turn_speed := TURN_SPEED_BASE * clamp(broom_state.speed / 5.0, 0.3, 1.0)
	if effect == .Drift {
		turn_speed *= DRIFT_TURN_MULT
	}
	turn_rate := steer_input * turn_speed * dt
	cos_a := math.cos(turn_rate)
	sin_a := math.sin(turn_rate)
	fwd := broom_state.forward
	broom_state.forward = rl.Vector3Normalize({
		fwd.x * cos_a - fwd.z * sin_a,
		0,
		fwd.x * sin_a + fwd.z * cos_a,
	})

	if accelerating {
		accel := profile.accel * ACCEL_FORCE
		if effect == .Accel {
			accel *= ACCEL_MULT
		}
		drag := broom_state.speed * SPEED_DRAG
		broom_state.speed += (accel - drag) * dt
	} else if braking {
		drag := broom_state.speed * SPEED_DRAG
		broom_state.speed -= (BRAKE_FORCE + drag) * dt
	} else {
		drag := broom_state.speed * SPEED_DRAG * COAST_MULT
		broom_state.speed -= drag * dt
	}
	broom_state.speed = max(broom_state.speed, 0)

	effective_speed := broom_state.speed
	if effect == .Drift && steer_input != 0 {
		effective_speed *= 0.55
	}

	velocity := broom_state.forward * effective_speed
	b3.Body_SetLinearVelocity(broom_state.body_id, {velocity.x, 0, velocity.z})

	angle := math.atan2(broom_state.forward.x, broom_state.forward.z)
	quat := b3.MakeQuatFromAxisAngle({0, 1, 0}, angle)
	b3.Body_SetTransform(broom_state.body_id, {broom_state.position.x, 0.8, broom_state.position.z}, quat)
}

// Called after World_Step to read collision-resolved position.
sync_broom :: proc() {
	pos := b3.Body_GetPosition(broom_state.body_id)
	broom_state.position = {pos[0], pos[1], pos[2]}
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
	b3.Body_SetLinearVelocity(broom_state.body_id, {0, 0, 0})
	id_quat := b3.MakeQuatFromAxisAngle({0, 1, 0}, 0)
	b3.Body_SetTransform(broom_state.body_id, {pos.x, 0.8, pos.z}, id_quat)
}
