package main

import "core:fmt"
import rl "vendor:raylib"
import b3 "vendor:box3d"

ROAD_WIDTH     :: f32(10.0)
ROAD_THICKNESS :: f32(0.15)

WallType :: enum {
	None,
	Wall,
	Curb,
}

TrackControlPoint :: struct {
	pos:       rl.Vector3,
	surface:   Surface,
	wall_left:  WallType,
	wall_right: WallType,
	boost:     bool,
}

SurfaceSample :: struct {
	pos:     b3.Vec3,
	surface: Surface,
}

Track3D :: struct {
	points:         []TrackControlPoint,
	spline_pos:     []b3.Vec3,
	mesh_model:     rl.Model,
	collision_mesh: ^b3.MeshData,
	samples:        []SurfaceSample,
	start_pos:      rl.Vector3,
	finish_pos:     rl.Vector3,
}

current_track: Track3D

RENDER_SAMPLES_PER_SEG   :: 32
SURFACE_SAMPLES_PER_SEG  :: 16
COLLISION_SAMPLES_PER_SEG :: 8

init_track :: proc() {
	points := build_map00()
	current_track.points = points
	n := len(points)

	current_track.start_pos = points[0].pos
	last := points[n-1]
	current_track.finish_pos = last.pos

	fmt.eprintfln("init_track: %d points, start=(%v) finish=(%v)", n, current_track.start_pos, current_track.finish_pos)
	for i in 0..<n {
		fmt.eprintfln("  pt[%d] pos=(%v) surface=%v", i, points[i].pos, points[i].surface)
	}

	raw_pos := make([]b3.Vec3, n)
	for i in 0..<n {
		raw_pos[i] = b3.Vec3(points[i].pos)
	}
	current_track.spline_pos = make_catmull_rom_points(raw_pos)
	fmt.eprintfln("init_track: spline has %d points (including ghosts)", len(current_track.spline_pos))

	build_surface_samples(current_track.spline_pos)
	build_track_model(current_track.spline_pos)
}

build_surface_samples :: proc(spline_pos: []b3.Vec3) {
	n := len(current_track.points)
	num_segs := n - 1
	total := num_segs * SURFACE_SAMPLES_PER_SEG + 1
	samples := make([]SurfaceSample, total)

	idx := 0
	for seg in 0..<num_segs {
		cp := current_track.points[seg]
		for s in 0..<SURFACE_SAMPLES_PER_SEG {
			t := f32(s) / f32(SURFACE_SAMPLES_PER_SEG)
			pos, _, _, _ := get_road_frame(spline_pos, seg, t)
			samples[idx] = SurfaceSample{pos = pos, surface = cp.surface}
			idx += 1
		}
	}
	last := current_track.points[n-1]
	samples[idx] = SurfaceSample{pos = b3.Vec3(last.pos), surface = last.surface}
	current_track.samples = samples
}

build_track_model :: proc(spline_pos: []b3.Vec3) {
	n := len(current_track.points)
	num_segs := n - 1
	total_samples := num_segs * RENDER_SAMPLES_PER_SEG + 1

	vc := total_samples * 2
	tc := (total_samples - 1) * 2

	vert_arr := make([]f32, vc * 3)
	norm_arr := make([]f32, vc * 3)
	tc_arr := make([]f32, vc * 2)
	col_arr := make([]u8, vc * 4)
	idx_arr := make([]u16, tc * 3)

	surface_colors := [Surface]rl.Color{
		.Dirt     = {120, 80, 40, 255},
		.Pavement = {80, 80, 80, 255},
		.Sand     = {180, 160, 100, 255},
		.Grass    = {60, 140, 60, 255},
	}

	hw := ROAD_WIDTH * 0.5

	vi := 0
	for seg in 0..<num_segs {
		cp := current_track.points[seg]
		col := surface_colors[cp.surface]

		for s in 0..<RENDER_SAMPLES_PER_SEG {
			t := f32(s) / f32(RENDER_SAMPLES_PER_SEG)
			pos, fwd, right, norm := get_road_frame(spline_pos, seg, t)

			left_v := pos + right * hw
			right_v := pos - right * hw

			right_side := [2]bool{false, true}
			for is_right in right_side {
				p := right_v if is_right else left_v
				base := vi * 3
				vert_arr[base+0] = p.x; vert_arr[base+1] = p.y; vert_arr[base+2] = p.z
				norm_arr[base+0] = norm.x; norm_arr[base+1] = norm.y; norm_arr[base+2] = norm.z
				cb := vi * 4
				col_arr[cb+0] = col.r; col_arr[cb+1] = col.g; col_arr[cb+2] = col.b; col_arr[cb+3] = col.a
				tc_arr[vi*2+0] = 1.0 if is_right else 0.0
				tc_arr[vi*2+1] = f32(seg) + t
				vi += 1
			}
		}
	}

	pos, fwd, right, norm := get_road_frame(spline_pos, num_segs-1, 1.0)
	last_cp := current_track.points[n-1]
	col := surface_colors[last_cp.surface]
	left_v := pos + right * hw
	right_v := pos - right * hw
	side_ends := [2]bool{false, true}
	for is_right in side_ends {
		p := right_v if is_right else left_v
		base := vi * 3
		vert_arr[base+0] = p.x; vert_arr[base+1] = p.y; vert_arr[base+2] = p.z
		norm_arr[base+0] = norm.x; norm_arr[base+1] = norm.y; norm_arr[base+2] = norm.z
		cb := vi * 4
		col_arr[cb+0] = col.r; col_arr[cb+1] = col.g; col_arr[cb+2] = col.b; col_arr[cb+3] = col.a
		tc_arr[vi*2+0] = 1.0 if is_right else 0.0
		tc_arr[vi*2+1] = f32(num_segs)
		vi += 1
	}

	ii := 0
	for i in 0..<total_samples - 1 {
		a := i * 2
		b := a + 1
		c := (i + 1) * 2
		d := c + 1
		idx_arr[ii+0] = u16(a)
		idx_arr[ii+1] = u16(b)
		idx_arr[ii+2] = u16(c)
		idx_arr[ii+3] = u16(c)
		idx_arr[ii+4] = u16(b)
		idx_arr[ii+5] = u16(d)
		ii += 6
	}

	mesh := rl.Mesh{
		vertexCount   = i32(vc),
		triangleCount = i32(tc),
		vertices      = raw_data(vert_arr),
		normals       = raw_data(norm_arr),
		texcoords     = raw_data(tc_arr),
		colors        = raw_data(col_arr),
		indices       = raw_data(idx_arr),
	}

	fmt.eprintfln("build_track_model: vc=%d tc=%d", vc, tc)
	for i in 0..<min(6, vc) {
		base := i * 3
		fmt.eprintfln("  vert[%d] = (%f %f %f) norm=(%f %f %f) tc=(%f %f)", i, vert_arr[base], vert_arr[base+1], vert_arr[base+2], norm_arr[base], norm_arr[base+1], norm_arr[base+2], tc_arr[i*2], tc_arr[i*2+1])
	}
	for i := max(0, vc-4); i < vc; i += 1 {
		base := i * 3
		fmt.eprintfln("  vert[%d] = (%f %f %f) norm=(%f %f %f) tc=(%f %f)", i, vert_arr[base], vert_arr[base+1], vert_arr[base+2], norm_arr[base], norm_arr[base+1], norm_arr[base+2], tc_arr[i*2], tc_arr[i*2+1])
	}
	fmt.eprintfln("  first 12 indices: %d %d %d %d %d %d %d %d %d %d %d %d", idx_arr[0], idx_arr[1], idx_arr[2], idx_arr[3], idx_arr[4], idx_arr[5], idx_arr[6], idx_arr[7], idx_arr[8], idx_arr[9], idx_arr[10], idx_arr[11])
	max_idx := u16(0)
	for i in 0..<len(idx_arr) {
		if idx_arr[i] > max_idx { max_idx = idx_arr[i] }
	}
	fmt.eprintfln("  max index = %d (vc=%d, valid=%v)", max_idx, vc, max_idx < u16(vc))

	rl.UploadMesh(&mesh, false)
	current_track.mesh_model = rl.LoadModelFromMesh(mesh)
}

get_surface_at :: proc(pos: rl.Vector3) -> Surface {
	if len(current_track.samples) == 0 {
		return .Pavement
	}
	bpos := b3.Vec3{pos.x, pos.y, pos.z}
	best_d := f32(1e10)
	best_surface := Surface.Pavement

	for s in current_track.samples {
		d := b3.DistanceSquared(bpos, s.pos)
		if d < best_d {
			best_d = d
			best_surface = s.surface
		}
	}

	if best_d < ROAD_WIDTH * ROAD_WIDTH {
		return best_surface
	}
	return .Pavement
}

get_track_points :: proc() -> []TrackControlPoint {
	return current_track.points
}

get_start_position :: proc() -> rl.Vector3 {
	return current_track.start_pos
}

get_track_finish :: proc() -> rl.Vector3 {
	return current_track.finish_pos
}

get_track_mesh_model :: proc() -> rl.Model {
	return current_track.mesh_model
}

get_track_spline :: proc() -> []b3.Vec3 {
	return current_track.spline_pos
}
