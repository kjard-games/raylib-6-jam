package main

import rl "vendor:raylib"

CHASE_OFFSET :: rl.Vector3{0, 3, -7}
CHASE_LOOK_AHEAD :: 4.0

update_camera :: proc() {
	broom := get_broom_position()
	fwd := get_broom_forward()

	target_pos := broom + fwd * CHASE_LOOK_AHEAD
	target_pos.y = broom.y + 1.0

	cam_pos := broom + rl.Vector3{0, CHASE_OFFSET.y, 0} - fwd * abs(CHASE_OFFSET.z)
	cam_pos.y = broom.y + CHASE_OFFSET.y

	state.camera.position = cam_pos
	state.camera.target = target_pos
	state.camera.up = {0, 1, 0}
}
