package box3d

when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32 {
    foreign import lib "box3d_bridge.wasm.o"
} else {
    foreign import lib "libbox3d.a"
}

BodyType :: enum i32 {
    Static    = 0,
    Kinematic = 1,
    Dynamic   = 2,
}

@(default_calling_convention="c")
foreign lib {
    bw_create_world      :: proc(gx, gy, gz: f32) -> u32 ---
    bw_destroy_world     :: proc(world: u32) ---
    bw_step              :: proc(world: u32, time_step: f32, sub_step_count: i32) ---
    bw_create_body       :: proc(world: u32, x, y, z: f32, type: BodyType) -> u64 ---
    bw_destroy_body      :: proc(body: u64) ---
    bw_get_body_position :: proc(body: u64, x, y, z: ^f32) ---
    bw_create_box_shape  :: proc(body: u64, hx, hy, hz: f32) -> u64 ---
}
