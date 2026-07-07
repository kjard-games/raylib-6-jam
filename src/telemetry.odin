package main

import "core:c"
import "core:fmt"
import "core:strings"
import "core:time"
import rl "vendor:raylib"
import b3 "vendor:box3d"

FIXED_DT :: 1.0 / 60.0
MAX_TICKS :: 60 * 60 * 10

TickInputs :: struct {
	steer:      f32,
	accelerate: bool,
	brake:      bool,
	stance:     Stance,
}

TelemetryTick :: struct {
	using inputs: TickInputs,
	pos_x:     f32,
	pos_z:     f32,
	speed:     f32,
	surface:   Surface,
	effect:    Effect,
	phase:     TimePhase,
}

TelemetryState :: struct {
	buffer:        [MAX_TICKS]TelemetryTick,
	count:         int,
	recording:     bool,
	playing_back:  bool,
	playback_idx:  int,
	accumulator:   f32,
	race_time:     f64,
}

telemetry: TelemetryState

stance_names := [Stance]string{
	.Speed   = "Speed",
	.Drift   = "Drift",
	.Fist    = "Fist",
	.OK      = "OK",
	.Advance = "Advance",
}

surface_names := [Surface]string{
	.Dirt     = "Dirt",
	.Pavement = "Pavement",
	.Sand     = "Sand",
	.Grass    = "Grass",
}

effect_names := [Effect]string{
	.Neutral = "Neutral",
	.Accel   = "Accel",
	.Drift   = "Drift",
}

phase_names := [TimePhase]string{
	.Noon     = "Noon",
	.Dusk     = "Dusk",
	.Midnight = "Midnight",
	.Dawn     = "Dawn",
}

init_telemetry :: proc() {
	telemetry.recording = true
	telemetry.playing_back = false
	telemetry.count = 0
	telemetry.playback_idx = 0
	telemetry.accumulator = 0
	telemetry.race_time = 0
}

record_tick :: proc(inputs: TickInputs) {
	if !telemetry.recording || telemetry.count >= MAX_TICKS {
		return
	}
	pos := get_broom_position()
	speed := get_broom_speed()
	surface := get_surface_at(pos)
	stance := inputs.stance
	effect := get_effect(surface, stance)
	phase := get_current_phase()

	telemetry.buffer[telemetry.count] = TelemetryTick{
		steer = inputs.steer,
		accelerate = inputs.accelerate,
		brake = inputs.brake,
		stance = stance,
		pos_x = pos.x,
		pos_z = pos.z,
		speed = speed,
		surface = surface,
		effect = effect,
		phase = phase,
	}
	telemetry.count += 1
}

build_csv :: proc() -> string {
	if telemetry.count == 0 {
		return ""
	}

	b := strings.builder_make()
	defer strings.builder_destroy(&b)

	strings.write_string(&b, "tick,steer,accelerate,brake,stance,pos_x,pos_z,speed,surface,effect,phase\n")

	for i in 0 ..< telemetry.count {
		t := telemetry.buffer[i]
		fmt.sbprintf(&b, "%d,%f,%d,%d,%s,%f,%f,%f,%s,%s,%s\n",
			i,
			t.steer,
			t.accelerate ? 1 : 0,
			t.brake ? 1 : 0,
			stance_names[t.stance],
			t.pos_x,
			t.pos_z,
			t.speed,
			surface_names[t.surface],
			effect_names[t.effect],
			phase_names[t.phase],
		)
	}

	return strings.to_string(b)
}

finish_run :: proc() {
	if telemetry.count == 0 {
		return
	}

	csv := build_csv()
	defer delete(csv)

	when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32 {
		fmt.println("=== TELEMETRY ===")
		fmt.println(csv)
		fmt.println("=== END ===")
	} else {
		save_csv_file(csv)
	}
	init_telemetry()
}

save_csv_file :: proc(csv: string) {
	now := time.now()
	year, month, day := time.date(now)
	hour, min, sec := time.clock(now)
	filename := fmt.tprintf("telemetry/run_%04d%02d%02d_%02d%02d%02d.csv", year, month, day, hour, min, sec)
	fmt.printfln("Saving telemetry to %s", filename)
	fn := strings.clone_to_cstring(filename, context.temp_allocator)
	rl.SaveFileData(fn, raw_data(csv), c.int(len(csv)))
}

// Fixed-timestep tick — called by the game loop accumulator.
// Returns true while the race is active (not finished).
tick :: proc() -> bool {
	if state.race_phase == .Countdown {
		return true
	}

	if telemetry.playing_back {
		if telemetry.playback_idx >= telemetry.count {
			telemetry.playing_back = false
			return false
		}
		recorded := telemetry.buffer[telemetry.playback_idx]
		telemetry.playback_idx += 1

		controls_state.steer = recorded.steer
		controls_state.accelerate = recorded.accelerate
		controls_state.brake = recorded.brake
		if recorded.stance != get_current_stance() {
			switch_stance_unchecked(recorded.stance)
		}
	} else {
		update_controls()
	}

	update_stance(FIXED_DT)

	if consume_advance_flag() {
		advance_phase()
	}

	if state.race_phase == .Racing {
		state.race_time += FIXED_DT
	}

	if !telemetry.playing_back {
		inputs := TickInputs{
			steer = controls_state.steer,
			accelerate = controls_state.accelerate,
			brake = controls_state.brake,
			stance = get_current_stance(),
		}
		record_tick(inputs)
	}

	simulate_broom(FIXED_DT)
	b3.World_Step(state.world, FIXED_DT, 4)
	sync_broom()

	pos := get_broom_position()
	if state.race_phase == .Racing && pos.z >= current_track.finish_pos.z {
		state.race_phase = .Finished
		telemetry.recording = false
		finish_run()
	}

	update_camera()

	return true
}
