package main

import rl "vendor:raylib"

TileClass :: enum u8 {
	Straight,
	CornerRight,
	CornerLeft,
	Crossing,
	Start,
}

TileDef :: struct {
	name:       string,
	model_path: string,
	class:      TileClass,
	length:     f32,
}

TileRegistry :: map[string]TileDef

add :: proc(m: ^TileRegistry, name, path: string, class: TileClass, length: f32) {
	m[name] = TileDef{name = name, model_path = path, class = class, length = length}
}

register_tiles :: proc() -> TileRegistry {
	BASE :: "assets/kenney_racing/models/"
	KIT  :: "assets/kenney_racing_kit/Models/GLTF format/"

	m := make(TileRegistry)

	// Old kenney_racing kit
	add(&m, "straight",        BASE + "track-straight.glb",   .Straight,    10)
	add(&m, "cornerRight",     BASE + "track-corner.glb",     .CornerRight, 10)
	add(&m, "cornerLeft",      BASE + "track-corner.glb",     .CornerLeft,  10)
	add(&m, "bump",            BASE + "track-bump.glb",       .Straight,    10)
	add(&m, "finish",          BASE + "track-finish.glb",     .Straight,    10)

	// New Kenney Racing Kit road pieces
	add(&m, "roadStraight",        KIT + "roadStraight.glb",        .Straight,    10)
	add(&m, "roadStraightLong",    KIT + "roadStraightLong.glb",    .Straight,    20)
	add(&m, "roadStraightLongMid", KIT + "roadStraightLongMid.glb", .Straight,    10)
	add(&m, "roadStraightArrow",   KIT + "roadStraightArrow.glb",   .Straight,    10)
	add(&m, "roadStraightSkew",    KIT + "roadStraightSkew.glb",    .Straight,    10)
	add(&m, "roadStraightBridge",  KIT + "roadStraightBridge.glb",  .Straight,    10)

	add(&m, "roadCornerSmall",      KIT + "roadCornerSmall.glb",      .CornerRight, 10)
	add(&m, "roadCornerLarge",      KIT + "roadCornerLarge.glb",      .CornerRight, 10)
	add(&m, "roadCornerLarger",     KIT + "roadCornerLarger.glb",     .CornerRight, 10)
	add(&m, "roadCornerSmallSquare", KIT + "roadCornerSmallSquare.glb", .CornerRight, 10)

	add(&m, "roadCornerSmallBorder",  KIT + "roadCornerSmallBorder.glb",  .CornerRight, 10)
	add(&m, "roadCornerLargeBorder",  KIT + "roadCornerLargeBorder.glb",  .CornerRight, 10)
	add(&m, "roadCornerLargerBorder", KIT + "roadCornerLargerBorder.glb", .CornerRight, 10)
	add(&m, "roadCornerLargeWall",    KIT + "roadCornerLargeWall.glb",    .CornerRight, 10)
	add(&m, "roadCornerLargerWall",   KIT + "roadCornerLargerWall.glb",   .CornerRight, 10)
	add(&m, "roadCornerSmallWall",    KIT + "roadCornerSmallWall.glb",    .CornerRight, 10)
	add(&m, "roadCornerLargeSand",    KIT + "roadCornerLargeSand.glb",    .CornerRight, 10)
	add(&m, "roadCornerLargerSand",   KIT + "roadCornerLargerSand.glb",   .CornerRight, 10)
	add(&m, "roadCornerSmallSand",    KIT + "roadCornerSmallSand.glb",    .CornerRight, 10)

	add(&m, "roadCrossing",    KIT + "roadCrossing.glb",    .Crossing,   10)
	add(&m, "roadCurved",      KIT + "roadCurved.glb",      .Straight,   10)
	add(&m, "roadCurvedSplit", KIT + "roadCurvedSplit.glb", .Straight,   10)
	add(&m, "roadEnd",         KIT + "roadEnd.glb",         .Straight,   10)
	add(&m, "roadBump",        KIT + "roadBump.glb",        .Straight,   10)
	add(&m, "roadSide",        KIT + "roadSide.glb",        .Straight,   10)

	add(&m, "roadRamp",        KIT + "roadRamp.glb",        .Straight,   10)
	add(&m, "roadRampLong",    KIT + "roadRampLong.glb",    .Straight,   20)
	add(&m, "roadRampWall",    KIT + "roadRampWall.glb",    .Straight,   10)
	add(&m, "roadRampLongWall", KIT + "roadRampLongWall.glb", .Straight, 20)

	add(&m, "roadPitEntry",       KIT + "roadPitEntry.glb",       .Straight, 10)
	add(&m, "roadPitGarage",      KIT + "roadPitGarage.glb",      .Straight, 10)
	add(&m, "roadPitStraight",    KIT + "roadPitStraight.glb",    .Straight, 10)
	add(&m, "roadPitStraightLong", KIT + "roadPitStraightLong.glb", .Straight, 20)

	add(&m, "roadSplit",        KIT + "roadSplit.glb",        .Straight, 10)
	add(&m, "roadSplitSmall",   KIT + "roadSplitSmall.glb",   .Straight, 10)
	add(&m, "roadSplitLarge",   KIT + "roadSplitLarge.glb",   .Straight, 10)
	add(&m, "roadSplitLarger",  KIT + "roadSplitLarger.glb",  .Straight, 10)
	add(&m, "roadSplitRound",   KIT + "roadSplitRound.glb",   .Straight, 10)
	add(&m, "roadSplitRoundLarge", KIT + "roadSplitRoundLarge.glb", .Straight, 10)

	add(&m, "roadStart",          KIT + "roadStart.glb",          .Start,    10)
	add(&m, "roadStartPositions", KIT + "roadStartPositions.glb", .Start,    10)

	return m
}
