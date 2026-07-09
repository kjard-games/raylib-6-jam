package main

import rl "vendor:raylib"

main :: proc() {
    init()

    for !rl.WindowShouldClose() {
        if !update() { break }
    }

    shutdown()
}