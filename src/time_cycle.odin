package main

TimePhase :: enum i32 {
	Noon,
	Dusk,
	Midnight,
	Dawn,
}

PHASE_COUNT :: 4

Effect :: enum i32 {
	Neutral,
	Accel,
	Drift,
}

// Base effect per (surface, stance) at P=0 (Noon).
// Stance order inside each entry: [Speed, Drift, Fist, OK].
// At phase P, the effect for stance S is base_sequence[surface][(S - P) mod 4].

base_sequences := [Surface][4]Effect{
	.Dirt     = {.Drift, .Neutral, .Neutral, .Accel},
	.Pavement = {.Accel, .Neutral, .Drift,  .Neutral},
	.Sand     = {.Neutral, .Accel, .Neutral, .Drift},
	.Grass    = {.Neutral, .Drift, .Accel,  .Neutral},
}

TimeState :: struct {
	current_phase: TimePhase,
}

time_state: TimeState

init_time :: proc() {
	time_state.current_phase = .Noon
}

get_current_phase :: proc() -> TimePhase {
	return time_state.current_phase
}

advance_phase :: proc() {
	time_state.current_phase = TimePhase((int(time_state.current_phase) + 1) % PHASE_COUNT)
}

get_effect :: proc(surface: Surface, stance: Stance) -> Effect {
	if stance == .Advance {
		return .Neutral
	}
	stance_idx := int(stance)
	phase_offset := int(time_state.current_phase)
	effective_idx := (stance_idx - phase_offset) % 4
	if effective_idx < 0 {
		effective_idx += 4
	}
	return base_sequences[surface][effective_idx]
}
