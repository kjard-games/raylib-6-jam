package main

Surface :: enum i32 {
	Dirt,
	Pavement,
	Sand,
	Grass,
}

SurfaceProfile :: struct {
	max_speed: f32,
	accel:     f32,
	grip:      f32,
	drag:      f32,
}

surface_profiles := [Surface]SurfaceProfile{
	.Dirt     = {max_speed = 0.85, accel = 0.90, grip = 0.70, drag = 1.10},
	.Pavement = {max_speed = 1.00, accel = 1.00, grip = 1.00, drag = 1.00},
	.Sand     = {max_speed = 0.75, accel = 0.80, grip = 0.40, drag = 1.30},
	.Grass    = {max_speed = 0.80, accel = 0.85, grip = 0.60, drag = 1.20},
}
