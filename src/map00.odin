package main

build_map00 :: proc() -> []Tile {
	segments := []Segment{
		// === MOUNTAIN START — high speed sweeping descent ===
		{template = .Straight, dy = 0,  surface = .Pavement, wall_left = .Wall, wall_right = .Wall, boost = false},
		{template = .Straight, dy = 0,  surface = .Pavement, wall_left = .Wall, wall_right = .Wall, boost = false},
		{template = .Descent,  dy = 4,  surface = .Pavement, wall_left = .Wall, wall_right = .Wall, boost = false},
		{template = .Straight, dy = 0,  surface = .Pavement, wall_left = .Wall, wall_right = .Wall, boost = false},
		{template = .Descent,  dy = 4,  surface = .Pavement, wall_left = .Wall, wall_right = .Wall, boost = false},
		{template = .Straight, dy = 0,  surface = .Pavement, wall_left = .Wall, wall_right = .Wall, boost = false},
		{template = .Turn,     dy = 0,  surface = .Pavement, wall_left = .Wall, wall_right = .Wall, boost = false},
		// === FOREST — technical section ===
		{template = .Straight, dy = 0,  surface = .Dirt,    wall_left = .None, wall_right = .None, boost = false},
		{template = .Straight, dy = 0,  surface = .Dirt,    wall_left = .None, wall_right = .None, boost = false},
		{template = .Turn,     dy = 0,  surface = .Dirt,    wall_left = .None, wall_right = .None, boost = false},
		{template = .Straight, dy = 0,  surface = .Dirt,    wall_left = .None, wall_right = .None, boost = false},
		{template = .Straight, dy = 0,  surface = .Dirt,    wall_left = .None, wall_right = .None, boost = false},
		{template = .Turn,     dy = 0,  surface = .Dirt,    wall_left = .None, wall_right = .None, boost = false},
		// === BEACH ===
		{template = .Straight, dy = 0,  surface = .Sand,    wall_left = .None, wall_right = .None, boost = false},
		{template = .Straight, dy = 0,  surface = .Sand,    wall_left = .None, wall_right = .None, boost = false},
		{template = .Straight, dy = 0,  surface = .Sand,    wall_left = .None, wall_right = .None, boost = false},
		// === MEADOW (finish) ===
		{template = .Straight, dy = 0,  surface = .Grass,   wall_left = .None, wall_right = .None, boost = false},
		{template = .Straight, dy = 0,  surface = .Grass,   wall_left = .None, wall_right = .None, boost = false},
		{template = .Straight, dy = 0,  surface = .Grass,   wall_left = .None, wall_right = .None, boost = false},
	}

	return build_track_from_segments(segments, 0, 100, 0, 0)
}
