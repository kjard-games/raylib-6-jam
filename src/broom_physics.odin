package main

import "core:c"
import "core:fmt"
import "core:math"
import rl "vendor:raylib"
import b3 "vendor:box3d"

ACCEL_FORCE :: 600.0
BRAKE_FORCE :: 900.0
ACCEL_MULT :: 1.5
DRIFT_TURN_MULT :: 1.8
TURN_SPEED_BASE :: 3.0
DRAG_COEFF :: 0.15

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
	def.linearDamping = 0.10
	def.angularDamping = 1.5
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
	points := get_track_points()
	n := len(points)
	if n < 2 { return }

	raw_pos := make([]b3.Vec3, n)
	for i in 0..<n {
		raw_pos[i] = b3.Vec3(points[i].pos)
	}
	spline_pos := make_catmull_rom_points(raw_pos)

	track_def := b3.DefaultBodyDef()
	track_def.type = b3.BodyType.staticBody
	track_body := b3.CreateBody(state.world, track_def)

	num_segs := n - 1

	// --- Road mesh shape ---
	total_samples := num_segs * COLLISION_SAMPLES_PER_SEG + 1
	vc := total_samples * 2
	tc := (total_samples - 1) * 2

	verts := make([]b3.Vec3, vc)
	indices := make([]i32, tc * 3)
	mat_indices := make([]u8, tc)

	vi := 0
	for seg in 0..<num_segs {
		for s in 0..<COLLISION_SAMPLES_PER_SEG {
			t := f32(s) / f32(COLLISION_SAMPLES_PER_SEG)
			width, bank := get_track_attribs(seg, t)
			hw := width * 0.5
			pos, fwd, right, _ := get_road_frame(spline_pos, seg, t, bank)
			verts[vi] = pos - right * hw
			verts[vi+1] = pos + right * hw
			vi += 2
		}
	}
	last_width, last_bank := get_track_attribs(num_segs-1, 1.0)
	last_hw := last_width * 0.5
	pos, fwd, right, _ := get_road_frame(spline_pos, num_segs-1, 1.0, last_bank)
	verts[vi] = pos - right * last_hw
	verts[vi+1] = pos + right * last_hw
	fmt.eprintfln("  collision first 4 verts: (%v) (%v) (%v) (%v)", verts[0], verts[1], verts[2], verts[3])
	fmt.eprintfln("  collision last 4 verts: (%v) (%v) (%v) (%v)", verts[vc-4], verts[vc-3], verts[vc-2], verts[vc-1])

	ii := 0
	for i in 0..<total_samples - 1 {
		a := i32(i * 2)
		b := a + 1
		c := i32((i + 1) * 2)
		d := c + 1
		indices[ii+0] = a
		indices[ii+1] = c
		indices[ii+2] = b
		indices[ii+3] = b
		indices[ii+4] = c
		indices[ii+5] = d
		ii += 6
	}
	fmt.eprintfln("  collision first 6 indices: %d %d %d %d %d %d", indices[0], indices[1], indices[2], indices[3], indices[4], indices[5])

	for i in 0..<tc {
		tri_seg := i / (COLLISION_SAMPLES_PER_SEG * 2)
		if tri_seg >= num_segs { tri_seg = num_segs - 1 }
		mat_indices[i] = u8(points[tri_seg].surface)
	}

	materials := [4]b3.SurfaceMaterial{}
	for i in 0..<4 {
		materials[i] = b3.DefaultSurfaceMaterial()
	}
	materials[Surface.Dirt].friction = 0.70
	materials[Surface.Dirt].userMaterialId = u64(Surface.Dirt)
	materials[Surface.Pavement].friction = 0.60
	materials[Surface.Pavement].userMaterialId = u64(Surface.Pavement)
	materials[Surface.Sand].friction = 0.80
	materials[Surface.Sand].userMaterialId = u64(Surface.Sand)
	materials[Surface.Grass].friction = 0.75
	materials[Surface.Grass].userMaterialId = u64(Surface.Grass)

	mesh_def := b3.MeshDef {
		vertices        = raw_data(verts),
		vertexCount     = c.int(vc),
		indices         = raw_data(indices),
		materialIndices = raw_data(mat_indices),
		triangleCount   = c.int(tc),
		weldVertices    = true,
		weldTolerance   = 0.001,
		useMedianSplit  = true,
		identifyEdges   = false,
	}

	mesh_data := b3.CreateMesh(mesh_def, nil, 0)
	current_track.collision_mesh = mesh_data
	fmt.eprintfln("build_track_collision: CreateMesh returned ptr (verts=%d tris=%d)", vc, tc)

	shape_def := b3.DefaultShapeDef()
	shape_def.materials = raw_data(materials[:])
	shape_def.materialCount = c.int(len(materials))

	shape_id := b3.CreateMeshShape(track_body, shape_def, mesh_data, {1, 1, 1})
	fmt.eprintfln("build_track_collision: CreateMeshShape id=(index1=%d world0=%d gen=%d)", shape_id.index1, shape_id.world0, shape_id.generation)

	delete(verts)
	delete(indices)
	delete(mat_indices)

	// --- Finish line sensor ---
	finish_pos, finish_fwd, finish_right, _ := get_road_frame(spline_pos, num_segs-1, 1.0, last_bank)
	finish_q := make_quat_from_road_frame(finish_fwd, finish_right)
	finish_xf := b3.Transform{p = finish_pos, q = finish_q}

	sensor_def := b3.DefaultShapeDef()
	sensor_def.isSensor = true
	sensor_def.enableSensorEvents = true
	finish_hull := b3.MakeTransformedBoxHull(last_hw, 2.5, 0.5, finish_xf)
	state.finish_sensor = b3.CreateHullShape(track_body, sensor_def, &finish_hull.base)

	// --- Wall box hulls ---
	wall_shape_def := b3.DefaultShapeDef()

	for seg in 0..<num_segs {
		cp := points[seg]
		for s in 0..<COLLISION_SAMPLES_PER_SEG {
			t := f32(s) / f32(COLLISION_SAMPLES_PER_SEG)
			next_t := min(t + 1.0 / f32(COLLISION_SAMPLES_PER_SEG), 1.0)
			width, bank := get_track_attribs(seg, t)
			hw := width * 0.5

			pos, fwd, right, _ := get_road_frame(spline_pos, seg, t, bank)
			next_pos := catmull_rom_eval(spline_pos, seg, next_t)

			mid := (pos + next_pos) * 0.5
			half_len := b3.Distance(pos, next_pos) * 0.5 + 0.25
			q := make_quat_from_road_frame(fwd, right)
			xf := b3.Transform{p = mid, q = q}

			if cp.wall_left != .None {
				lp := mid - right * hw
				wh := f32(8.0) if cp.wall_left == .Wall else f32(0.4)
				ww := f32(0.5) if cp.wall_left == .Wall else f32(0.3)
				w_xf := b3.Transform{p = lp + b3.Vec3{0, wh * 0.5, 0}, q = q}
				wbox := b3.MakeTransformedBoxHull(ww, wh, half_len, w_xf)
				_ = b3.CreateHullShape(track_body, wall_shape_def, &wbox.base)
			}
			if cp.wall_right != .None {
				rp := mid + right * hw
				wh := f32(8.0) if cp.wall_right == .Wall else f32(0.4)
				ww := f32(0.5) if cp.wall_right == .Wall else f32(0.3)
				w_xf := b3.Transform{p = rp + b3.Vec3{0, wh * 0.5, 0}, q = q}
				wbox := b3.MakeTransformedBoxHull(ww, wh, half_len, w_xf)
				_ = b3.CreateHullShape(track_body, wall_shape_def, &wbox.base)
			}
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

	turn_speed := TURN_SPEED_BASE * profile.grip * clamp(current_speed / 15.0, 0.2, 1.0)
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

	// Drag force: quadratic speed-dependent resistance
	drag_mag := profile.drag * DRAG_COEFF * current_speed * current_speed
	drag_force := b3.Vec3{-fwd.x * drag_mag, 0, -fwd.z * drag_mag}

	b3.Body_ApplyForceToCenter(body, forward_force + drag_force, true)

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
