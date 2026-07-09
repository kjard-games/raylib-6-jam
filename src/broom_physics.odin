package main

import "core:math"
import rl "vendor:raylib"
import b3 "vendor:box3d"

ACCEL_FORCE :: 300.0
BRAKE_FORCE :: 460.0
ACCEL_MULT :: 1.35
DRIFT_TURN_MULT :: 1.6
TURN_SPEED_BASE :: 1.8

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
	def.linearDamping = 0.33
	def.angularDamping = 2.0
	def.motionLocks = {angularX = true, angularZ = true}
	def.isAwake = true
	def.enableSleep = false
	broom_state.body_id = b3.CreateBody(state.world, def)

	shape_def := b3.DefaultShapeDef()
	shape_def.density = 100.0
	shape_def.baseMaterial.friction = 0.6
	hull := b3.MakeBoxHull(0.4, 0.2, 0.6)
	_ = b3.CreateHullShape(broom_state.body_id, shape_def, &hull.base)

	broom_state.speed = 0
	broom_state.forward = {0, 0, 1}
	broom_state.position = pos

	build_track_collision()
}

build_track_collision :: proc() {
	tiles := get_tiles()
	track_def := b3.DefaultBodyDef()
	track_def.type = b3.BodyType.staticBody
	track_body := b3.CreateBody(state.world, track_def)
	shape_def := b3.DefaultShapeDef()

	for tile in tiles {
		origin := tile_world_origin(tile.gx, tile.gy, tile.gz)
		dir_angle := f32(tile.rotation) * math.PI * 0.5
		q_tile := b3.MakeQuatFromAxisAngle(b3.Vec3_axisY, dir_angle)

		// Road hulls
		hulls := generate_template_hulls(tile.template, tile.dy, context.temp_allocator)
		for hull in hulls {
			world_pos := origin + b3.RotateVector(q_tile, hull.pos)
			q_world := b3.MulQuat(q_tile, hull.rot)

			box := b3.MakeBoxHull(hull.hx, hull.hy, hull.hz)
			_ = b3.CreateTransformedHullShape(
				track_body, shape_def, &box.base,
				{p = world_pos, q = q_world},
				b3.Vec3_one,
			)
		}

		// Edge hulls (walls/curbs)
		edge_hulls := generate_edge_hulls(tile.template, tile.dy, tile.wall_left, tile.wall_right, context.temp_allocator)
		for hull in edge_hulls {
			world_pos := origin + b3.RotateVector(q_tile, hull.pos)
			q_world := b3.MulQuat(q_tile, hull.rot)

			box := b3.MakeBoxHull(hull.hx, hull.hy, hull.hz)
			_ = b3.CreateTransformedHullShape(
				track_body, shape_def, &box.base,
				{p = world_pos, q = q_world},
				b3.Vec3_one,
			)
		}
	}
}

simulate_broom :: proc(dt: f32) {
	body := broom_state.body_id

	vel := b3.Body_GetLinearVelocity(body)
	current_speed := math.sqrt(vel.x * vel.x + vel.z * vel.z)

	surface := get_surface_at(broom_state.position)
	stance := get_current_stance()
	effect := get_effect(surface, stance)
	profile := surface_profiles[surface]

	steer_input := controls_state.steer
	accelerating := controls_state.accelerate
	braking := controls_state.brake

	turn_speed := TURN_SPEED_BASE * clamp(current_speed / 5.0, 0.3, 1.0)
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

	b3.Body_SetAngularVelocity(body, {0, turn_rate / dt, 0})

	drift_mult := f32(1.0)
	if effect == .Drift && steer_input != 0 {
		drift_mult = 0.55
	}

	forward_force := b3.Vec3{0, 0, 0}
	if accelerating {
		accel := profile.accel * ACCEL_FORCE * drift_mult
		if effect == .Accel {
			accel *= ACCEL_MULT
		}
		forward_force = {fwd.x * accel, 0, fwd.z * accel}
	} else if braking {
		forward_force = {-fwd.x * BRAKE_FORCE * drift_mult, 0, -fwd.z * BRAKE_FORCE * drift_mult}
	}

	b3.Body_ApplyForceToCenter(body, forward_force, true)

	broom_state.speed = current_speed
}

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
	b3.Body_SetTransform(broom_state.body_id, {pos.x, pos.y, pos.z}, id_quat)
}
