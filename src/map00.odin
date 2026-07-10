package main

import rl "vendor:raylib"
import b3 "vendor:box3d"

build_map00 :: proc() -> []TrackControlPoint {
	raw := [31]TrackControlPoint{
		// === START/FINISH STRAIGHT === pavement, walls for first section
		{pos = {0, 0, 0},     surface = .Pavement, wall_left = .Wall, wall_right = .Wall, width = 10, bank = 0},
		{pos = {5, 4, 80},    surface = .Pavement, wall_left = .Wall, wall_right = .Wall, width = 10, bank = 0},
		{pos = {15, 6, 160},  surface = .Pavement, wall_left = .Wall, wall_right = .Wall, width = 10, bank = 0},

		// === BANKED RIGHT SWEEPER === pavement, wide with banking
		{pos = {55, 7, 240},  surface = .Pavement, width = 14, bank = 0.15},
		{pos = {135, 6, 290}, surface = .Pavement, width = 16, bank = 0.35},
		{pos = {215, 5, 260}, surface = .Pavement, width = 14, bank = 0.25},
		{pos = {255, 4, 190}, surface = .Pavement, width = 12, bank = 0.10},

		// === TECHNICAL DIRT S-CURVES === narrow, no banking
		{pos = {260, 2, 105}, surface = .Dirt, width = 8, bank = 0},
		{pos = {235, 1, 35},  surface = .Dirt, width = 6, bank = 0},
		{pos = {180, 0, -15}, surface = .Dirt, width = 6, bank = 0},
		{pos = {125, 0, 15},  surface = .Dirt, width = 7, bank = 0},
		{pos = {90, 1, 60},   surface = .Dirt, width = 8, bank = 0},

		// === BOBSLEIGH DIP === sand, steep elevation changes
		{pos = {70, 2, 110},   surface = .Sand, width = 10, bank = 0},
		{pos = {55, -10, 170}, surface = .Sand, width = 10, bank = 0},
		{pos = {80, -25, 225}, surface = .Sand, width = 10, bank = 0},
		{pos = {135, -32, 250}, surface = .Sand, width = 10, bank = 0},
		{pos = {200, -24, 230}, surface = .Sand, width = 10, bank = 0},
		{pos = {245, -10, 185}, surface = .Sand, width = 10, bank = 0},
		{pos = {265, 4, 120},  surface = .Sand, width = 10, bank = 0},

		// === GRASS CHICANE === very narrow, tight flicks
		{pos = {250, 5, 55},   surface = .Grass, width = 5, bank = 0},
		{pos = {210, 6, 15},   surface = .Grass, width = 5, bank = 0},
		{pos = {155, 5, 25},   surface = .Grass, width = 5, bank = 0},
		{pos = {110, 4, 60},   surface = .Grass, width = 5, bank = 0},

		// === WIDE LEFT SWEEPER (BANKED) === dirt, negative bank (left side lower)
		{pos = {70, 3, 95},    surface = .Dirt, width = 12, bank = -0.15},
		{pos = {20, 3, 130},   surface = .Dirt, width = 14, bank = -0.30},
		{pos = {-40, 4, 115},  surface = .Dirt, width = 13, bank = -0.25},
		{pos = {-70, 5, 70},   surface = .Dirt, width = 11, bank = -0.10},

		// === RETURN STRAIGHT === pavement, closing the loop
		{pos = {-70, 4, 10},   surface = .Pavement, width = 10, bank = 0},
		{pos = {-45, 1, -25},  surface = .Pavement, width = 10, bank = 0},
		{pos = {-15, 0, -15},  surface = .Pavement, width = 10, bank = 0},
		{pos = {0, 0, -1},     surface = .Pavement, wall_left = .Wall, wall_right = .Wall, width = 10, bank = 0},
	}
	result := make([]TrackControlPoint, len(raw))
	copy(result, raw[:])
	return result
}
