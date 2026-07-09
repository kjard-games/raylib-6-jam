package main

import "core:math"
import rl "vendor:raylib"
import b3 "vendor:box3d"

Checkpoint :: struct {
	position: rl.Vector3,
	index:    i32,
}

Tile :: struct {
	template:   BlockTemplate,
	gx, gy, gz: int,
	rotation:   int,
	dy:         int,
	surface:    Surface,
	wall_left:  WallType,
	wall_right: WallType,
	boost:      bool,
}

Track3D :: struct {
	tiles:       []Tile,
	tile_lookup: map[[2]int]^Tile,
	start_pos:   rl.Vector3,
	finish_pos:  rl.Vector3,
	checkpoints: []Checkpoint,
}

Segment :: struct {
	template:   BlockTemplate,
	dy:         int,
	surface:    Surface,
	wall_left:  WallType,
	wall_right: WallType,
	boost:      bool,
}

template_grid_out :: proc(t: BlockTemplate, dy, dir: int) -> (dx, dy_out, dz: int) {
	switch t {
	case .Straight, .JumpRamp:
		switch dir & 3 {
		case 0: dz = 1
		case 1: dx = 1
		case 2: dz = -1
		case 3: dx = -1
		}
		dy_out = dy
	case .Slope:
		switch dir & 3 {
		case 0: dz = 1
		case 1: dx = 1
		case 2: dz = -1
		case 3: dx = -1
		}
		dy_out = dy
	case .Descent:
		switch dir & 3 {
		case 0: dz = 1
		case 1: dx = 1
		case 2: dz = -1
		case 3: dx = -1
		}
		dy_out = -dy
	case .Turn, .TurnSlope:
		next_dir := (dir + 1) & 3
		switch next_dir {
		case 0: dz = 1
		case 1: dx = 1
		case 2: dz = -1
		case 3: dx = -1
		}
		dy_out = dy
	}
	return
}

build_track_from_segments :: proc(segments: []Segment, start_gx, start_gy, start_gz, start_dir: int) -> []Tile {
	tiles := make([]Tile, len(segments))
	cx, cy, cz := start_gx, start_gy, start_gz
	dir := start_dir

	for seg, i in segments {
		tiles[i] = Tile{
			template   = seg.template,
			gx         = cx,
			gy         = cy,
			gz         = cz,
			rotation   = dir,
			dy         = seg.dy,
			surface    = seg.surface,
			wall_left  = seg.wall_left,
			wall_right = seg.wall_right,
			boost      = seg.boost,
		}

		dx, ddy, dz := template_grid_out(seg.template, seg.dy, dir)
		cx += dx
		cy += ddy
		cz += dz

		#partial switch seg.template {
		case .Turn, .TurnSlope:
			dir = (dir + 1) & 3
		case .Straight, .Slope, .Descent, .JumpRamp:
		}
	}

	return tiles
}

current_track: Track3D

init_track :: proc() {
	current_track.tiles = build_map00()
	current_track.checkpoints = {}

	current_track.tile_lookup = make(map[[2]int]^Tile)
	for i in 0 ..< len(current_track.tiles) {
		t := &current_track.tiles[i]
		current_track.tile_lookup[[2]int{t.gx, t.gz}] = t
	}

	first := &current_track.tiles[0]
	f_origin := tile_world_origin(first.gx, first.gy, first.gz)
	current_track.start_pos = {f_origin[0], f_origin[1] + 0.5, f_origin[2]}

	last := &current_track.tiles[len(current_track.tiles) - 1]
	last_out_dx, last_out_dy, last_out_dz := template_grid_out(last.template, last.dy, last.rotation)
	lo := tile_world_origin(last.gx + last_out_dx, last.gy + last_out_dy, last.gz + last_out_dz)
	current_track.finish_pos = {lo[0], lo[1] + 0.5, lo[2]}
}

get_tiles :: proc() -> []Tile {
	return current_track.tiles
}

get_checkpoints :: proc() -> []Checkpoint {
	return current_track.checkpoints
}

get_start_position :: proc() -> rl.Vector3 {
	return current_track.start_pos
}

get_track_finish :: proc() -> rl.Vector3 {
	return current_track.finish_pos
}

piece_world_in :: proc(tile: Tile) -> b3.Vec3 {
	return tile_world_origin(tile.gx, tile.gy, tile.gz)
}

piece_world_out :: proc(tile: Tile) -> b3.Vec3 {
	dx, dy, dz := template_grid_out(tile.template, tile.dy, tile.rotation)
	return tile_world_origin(tile.gx + dx, tile.gy + dy, tile.gz + dz)
}

get_surface_at :: proc(pos: rl.Vector3) -> Surface {
	bpos := b3.Vec3{pos.x, pos.y, pos.z}
	best_dist := f32(1e10)
	surface := Surface.Pavement

	for piece in current_track.tiles {
		origin := tile_world_origin(piece.gx, piece.gy, piece.gz)
		dir_angle := f32(piece.rotation) * math.PI * 0.5
		q_dir := b3.MakeQuatFromAxisAngle(b3.Vec3_axisY, dir_angle)

		samples := generate_centerline(piece.template, piece.dy, context.temp_allocator)
		for sample in samples {
			world_pos := origin + b3.RotateVector(q_dir, sample.pos)
			dist := b3.Distance(bpos, world_pos)
			if dist < best_dist {
				best_dist = dist
				surface = piece.surface
			}
		}
	}

	if best_dist < ROAD_WIDTH {
		return surface
	}
	return .Pavement
}
