package main

import "core:math"
import b3 "vendor:box3d"

CELL_SIZE     :: f32(25.0)
CELL_HEIGHT   :: f32(5.0)
ROAD_WIDTH    :: f32(10.0)
ROAD_THICKNESS :: f32(0.15)

CANVAS_SIZE   :: 200

BlockTemplate :: enum {
	Straight,
	Turn,
	Slope,
	Descent,
	TurnSlope,
	JumpRamp,
}

WallType :: enum {
	None,
	Wall,
	Curb,
}

RoadHull :: struct {
	pos:   b3.Vec3,
	rot:   b3.Quat,
	hx:    f32,
	hy:    f32,
	hz:    f32,
}

template_in_local :: proc(t: BlockTemplate, dy: int) -> b3.Vec3 {
	S2 := CELL_SIZE * 0.5
	switch t {
	case .Straight, .Slope, .Descent, .Turn, .TurnSlope, .JumpRamp:
		return {0, 0, -S2}
	}
	return {0, 0, -S2}
}

template_out_local :: proc(t: BlockTemplate, dy: int) -> b3.Vec3 {
	S2 := CELL_SIZE * 0.5
	height := f32(dy) * CELL_HEIGHT
	switch t {
	case .Straight:  return {0, 0, S2}
	case .Slope:     return {0, height, S2}
	case .Descent:   return {0, -height, S2}
	case .Turn:      return {S2, 0, 0}
	case .TurnSlope: return {S2, height, 0}
	case .JumpRamp:  return {0, height, S2}
	}
	return {0, 0, S2}
}

generate_template_hulls :: proc(template: BlockTemplate, dy: int, allocator := context.allocator) -> []RoadHull {
	S := CELL_SIZE
	H := CELL_HEIGHT
	W := ROAD_WIDTH
	T := f32(0.25)

	switch template {
	case .Straight: {
		res := make([]RoadHull, 1, allocator)
		res[0] = {
			pos = {0, 0, 0},
			rot = b3.Quat_identity,
			hx = W * f32(0.5),
			hy = T,
			hz = S * f32(0.5),
		}
		return res
	}

	case .Slope: {
		total_h := f32(dy) * H
		angle := f32(math.atan2(f64(total_h), f64(S)))
		half_len := f32(math.sqrt(f64(S*S + total_h*total_h))) * f32(0.5)
		res := make([]RoadHull, 1, allocator)
		res[0] = {
			pos = {0, total_h * 0.5, 0},
			rot = b3.MakeQuatFromAxisAngle(b3.Vec3_axisX, -angle),
			hx = W * f32(0.5),
			hy = T,
			hz = half_len,
		}
		return res
	}

	case .Descent: {
		total_h := f32(abs(dy)) * H
		angle := f32(math.atan2(f64(total_h), f64(S)))
		half_len := f32(math.sqrt(f64(S*S + total_h*total_h))) * f32(0.5)
		res := make([]RoadHull, 1, allocator)
		res[0] = {
			pos = {0, -total_h * 0.5, 0},
			rot = b3.MakeQuatFromAxisAngle(b3.Vec3_axisX, angle),
			hx = W * f32(0.5),
			hy = T,
			hz = half_len,
		}
		return res
	}

	case .Turn: {
		N :: 4
		res := make([]RoadHull, N, allocator)
		radius := S * f32(0.5)
		arc_len := (math.PI * f32(0.5)) * radius
		half_seg := arc_len * f32(0.5) / f32(N)

		for i in 0 ..< N {
			t_mid := (f32(i) + f32(0.5)) / f32(N)
			angle := t_mid * math.PI * f32(0.5)

			cx := (S * f32(0.5)) - radius * f32(math.cos(f64(angle)))
			cz := (-S * f32(0.5)) + radius * f32(math.sin(f64(angle)))

			res[i] = {
				pos = {cx, 0, cz},
				rot = b3.MakeQuatFromAxisAngle(b3.Vec3_axisY, angle),
				hx = W * f32(0.5),
				hy = T,
				hz = half_seg,
			}
		}
		return res
	}

	case .TurnSlope: {
		N :: 4
		res := make([]RoadHull, N, allocator)
		radius := S * f32(0.5)
		arc_len := (math.PI * f32(0.5)) * radius
		half_seg := arc_len * f32(0.5) / f32(N)
		total_h := f32(dy) * H
		slope_angle := f32(math.atan2(f64(total_h), f64(arc_len)))

		for i in 0 ..< N {
			t_mid := (f32(i) + f32(0.5)) / f32(N)
			angle := t_mid * math.PI * f32(0.5)

			cx := (S * f32(0.5)) - radius * f32(math.cos(f64(angle)))
			cz := (-S * f32(0.5)) + radius * f32(math.sin(f64(angle)))
			cy := total_h * t_mid

			q_y := b3.MakeQuatFromAxisAngle(b3.Vec3_axisY, angle)
			right := b3.RotateVector(q_y, b3.Vec3_axisX)
			q_slope := b3.MakeQuatFromAxisAngle(right, slope_angle)

			res[i] = {
				pos = {cx, cy, cz},
				rot = b3.MulQuat(q_slope, q_y),
				hx = W * f32(0.5),
				hy = T,
				hz = half_seg,
			}
		}
		return res
	}

	case .JumpRamp: {
		res := make([]RoadHull, 2, allocator)
		res[0] = {
			pos = {0, 0, -S * 0.25},
			rot = b3.Quat_identity,
			hx = W * 0.5,
			hy = T,
			hz = S * 0.25,
		}
		total_h := f32(abs(dy)) * H
		angle := f32(math.atan2(f64(total_h), f64(S * 0.5)))
		half_len := f32(math.sqrt(f64(S * 0.5 * S * 0.5 + total_h * total_h))) * f32(0.5)
		cx := S * 0.25
		cy := total_h * 0.5
		res[1] = {
			pos = {0, cy, cx},
			rot = b3.MakeQuatFromAxisAngle(b3.Vec3_axisX, -angle),
			hx = W * 0.5,
			hy = T,
			hz = half_len,
		}
		return res
	}
	}

	return nil
}

generate_edge_hulls :: proc(template: BlockTemplate, dy: int, wall_left: WallType, wall_right: WallType, allocator := context.allocator) -> []RoadHull {
	S := CELL_SIZE
	W := ROAD_WIDTH
	hw := W * 0.5

	n := 0
	if wall_left != .None { n += 1 }
	if wall_right != .None { n += 1 }
	if n == 0 { return nil }

	res := make([]RoadHull, n, allocator)
	idx := 0
	left_half := hw + 0.5
	right_half := hw + 0.5

	if wall_left == .Wall {
		res[idx] = {pos = {left_half, 8, 0}, rot = b3.Quat_identity, hx = 0.5, hy = 8, hz = S * 0.5}
		idx += 1
	} else if wall_left == .Curb {
		res[idx] = {pos = {left_half, 0.4, 0}, rot = b3.Quat_identity, hx = 0.3, hy = 0.4, hz = S * 0.5}
		idx += 1
	}

	if wall_right == .Wall {
		res[idx] = {pos = {-right_half, 8, 0}, rot = b3.Quat_identity, hx = 0.5, hy = 8, hz = S * 0.5}
		idx += 1
	} else if wall_right == .Curb {
		res[idx] = {pos = {-right_half, 0.4, 0}, rot = b3.Quat_identity, hx = 0.3, hy = 0.4, hz = S * 0.5}
		idx += 1
	}

	return res
}

CenterlineSample :: struct {
	pos:  b3.Vec3,
	fwd:  b3.Vec3,
}

generate_centerline :: proc(template: BlockTemplate, dy: int, allocator := context.allocator) -> []CenterlineSample {
	S := CELL_SIZE
	H := CELL_HEIGHT
	total_h := f32(dy) * H
	N :: 16

	switch template {
	case .Straight: {
		res := make([]CenterlineSample, N, allocator)
		for i in 0 ..< N {
			t := f32(i) / f32(N - 1)
			z := -S * f32(0.5) + t * S
			res[i] = {
				pos = {0, 0, z},
				fwd = {0, 0, 1},
			}
		}
		return res
	}

	case .Slope: {
		res := make([]CenterlineSample, N, allocator)
		for i in 0 ..< N {
			t := f32(i) / f32(N - 1)
			z := -S * f32(0.5) + t * S
			y := t * total_h
			res[i] = {
				pos = {0, y, z},
				fwd = {0, total_h / S, 1},
			}
			fl := math.sqrt(res[i].fwd.x * res[i].fwd.x + res[i].fwd.y * res[i].fwd.y + res[i].fwd.z * res[i].fwd.z)
			res[i].fwd /= fl
		}
		return res
	}

	case .Descent: {
		res := make([]CenterlineSample, N, allocator)
		for i in 0 ..< N {
			t := f32(i) / f32(N - 1)
			z := -S * f32(0.5) + t * S
			y := -t * total_h
			res[i] = {
				pos = {0, y, z},
				fwd = {0, -total_h / S, 1},
			}
			fl := math.sqrt(res[i].fwd.x * res[i].fwd.x + res[i].fwd.y * res[i].fwd.y + res[i].fwd.z * res[i].fwd.z)
			res[i].fwd /= fl
		}
		return res
	}

	case .Turn: {
		res := make([]CenterlineSample, N, allocator)
		radius := S * f32(0.5)
		for i in 0 ..< N {
			t := f32(i) / f32(N - 1)
			angle := t * math.PI * f32(0.5)
			cx := (S * f32(0.5)) - radius * f32(math.cos(f64(angle)))
			cz := (-S * f32(0.5)) + radius * f32(math.sin(f64(angle)))
			fx := f32(math.sin(f64(angle)))
			fz := f32(math.cos(f64(angle)))
			fl := math.sqrt(fx * fx + fz * fz)
			res[i] = {
				pos = {cx, 0, cz},
				fwd = {fx / fl, 0, fz / fl},
			}
		}
		return res
	}

	case .TurnSlope: {
		res := make([]CenterlineSample, N, allocator)
		radius := S * f32(0.5)
		for i in 0 ..< N {
			t := f32(i) / f32(N - 1)
			angle := t * math.PI * f32(0.5)
			cx := (S * f32(0.5)) - radius * f32(math.cos(f64(angle)))
			cz := (-S * f32(0.5)) + radius * f32(math.sin(f64(angle)))
			cy := t * total_h
			fx := f32(math.sin(f64(angle)))
			fz := f32(math.cos(f64(angle)))
			fl := math.sqrt(fx * fx + fz * fz)
			res[i] = {
				pos = {cx, cy, cz},
				fwd = {fx / fl, 0, fz / fl},
			}
		}
		return res
	}

	case .JumpRamp: {
		res := make([]CenterlineSample, N, allocator)
		for i in 0 ..< N {
			t := f32(i) / f32(N - 1)
			z := -S * f32(0.5) + t * S
			y := f32(0)
			if t > 0.5 {
				ramp_t := (t - 0.5) * 2
				y = ramp_t * total_h
			}
			res[i] = {
				pos = {0, y, z},
				fwd = {0, 0, 1},
			}
		}
		return res
	}
	}

	return nil
}

tile_world_origin :: proc(gx, gy, gz: int) -> b3.Vec3 {
	return {
		f32(gx) * CELL_SIZE,
		f32(gy) * CELL_HEIGHT,
		f32(gz) * CELL_SIZE,
	}
}
