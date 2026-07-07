package main

Surface :: enum i32 {
	Dirt,
	Pavement,
	Sand,
	Grass,
}

SurfaceProfile :: struct {
	accel: f32,
	grip:  f32,
	drag:  f32,
}

surface_profiles := [Surface]SurfaceProfile{
	.Dirt     = {accel = 0.90, grip = 0.70, drag = 1.10},
	.Pavement = {accel = 1.00, grip = 1.00, drag = 1.00},
	.Sand     = {accel = 0.80, grip = 0.40, drag = 1.30},
	.Grass    = {accel = 0.85, grip = 0.60, drag = 1.20},
}
