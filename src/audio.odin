package main

import rl "vendor:raylib"

AudioAssets :: struct {
	engine: rl.Sound,
	skid:   rl.Sound,
	impact: rl.Sound,
}

audio: AudioAssets

init_audio :: proc() {
	audio.engine = rl.LoadSound("assets/kenney_racing/audio/engine.ogg")
	audio.skid = rl.LoadSound("assets/kenney_racing/audio/skid.ogg")
	audio.impact = rl.LoadSound("assets/kenney_racing/audio/impact.ogg")
}

start_engine :: proc() {
	rl.PlaySound(audio.engine)
}

stop_engine :: proc() {
	rl.StopSound(audio.engine)
}

play_skid :: proc() {
	if !rl.IsSoundPlaying(audio.skid) {
		rl.PlaySound(audio.skid)
	}
}

stop_skid :: proc() {
	if rl.IsSoundPlaying(audio.skid) {
		rl.StopSound(audio.skid)
	}
}

play_impact :: proc() {
	rl.PlaySound(audio.impact)
}

shutdown_audio :: proc() {
	rl.UnloadSound(audio.engine)
	rl.UnloadSound(audio.skid)
	rl.UnloadSound(audio.impact)
}
