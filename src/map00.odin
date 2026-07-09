package main

import rl "vendor:raylib"
import b3 "vendor:box3d"

build_map00 :: proc() -> []TrackControlPoint {
	raw := [12]TrackControlPoint{
		{pos = {0, 0, 0},     surface = .Pavement, wall_left = .Wall, wall_right = .Wall},
		{pos = {30, 1, 60},   surface = .Pavement, wall_left = .Wall, wall_right = .Wall},
		{pos = {70, 2, 100},  surface = .Pavement, wall_left = .Wall, wall_right = .Wall},
		{pos = {140, 2, 120}, surface = .Dirt,     wall_left = .None, wall_right = .None},
		{pos = {210, 1, 100}, surface = .Dirt,     wall_left = .None, wall_right = .None},
		{pos = {220, 0, 40},  surface = .Dirt,     wall_left = .None, wall_right = .None},
		{pos = {170, -1, -30}, surface = .Dirt,   wall_left = .None, wall_right = .None},
		{pos = {100, -1, -80}, surface = .Sand,   wall_left = .None, wall_right = .None},
		{pos = {30, 0, -100},  surface = .Sand,   wall_left = .None, wall_right = .None},
		{pos = {-40, 0, -80},  surface = .Sand,   wall_left = .None, wall_right = .None},
		{pos = {-80, 1, -40},  surface = .Grass,  wall_left = .None, wall_right = .None},
		{pos = {-50, 2, 10},   surface = .Grass,  wall_left = .None, wall_right = .None},
	}
	result := make([]TrackControlPoint, len(raw))
	copy(result, raw[:])
	return result
}
