package main

import rl "vendor:raylib"
import b3 "box3d"

WIDTH  :: 720
HEIGHT :: 720

BodyUser :: struct {
    id:   u64,
    size: f32,
}

State :: struct {
    world:  u32,
    bodies: [dynamic]BodyUser,
    camera: rl.Camera3D,
}

state: State

init :: proc() {
    rl.SetConfigFlags({.VSYNC_HINT})
    rl.InitWindow(WIDTH, HEIGHT, "raylib-6-jam")
    rl.InitAudioDevice()

    state.world = b3.bw_create_world(0, -10, 0)

    ground := b3.bw_create_body(state.world, 0, -2, 0, .Static)
    b3.bw_create_box_shape(ground, 15, 1, 15)

    for i in 0 ..< 10 {
        x := f32(i % 5) * 2.5 - 5.0
        z := f32(i / 5) * 2.5 - 2.5
        body := b3.bw_create_body(state.world, x, 5 + f32(i) * 0.5, z, .Dynamic)
        b3.bw_create_box_shape(body, 0.5, 0.5, 0.5)
        append(&state.bodies, BodyUser{id = body, size = 1.0})
    }

    state.camera = rl.Camera3D {
        position = {12, 8, 12},
        target   = {0, 1, 0},
        up       = {0, 1, 0},
        fovy     = 60,
        projection = .PERSPECTIVE,
    }

    rl.SetTargetFPS(60)
}

update :: proc() -> bool {
    rl.UpdateCamera(&state.camera, .ORBITAL)

    update_hand_tracking()

    b3.bw_step(state.world, 1.0 / 60.0, 4)

    rl.BeginDrawing()
    rl.ClearBackground(rl.SKYBLUE)

    rl.BeginMode3D(state.camera)
    rl.DrawGrid(20, 2)

    for b in state.bodies {
        x, y, z: f32
        b3.bw_get_body_position(b.id, &x, &y, &z)
        pos := rl.Vector3{x, y, z}
        rl.DrawCube(pos, b.size, b.size, b.size, rl.RED)
        rl.DrawCubeWires(pos, b.size, b.size, b.size, rl.MAROON)
    }

    if hand_tracking_state.num_hands > 0 {
        tip := hand_index_tip(0)
        world_pos := rl.Vector3{
            (1.0 - tip[0]) * 14.0 - 7.0,
            8.0 - tip[1] * 8.0,
            tip[2] * 4.0,
        }
        rl.DrawSphere(world_pos, 0.3, rl.GREEN)
    }

    rl.EndMode3D()

    if hand_tracking_state.num_hands > 0 {
        screen := hand_tip_screen_pos(0)
        rl.DrawCircleV(screen, 12, rl.GREEN)
        rl.DrawText("Hand tracked", 10, 30, 20, rl.DARKGREEN)
    } else {
        rl.DrawText("No hand detected", 10, 30, 20, rl.DARKGRAY)
    }

    rl.DrawFPS(10, 10)
    rl.EndDrawing()

    when ODIN_OS == .JS {
        return true
    } else {
        return !rl.WindowShouldClose()
    }
}

shutdown :: proc() {
    b3.bw_destroy_world(state.world)
    delete(state.bodies)
    rl.CloseAudioDevice()
    rl.CloseWindow()
}
