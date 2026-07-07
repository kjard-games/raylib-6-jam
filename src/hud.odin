package main

import "core:math"
import rl "vendor:raylib"

PENTAGRAM_CENTER :: rl.Vector2{640, 640}
PENTAGRAM_RADIUS :: 60

stance_labels := [Stance]cstring{
	.Speed   = "SPD",
	.Drift   = "DRF",
	.Fist    = "FST",
	.OK      = "OK",
	.Advance = "ADV",
}

stance_colors := [Stance]rl.Color{
	.Speed   = {255, 200, 50, 255},
	.Drift   = {100, 200, 255, 255},
	.Fist    = {255, 100, 100, 255},
	.OK      = {100, 255, 100, 255},
	.Advance = {200, 150, 255, 255},
}

draw_hud :: proc() {
	stance := get_current_stance()
	debounce := get_debounce_remaining()
	phase := get_current_phase()
	speed := get_broom_speed()

	rl.DrawText(rl.TextFormat("SPEED: %.0f", speed), 10, 50, 20, rl.WHITE)

	phase_labels := [TimePhase]cstring{.Noon = "NOON", .Dusk = "DUSK", .Midnight = "MID", .Dawn = "DAWN"}
	rl.DrawText(phase_labels[phase], 10, 80, 20, rl.WHITE)

	rl.DrawText(rl.TextFormat("STANCE: %s", stance_labels[stance]), 10, 110, 20, stance_colors[stance])

	if debounce > 0 {
		rl.DrawText(rl.TextFormat("COOLDOWN: %.1f", debounce), 10, 140, 14, rl.ORANGE)
	}

	draw_pentagram(stance, debounce)
}

draw_pentagram :: proc(current: Stance, debounce: f32) {
	center := PENTAGRAM_CENTER
	radius := f32(PENTAGRAM_RADIUS)

	points: [5]rl.Vector2
	for i in 0 ..< 5 {
		angle := f32(i) * 2 * math.PI / 5 - math.PI / 2
		c := math.cos(angle)
		s := math.sin(angle)
		points[i] = center + rl.Vector2{radius * c, radius * s}
	}

	star_edges := [5][2]int{{0, 2}, {2, 4}, {4, 1}, {1, 3}, {3, 0}}

	fuse_progress := f32(1.0)
	if debounce > 0 {
		fuse_progress = 1.0 - debounce / DEBOUNCE_DURATION
	}
	edges_burned := int(fuse_progress * 5)
	if edges_burned > 5 {
		edges_burned = 5
	}
	edge_frac := (fuse_progress * 5) - f32(edges_burned)

	for i in 0 ..< 5 {
		p1 := points[star_edges[i][0]]
		p2 := points[star_edges[i][1]]

		if i < edges_burned {
			rl.DrawLineEx(p1, p2, 3, rl.Color{80, 30, 30, 255})
		} else if i == edges_burned && debounce > 0 {
			mid := p1 + (p2 - p1) * edge_frac
			rl.DrawLineEx(p1, mid, 3, rl.Color{80, 30, 30, 255})
			rl.DrawLineEx(mid, p2, 2, rl.ORANGE)
		} else {
			rl.DrawLineEx(p1, p2, 2, rl.ORANGE)
		}
	}

	order := STANCE_ORDER
	for i in 0 ..< 5 {
		s := order[i]
		pt := points[i]
		label := stance_labels[s]

		col := rl.GRAY
		targets := get_valid_targets()
		if s == current {
			col = stance_colors[s]
		} else {
			for t in targets {
				if s == t {
					col = stance_colors[s]
					break
				}
			}
		}
		rl.DrawText(label, i32(pt.x) - 12, i32(pt.y) - 8, 14, col)
	}

	rl.DrawCircleV(center, 18, stance_colors[current])
	center_label := stance_labels[current]
	tw := rl.MeasureText(center_label, 16)
	rl.DrawText(center_label, i32(center.x) - tw / 2, i32(center.y) - 8, 16, rl.BLACK)
}
