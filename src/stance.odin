package main

Stance :: enum i32 {
	Speed,
	Drift,
	Fist,
	OK,
	Advance,
}

STANCE_ORDER := [5]Stance{.Speed, .Drift, .Fist, .OK, .Advance}

STANCE_COUNT :: 5

// Pentagram adjacency (across the star):
//   Speed ↔ Fist, Thumbs
//   Drift ↔ OK, Thumbs
//   Fist ↔ Speed, OK
//   OK ↔ Drift, Fist
//   Thumbs ↔ Speed, Drift
// Stored as a bitmask of reachable stances.

stance_adjacency := [Stance]u32{
	.Speed   = (1 << auto_cast Stance.Fist) | (1 << auto_cast Stance.Advance),
	.Drift   = (1 << auto_cast Stance.OK) | (1 << auto_cast Stance.Advance),
	.Fist    = (1 << auto_cast Stance.Speed) | (1 << auto_cast Stance.OK),
	.OK      = (1 << auto_cast Stance.Drift) | (1 << auto_cast Stance.Fist),
	.Advance = (1 << auto_cast Stance.Speed) | (1 << auto_cast Stance.Drift),
}

DEBOUNCE_DURATION :: 6.0

StanceState :: struct {
	current:          Stance,
	debounce_timer:   f32,
	debounce_active:  bool,
	advanced_this_frame: bool,
}

stance_state: StanceState

init_stance :: proc() {
	stance_state.current = .Advance
	stance_state.debounce_timer = 0
	stance_state.debounce_active = false
}

get_current_stance :: proc() -> Stance {
	return stance_state.current
}

is_adjacent :: proc(from, to: Stance) -> bool {
	mask := stance_adjacency[from]
	return (mask & (1 << auto_cast to)) != 0
}

get_valid_targets :: proc() -> [2]Stance {
	result: [2]Stance
	idx := 0
	mask := stance_adjacency[stance_state.current]
	order := STANCE_ORDER
	for s in order {
		if (mask & (1 << auto_cast s)) != 0 {
			result[idx] = s
			idx += 1
		}
	}
	return result
}

switch_stance :: proc(target: Stance) -> bool {
	if stance_state.debounce_active {
		return false
	}
	if target == stance_state.current {
		return false
	}
	if !is_adjacent(stance_state.current, target) {
		return false
	}
	stance_state.current = target
	stance_state.debounce_timer = DEBOUNCE_DURATION
	stance_state.debounce_active = true
	if target == .Advance {
		stance_state.advanced_this_frame = true
	}
	return true
}

switch_stance_unchecked :: proc(target: Stance) {
	if target == stance_state.current {
		return
	}
	stance_state.current = target
	stance_state.debounce_timer = DEBOUNCE_DURATION
	stance_state.debounce_active = true
	if target == .Advance {
		stance_state.advanced_this_frame = true
	}
}

get_debounce_remaining :: proc() -> f32 {
	if !stance_state.debounce_active {
		return 0
	}
	return stance_state.debounce_timer
}

consume_advance_flag :: proc() -> bool {
	if stance_state.advanced_this_frame {
		stance_state.advanced_this_frame = false
		return true
	}
	return false
}

update_stance :: proc(dt: f32) {
	if stance_state.debounce_active {
		stance_state.debounce_timer -= dt
		if stance_state.debounce_timer <= 0 {
			stance_state.debounce_timer = 0
			stance_state.debounce_active = false
		}
	}
}
