package main

import rl "vendor:raylib"

MAX_HANDS          :: 2
LANDMARKS_PER_HAND :: 21
INDEX_FINGER_TIP   :: 8

Hand :: struct {
    landmarks: [LANDMARKS_PER_HAND]rl.Vector3,
}

HandTrackingState :: struct {
    hands:     [MAX_HANDS]Hand,
    num_hands: i32,
}

hand_tracking_state: HandTrackingState

when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32 {
    foreign import game_bridge "game_bridge"

    @(default_calling_convention="c")
    foreign game_bridge {
        get_hand_landmarks :: proc(buffer: [^]f32, max_hands: i32) -> i32 ---
    }
}

update_hand_tracking :: proc() {
    when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32 {
        buffer: [MAX_HANDS * LANDMARKS_PER_HAND * 3]f32
        hand_tracking_state.num_hands = get_hand_landmarks(&buffer[0], MAX_HANDS)

        for h in 0 ..< hand_tracking_state.num_hands {
            for i in 0 ..< LANDMARKS_PER_HAND {
                idx := (int(h) * LANDMARKS_PER_HAND + i) * 3
                hand_tracking_state.hands[h].landmarks[i] = rl.Vector3{
                    buffer[idx + 0],
                    buffer[idx + 1],
                    buffer[idx + 2],
                }
            }
        }
    } else {
        hand_tracking_state.num_hands = 0
    }
}

hand_index_tip :: proc(hand_index: i32) -> rl.Vector3 {
    if hand_index < 0 || hand_index >= hand_tracking_state.num_hands {
        return rl.Vector3{0, 0, 0}
    }
    return hand_tracking_state.hands[hand_index].landmarks[INDEX_FINGER_TIP]
}

// MediaPipe returns normalized coordinates (0..1, origin top-left).
// This maps the index fingertip into a 720x720 screen rectangle.
hand_tip_screen_pos :: proc(hand_index: i32) -> rl.Vector2 {
    tip := hand_index_tip(hand_index)
    return rl.Vector2{
        (1.0 - tip[0]) * WIDTH,
        tip[1] * HEIGHT,
    }
}
