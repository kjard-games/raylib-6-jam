#!/usr/bin/env bash
set -eu

OUT_DIR="build/desktop"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$SCRIPT_DIR/src"
BOX3D_DIR="$SCRIPT_DIR/extern/box3d"
RAYLIB_DIR="$SCRIPT_DIR/extern/raylib"

mkdir -p "$OUT_DIR"

OS=$(uname -s)
ARCH=$(uname -m)

if [ "$OS" = "Darwin" ]; then
    RAYLIB_VENDOR_SUBDIR="macos"
    BRIDGE_CC="clang"
elif [ "$OS" = "Linux" ]; then
    if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
        RAYLIB_VENDOR_SUBDIR="linux-arm64"
    else
        RAYLIB_VENDOR_SUBDIR="linux"
    fi
    BRIDGE_CC="gcc"
else
    echo "Unsupported OS: $OS"
    exit 1
fi

# Build Box3D library
mkdir -p "$SCRIPT_DIR/build/box3d"
cd "$SCRIPT_DIR/build/box3d"
cmake "$BOX3D_DIR" -DBOX3D_SAMPLES=OFF -DBOX3D_UNIT_TESTS=OFF -DBOX3D_BENCHMARKS=OFF -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release --parallel
cd "$SCRIPT_DIR"

# Build Raylib 6 for desktop
if [ ! -f "$SCRIPT_DIR/build/raylib_desktop/raylib/libraylib.a" ]; then
    mkdir -p "$SCRIPT_DIR/build/raylib_desktop"
    cd "$SCRIPT_DIR/build/raylib_desktop"
    cmake "$RAYLIB_DIR" \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_EXAMPLES=OFF \
        -DBUILD_GAMES=OFF \
        -DUSE_EXTERNAL_GLFW=OFF \
        -DPLATFORM=Desktop
    cmake --build . --config Release --parallel
    cd "$SCRIPT_DIR"
fi

# Compile Box3D bridge
"$BRIDGE_CC" -c "$SRC_DIR/box3d/bridge.c" -I"$BOX3D_DIR/include" -O2 -o "$OUT_DIR/box3d_bridge.o"

# Copy Box3D library to package directory (for Odin foreign import)
cp "$SCRIPT_DIR/build/box3d/src/libbox3d.a" "$SRC_DIR/box3d/"

# The Odin install's vendor:raylib currently ships a Raylib 5.5 library.
# We build Raylib 6 from extern/raylib and use a local ODIN_ROOT so we can
# swap in the Raylib 6 static library without modifying the system Odin install.
ODIN_REAL_ROOT=$(odin root)
ODIN_FAKE_ROOT="$SCRIPT_DIR/build/odin_root"

if [ ! -d "$ODIN_FAKE_ROOT/vendor/raylib" ]; then
    rm -rf "$ODIN_FAKE_ROOT"
    mkdir -p "$ODIN_FAKE_ROOT/vendor"

    ln -sfn "$ODIN_REAL_ROOT/base" "$ODIN_FAKE_ROOT/base"
    ln -sfn "$ODIN_REAL_ROOT/core" "$ODIN_FAKE_ROOT/core"

    for entry in "$ODIN_REAL_ROOT/vendor"/*; do
        name=$(basename "$entry")
        if [ "$name" = "raylib" ]; then
            cp -R "$entry" "$ODIN_FAKE_ROOT/vendor/raylib"
        else
            ln -sfn "$entry" "$ODIN_FAKE_ROOT/vendor/$name"
        fi
    done
fi

rm -f "$ODIN_FAKE_ROOT/vendor/raylib/$RAYLIB_VENDOR_SUBDIR/libraylib.a"
cp "$SCRIPT_DIR/build/raylib_desktop/raylib/libraylib.a" "$ODIN_FAKE_ROOT/vendor/raylib/$RAYLIB_VENDOR_SUBDIR/libraylib.a"

# Build game using the local ODIN_ROOT with Raylib 6
ODIN_ROOT="$ODIN_FAKE_ROOT" odin build "$SRC_DIR" -out:"$OUT_DIR/game" -o:speed \
    -extra-linker-flags:"$OUT_DIR/box3d_bridge.o $SCRIPT_DIR/build/box3d/src/libbox3d.a"

echo "Desktop build created in ${OUT_DIR}/game"
