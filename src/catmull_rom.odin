package main

import b3 "vendor:box3d"

// Builds ghost-points array for an open Catmull-Rom spline from N control points.
// Returns N+2 points: ghost start, control[0..N-1], ghost end.
// Free with delete().
make_catmull_rom_points :: proc(points: []b3.Vec3, allocator := context.allocator) -> []b3.Vec3 {
	n := len(points)
	if n < 2 { return nil }
	result := make([]b3.Vec3, n + 2, allocator)
	result[0] = 2 * points[0] - points[1]
	copy(result[1:], points)
	result[n+1] = 2 * points[n-1] - points[n-2]
	return result
}

// Evaluate a uniform Catmull-Rom spline at segment i, parameter t in [0,1].
// p must have at least segment+4 elements (ghost-points array of N+2, segment in 0..N-2).
catmull_rom_eval :: proc(p: []b3.Vec3, segment: int, t: f32) -> b3.Vec3 {
	p0, p1, p2, p3 := p[segment], p[segment+1], p[segment+2], p[segment+3]
	t2 := t * t
	t3 := t2 * t
	return 0.5 * (
		(2 * p1) +
		(-p0 + p2) * t +
		(2*p0 - 5*p1 + 4*p2 - p3) * t2 +
		(-p0 + 3*p1 - 3*p2 + p3) * t3
	)
}

// Derivative of the Catmull-Rom spline at segment i, parameter t in [0,1].
catmull_rom_derivative :: proc(p: []b3.Vec3, segment: int, t: f32) -> b3.Vec3 {
	p0, p1, p2, p3 := p[segment], p[segment+1], p[segment+2], p[segment+3]
	t2 := t * t
	return 0.5 * (
		(-p0 + p2) +
		2 * (2*p0 - 5*p1 + 4*p2 - p3) * t +
		3 * (-p0 + 3*p1 - 3*p2 + p3) * t2
	)
}

// Returns the frame (pos, forward, right, normal) along the road at a spline sample.
get_road_frame :: proc(spline_pos: []b3.Vec3, segment: int, t: f32) -> (pos, forward, right, normal: b3.Vec3) {
	pos = catmull_rom_eval(spline_pos, segment, t)
	forward = catmull_rom_derivative(spline_pos, segment, t)
	fl := b3.Length(forward)
	if fl < 0.0001 {
		forward = {0, 0, 1}
	} else {
		forward = forward * (1.0 / fl)
	}
	up := b3.Vec3{0, 1, 0}
	right = b3.Normalize(b3.Cross(up, forward))
	normal = b3.Normalize(b3.Cross(forward, right))
	return
}

// Build a quaternion from the road frame (forward, right, up).
// The resulting quaternion rotates local Z to forward, local X to right, local Y to up.
make_quat_from_road_frame :: proc(forward, right: b3.Vec3) -> b3.Quat {
	up := b3.Normalize(b3.Cross(forward, right))
	m := matrix[3, 3]f32{
		right.x,   up.x,   forward.x,
		right.y,   up.y,   forward.y,
		right.z,   up.z,   forward.z,
	}
	return b3.MakeQuatFromMatrix(m)
}
