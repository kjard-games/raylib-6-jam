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

// Each block's start connects to the previous block's end.
// End X = start.x + curvature * length * 0.3  (center offset)
// End Z = start.z + length

track1_blocks := []TrackBlock{
	// Start straight — Pavement
	{surface = .Pavement, start = {0, 0, 0}, length = 40, width = 8, curvature = 0},
	// Gentle right — Pavement
	{surface = .Pavement, start = {0, 0, 40}, length = 30, width = 8, curvature = 0.3},
	// Transition to Dirt
	{surface = .Dirt, start = {2.70, 0, 70}, length = 35, width = 8, curvature = -0.2},
	// Dirt chicane right
	{surface = .Dirt, start = {0.60, 0, 105}, length = 25, width = 8, curvature = 0.5},
	// Dirt chicane left
	{surface = .Dirt, start = {4.35, 0, 130}, length = 25, width = 8, curvature = -0.5},
	// Dirt straight
	{surface = .Dirt, start = {0.60, 0, 155}, length = 30, width = 8, curvature = 0},
	// Transition to Sand
	{surface = .Sand, start = {0.60, 0, 185}, length = 40, width = 10, curvature = 0.25},
	// Sand sweeping right
	{surface = .Sand, start = {3.60, 0, 225}, length = 50, width = 10, curvature = 0.4},
	// Sand straight
	{surface = .Sand, start = {9.60, 0, 275}, length = 35, width = 10, curvature = 0},
	// Transition to Grass
	{surface = .Grass, start = {9.60, 0, 310}, length = 30, width = 9, curvature = -0.3},
	// Grass winding right
	{surface = .Grass, start = {6.90, 0, 340}, length = 20, width = 9, curvature = 0.6},
	// Grass winding left
	{surface = .Grass, start = {10.50, 0, 360}, length = 20, width = 9, curvature = -0.6},
	// Grass straight
	{surface = .Grass, start = {6.90, 0, 380}, length = 30, width = 9, curvature = 0},
	// Transition back to Pavement
	{surface = .Pavement, start = {6.90, 0, 410}, length = 40, width = 8, curvature = 0.15},
	// Finish straight
	{surface = .Pavement, start = {8.70, 0, 450}, length = 50, width = 8, curvature = 0},
}

track1_checkpoints := []Checkpoint{
	{position = {0, 0.5, 0}, index = 0},
	{position = {1.5, 0.5, 85}, index = 1},
	{position = {2, 0.5, 170}, index = 2},
	{position = {6, 0.5, 255}, index = 3},
	{position = {8, 0.5, 350}, index = 4},
	{position = {8.7, 0.5, 475}, index = 5},
}

current_track: TrackData

init_track :: proc() {
	current_track.blocks = track1_blocks[:]
	current_track.checkpoints = track1_checkpoints[:]
	current_track.start_pos = {0, 0.5, 0}
	current_track.finish_pos = {8.70, 0.5, 500}
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

get_track_finish :: proc() -> rl.Vector3 {
	return current_track.finish_pos
}

block_center :: proc(block: TrackBlock) -> rl.Vector3 {
	cx := block.start.x + block.curvature * block.length * 0.3
	cz := block.start.z + block.length / 2
	return {cx, 0, cz}
}
