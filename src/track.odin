package main

import "core:fmt"
import "core:math"
import "core:os"
import "core:strings"
import rl "vendor:raylib"
import b3 "vendor:box3d"

DEFAULT_TILE_SIZE :: 30.0

// New kit models are at 1 unit = 1 meter scale; we render them at 10x
// so they match the old kit's world-space footprint.
TILE_RENDER_SCALE :: 30.0

TrackBlock :: struct {
	tile_name: string,
	surface:   Surface,
}

TileInstance :: struct {
	tile_name:  string,
	model_idx:  int,
	class:      TileClass,
	length:     f32,
	pos:        rl.Vector3,
	yaw:        f32,
	surface:    Surface,
}

Track3D :: struct {
	blocks:         []TrackBlock,
	instances:      []TileInstance,
	models:         []rl.Model,
	model_paths:    []string,
	colormap:       rl.Texture2D,
	motorcycle:     rl.Model,
	collision_body: b3.BodyId,
	start_pos:      rl.Vector3,
	finish_pos:     rl.Vector3,
}

current_track: Track3D

parse_surface :: proc(s: string) -> Surface {
	switch s {
	case "dirt":     return .Dirt
	case "pavement": return .Pavement
	case "sand":     return .Sand
	case "grass":    return .Grass
	}
	return .Pavement
}

init_track :: proc() {
	tile_registry := register_tiles()
	defer delete(tile_registry)

	ok: bool
	track_path := "assets/tracks/map00.txt"
	data, read_ok := os.read_entire_file_from_path(track_path, context.temp_allocator)
	if read_ok != nil {
		fmt.eprintfln("ERROR: cannot read track file %s", track_path)
		return
	}
	text := string(data)

	path_order := make([dynamic]string)
	defer delete(path_order)
	path_map := make(map[string]int)
	defer delete(path_map)

	blocks := make([dynamic]TrackBlock)

	for line in strings.split_lines_iterator(&text) {
		line := strings.trim_space(line)
		if line == "" || strings.has_prefix(line, "#") {
			continue
		}

		parts := strings.fields(line)
		if len(parts) < 2 {
			fmt.eprintfln("WARN: skipping bad line: %s", line)
			continue
		}

		tile_name := parts[0]
		surface := parse_surface(parts[1])

		def, has_def := tile_registry[tile_name]
		if !has_def {
			fmt.eprintfln("WARN: unknown tile type '%s', skipping", tile_name)
			continue
		}

		if _, exists := path_map[def.model_path]; !exists {
			path_map[def.model_path] = len(path_order)
			append(&path_order, strings.clone(def.model_path))
		}
		append(&blocks, TrackBlock{tile_name = strings.clone(tile_name), surface = surface})
	}

	current_track.blocks = blocks[:]

	// Load colormap for old kenney_racing models
	colormap := rl.LoadTexture("assets/kenney_racing/models/Textures/colormap.png")
	current_track.colormap = colormap

	// Load models into array (indexed by position in path_order)
	n_models := len(path_order)
	models := make([]rl.Model, n_models)
	for i in 0 ..< n_models {
		path := path_order[i]
		cpath := strings.clone_to_cstring(path, context.temp_allocator)
		model := rl.LoadModel(cpath)
		for mi in 0 ..< model.materialCount {
			mat := model.materials[mi]
			if mat.maps[rl.MaterialMapIndex.ALBEDO].texture.id == 0 {
				rl.SetMaterialTexture(&model.materials[mi], .ALBEDO, colormap)
			}
		}
		models[i] = model
	}
	current_track.models = models
	current_track.model_paths = path_order[:]

	// Motorcycle
	mc := rl.LoadModel("assets/kenney_racing/models/vehicle-motorcycle.glb")
	for mi in 0 ..< mc.materialCount {
		if mc.materials[mi].maps[rl.MaterialMapIndex.ALBEDO].texture.id == 0 {
			rl.SetMaterialTexture(&mc.materials[mi], .ALBEDO, colormap)
		}
	}
	current_track.motorcycle = mc

	compute_tile_instances(tile_registry, path_map)

	if len(current_track.instances) > 0 {
		current_track.start_pos = get_tile_world_pos(0)
	}
	for i := len(current_track.blocks) - 1; i >= 0; i -= 1 {
		def, has_def := tile_registry[current_track.blocks[i].tile_name]
		if has_def && def.class == .Start {
			current_track.finish_pos = get_tile_world_pos(i)
			break
		}
	}

	build_track_collision(tile_registry)

	fmt.eprintfln("init_track: %d blocks, %d instances", len(current_track.blocks), len(current_track.instances))
	fmt.eprintfln("  start=(%v) finish=(%v)", current_track.start_pos, current_track.finish_pos)
}

compute_tile_instances :: proc(registry: TileRegistry, path_map: map[string]int) {
	blocks := current_track.blocks
	n := len(blocks)
	instances := make([]TileInstance, n)

	pos := rl.Vector3{0, 0, 0}
	yaw := f32(0)

	for i in 0 ..< n {
		block := blocks[i]
		def := registry[block.tile_name]

		instances[i] = TileInstance{
			tile_name = strings.clone(block.tile_name),
			model_idx = path_map[def.model_path],
			class     = def.class,
			length    = def.length,
			pos       = pos,
			yaw       = yaw,
			surface   = block.surface,
		}

		rad := yaw * math.PI / 180.0
		fwd := rl.Vector3{-math.sin(rad), 0, math.cos(rad)}
		right := rl.Vector3{math.cos(rad), 0, math.sin(rad)}

		switch def.class {
		case .Straight, .Start:
			pos += fwd * def.length
		case .CornerRight:
			pos += right * def.length
			yaw += 90
		case .CornerLeft:
			pos -= right * def.length
			yaw -= 90
		case .Crossing:
		}
	}

	current_track.instances = instances
}

get_tile_world_pos :: proc(block_idx: int) -> rl.Vector3 {
	if block_idx >= len(current_track.instances) {
		return {}
	}
	inst := current_track.instances[block_idx]
	rad := inst.yaw * math.PI / 180.0
	fwd := rl.Vector3{-math.sin(rad), 0, math.cos(rad)}
	return inst.pos + fwd * (inst.length * 0.5)
}

build_track_collision :: proc(registry: TileRegistry) {
	track_def := b3.DefaultBodyDef()
	track_def.type = b3.BodyType.staticBody
	track_body := b3.CreateBody(state.world, track_def)

	shape_def := b3.DefaultShapeDef()
	shape_def.baseMaterial.friction = 0.6

	for inst in current_track.instances {
		rad := inst.yaw * math.PI / 180.0
		rot := b3.MakeQuatFromAxisAngle(b3.Vec3{0, 1, 0}, rad)
		// Place hull below the visual model surface
		xf := b3.Transform{p = {inst.pos.x, -0.5, inst.pos.z}, q = rot}
		hull := b3.MakeTransformedBoxHull(inst.length, 0.25, f32(TILE_RENDER_SCALE), xf)
		_ = b3.CreateHullShape(track_body, shape_def, &hull.base)
	}

	fmt.eprintfln("build_track_collision: %d tile hulls", len(current_track.instances))

	current_track.collision_body = track_body

	// Finish sensor
	blocks := current_track.blocks
	instances := current_track.instances
	n := len(instances)
	finish_idx := -1
	for i := n - 1; i >= 0; i -= 1 {
		def, has_def := registry[blocks[i].tile_name]
		if has_def && def.class == .Start {
			finish_idx = i
			break
		}
	}
	if finish_idx >= 0 {
		inst := instances[finish_idx]
		rad := inst.yaw * math.PI / 180.0
		fwd := b3.Vec3{-math.sin(rad), 0, math.cos(rad)}
		center := b3.Vec3{inst.pos.x, 0, inst.pos.z} + fwd * (inst.length * 0.5)

		finish_q := b3.MakeQuatFromAxisAngle({0, 1, 0}, rad)
		finish_xf := b3.Transform{p = center, q = finish_q}

		sensor_def := b3.DefaultShapeDef()
		sensor_def.isSensor = true
		sensor_def.enableSensorEvents = true
		finish_hull := b3.MakeTransformedBoxHull(inst.length * 0.4, 2.5, 0.5, finish_xf)
		state.finish_sensor = b3.CreateHullShape(track_body, sensor_def, &finish_hull.base)
	}
}

get_surface_at :: proc(pos: rl.Vector3) -> Surface {
	if !b3.Body_IsValid(current_track.collision_body) {
		return .Pavement
	}
	origin := b3.Vec3{pos.x, pos.y + 5, pos.z}
	translation := b3.Vec3{0, -15, 0}

	filter := b3.QueryFilter{
		categoryBits = 0xFFFF,
		maskBits     = 0xFFFF,
	}

	result := b3.World_CastRayClosest(state.world, origin, translation, filter)
	if result.hit {
		return Surface(result.userMaterialId)
	}
	return .Pavement
}

get_start_position :: proc() -> rl.Vector3 {
	return current_track.start_pos
}

get_track_finish :: proc() -> rl.Vector3 {
	return current_track.finish_pos
}

draw_track :: proc() {
	for inst in current_track.instances {
		model := current_track.models[inst.model_idx]
		if model.meshes == nil { continue }

		s := f32(TILE_RENDER_SCALE)
		scale_x := s
		if inst.class == .CornerLeft {
			scale_x = -s
		}

		if debug.wireframe {
			rl.DrawModelEx(model, inst.pos, {0, 1, 0}, inst.yaw, {scale_x, s, s}, rl.WHITE)
		} else {
			rl.DrawModelEx(model, inst.pos, {0, 1, 0}, inst.yaw, {scale_x, s, s}, rl.WHITE)
		}
	}

	if debug.show_origin {
		for i in 0 ..< len(current_track.instances) {
			inst := current_track.instances[i]
			col := rl.Color{255, u8(100 + 50 * i % 100), 0, 255}
			rl.DrawSphere(inst.pos, 0.3, col)

			rad := inst.yaw * math.PI / 180.0
			fwd := rl.Vector3{-math.sin(rad), 0, math.cos(rad)}
			rl.DrawCylinderEx(inst.pos, inst.pos + fwd * 2, 0.1, 0.1, 4, col)
		}
	}
}

draw_motorcycle :: proc(pos: rl.Vector3, fwd: rl.Vector3, steer: f32, speed: f32) {
	model := current_track.motorcycle
	if model.meshes == nil {return}

	yaw_rad := math.atan2(fwd.x, fwd.z)
	lean_factor := clamp(speed / 15.0, 0.0, 1.0)
	lean_rad := -steer * 0.21 * lean_factor

	yaw_q := b3.MakeQuatFromAxisAngle(b3.Vec3{0, 1, 0}, yaw_rad)
	fwd_b3 := b3.Vec3{fwd.x, fwd.y, fwd.z}
	lean_q := b3.MakeQuatFromAxisAngle(fwd_b3, lean_rad)
	q := b3.MulQuat(yaw_q, lean_q)

	x2 := q.x + q.x; y2 := q.y + q.y; z2 := q.z + q.z
	xx := q.x * x2; xy := q.x * y2; xz := q.x * z2
	yy := q.y * y2; yz := q.y * z2; zz := q.z * z2
	wx := q.w * x2; wy := q.w * y2; wz := q.w * z2

	transform := rl.Matrix {
		1 - (yy + zz),       xy + wz,            xz - wy,            pos.x,
		xy - wz,            1 - (xx + zz),        yz + wx,            pos.y,
		xz + wy,             yz - wx,            1 - (xx + yy),       pos.z,
		0,                  0,                   0,                  1,
	}

	for mi in 0 ..< model.meshCount {
		mat := model.materials[model.meshMaterial[mi]]
		rl.DrawMesh(model.meshes[mi], mat, transform)
	}
}
