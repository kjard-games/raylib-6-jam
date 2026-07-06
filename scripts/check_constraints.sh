#!/usr/bin/env bash
# Enforce project constraints independent of the build script.
# Usage: check_constraints.sh [desktop|web]
set -eu

TARGET="${1:-desktop}"

fail() {
    echo "ERROR: $1" >&2
    exit 1
}

# Odin version must match what the project is pinned to.
ODIN_VERSION=$(odin version)
if [[ "$ODIN_VERSION" != *"dev-2026-07"* ]]; then
    fail "Expected Odin dev-2026-07, got: $ODIN_VERSION"
fi

# Raylib must be version 6.0 (vendor package).
RAYLIB_VERSION_FILE="$(odin root)/vendor/raylib/raylib.odin"
RAYLIB_VERSION=$(grep -E 'VERSION\s+::' "$RAYLIB_VERSION_FILE" | sed -E 's/.*"([^"]+)".*/\1/' | head -1)
if [ "$RAYLIB_VERSION" != "6.0" ]; then
    fail "Expected raylib 6.0, got: $RAYLIB_VERSION"
fi

# Screen resolution must be exactly 720x720.
if ! grep -qE '^WIDTH\s+::\s+720' src/game.odin; then
    fail "WIDTH must be 720 in src/game.odin"
fi
if ! grep -qE '^HEIGHT\s+::\s+720' src/game.odin; then
    fail "HEIGHT must be 720 in src/game.odin"
fi

# Box3D source must be present (submodule).
if [ ! -f "extern/box3d/include/box3d/box3d.h" ]; then
    fail "extern/box3d submodule is missing"
fi

if [ "$TARGET" = "web" ]; then
    # Web build must produce a wasm binary.
    if [ ! -f "build/web/index.wasm" ]; then
        fail "build/web/index.wasm is missing"
    fi
    if ! file "build/web/index.wasm" | grep -qi "wasm"; then
        fail "build/web/index.wasm is not a WebAssembly binary"
    fi

    # Total package size must be under 64 MiB.
    WASM_SIZE=$(stat -f%z "build/web/index.wasm" 2>/dev/null || stat -c%s "build/web/index.wasm")
    DATA_SIZE=0
    if [ -f "build/web/index.data" ]; then
        DATA_SIZE=$(stat -f%z "build/web/index.data" 2>/dev/null || stat -c%s "build/web/index.data")
    fi
    TOTAL=$((WASM_SIZE + DATA_SIZE))
    MAX=$((64 * 1024 * 1024))
    echo "Web package size: $TOTAL bytes (max $MAX bytes)"
    if [ "$TOTAL" -gt "$MAX" ]; then
        fail "wasm + data exceeds 64 MiB"
    fi
elif [ "$TARGET" = "desktop" ]; then
    # Desktop binary must exist and link the Box3D bridge.
    if [ ! -f "build/desktop/game" ]; then
        fail "build/desktop/game is missing"
    fi
    if ! nm "build/desktop/game" 2>/dev/null | grep -q "bw_create_world"; then
        fail "Box3D bridge symbol bw_create_world not found in binary"
    fi
else
    fail "Usage: $0 [desktop|web]"
fi

echo "All constraint checks passed for $TARGET"
