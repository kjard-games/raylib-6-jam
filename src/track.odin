package main

import rl "vendor:raylib"

Checkpoint :: struct {
	position: rl.Vector3,
	index:    i32,
}

TrackBlock :: struct {
	surface:   Surface,
	start:     rl.Vector3,
	length:    f32,
	width:     f32,
	curvature: f32,
}

TrackData :: struct {
	blocks:      []TrackBlock,
	checkpoints: []Checkpoint,
	start_pos:   rl.Vector3,
	finish_pos:  rl.Vector3,
}

// First track — a mix of all 4 surfaces with straight, curved and chicane sections.
// ~3 minutes at cruise speed. Blocks are placed along Z+ direction with curvature in X.

track1_blocks := []TrackBlock{
	// Start straight — Pavement
	{surface = .Pavement, start = {0, 0, 0}, length = 40, width = 8, curvature = 0},
	// Gentle right — Pavement
	{surface = .Pavement, start = {15, 0, 40}, length = 30, width = 8, curvature = 0.3},
	// Transition to Dirt
	{surface = .Dirt, start = {30, 0, 70}, length = 35, width = 8, curvature = -0.2},
	// Dirt chicane
	{surface = .Dirt, start = {20, 0, 105}, length = 25, width = 8, curvature = 0.5},
	{surface = .Dirt, start = {5, 0, 130}, length = 25, width = 8, curvature = -0.5},
	// Dirt straight
	{surface = .Dirt, start = {-10, 0, 155}, length = 30, width = 8, curvature = 0},
	// Transition to Sand
	{surface = .Sand, start = {-10, 0, 185}, length = 40, width = 10, curvature = 0.25},
	// Sand sweeping curve
	{surface = .Sand, start = {20, 0, 225}, length = 50, width = 10, curvature = 0.4},
	// Sand straight
	{surface = .Sand, start = {60, 0, 275}, length = 35, width = 10, curvature = 0},
	// Transition to Grass
	{surface = .Grass, start = {60, 0, 310}, length = 30, width = 9, curvature = -0.3},
	// Grass winding
	{surface = .Grass, start = {40, 0, 340}, length = 20, width = 9, curvature = 0.6},
	{surface = .Grass, start = {25, 0, 360}, length = 20, width = 9, curvature = -0.6},
	{surface = .Grass, start = {10, 0, 380}, length = 30, width = 9, curvature = 0},
	// Transition back to Pavement for finish
	{surface = .Pavement, start = {10, 0, 410}, length = 40, width = 8, curvature = 0.15},
	// Finish straight
	{surface = .Pavement, start = {30, 0, 450}, length = 50, width = 8, curvature = 0},
}

track1_checkpoints := []Checkpoint{
	{position = {0, 0, 0}, index = 0},
	{position = {50, 0, 100}, index = 1},
	{position = {10, 0, 200}, index = 2},
	{position = {40, 0, 300}, index = 3},
	{position = {20, 0, 400}, index = 4},
	{position = {40, 0, 475}, index = 5},
}

current_track: TrackData

init_track :: proc() {
	current_track.blocks = track1_blocks[:]
	current_track.checkpoints = track1_checkpoints[:]
	current_track.start_pos = {0, 0.5, 0}
	current_track.finish_pos = {55, 0.5, 500}
}

get_surface_at :: proc(pos: rl.Vector3) -> Surface {
	z := pos.z
	for block in current_track.blocks {
		if z >= block.start.z && z < block.start.z + block.length {
			return block.surface
		}
	}
	return .Pavement
}

get_track_blocks :: proc() -> []TrackBlock {
	return current_track.blocks
}

get_checkpoints :: proc() -> []Checkpoint {
	return current_track.checkpoints
}

get_start_position :: proc() -> rl.Vector3 {
	return current_track.start_pos
}
