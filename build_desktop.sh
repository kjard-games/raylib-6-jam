#!/usr/bin/env bash
set -eu

OUT_DIR="build/desktop"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$SCRIPT_DIR/src"
BOX3D_DIR="$SCRIPT_DIR/extern/box3d"

mkdir -p "$OUT_DIR"

OS=$(uname -s)
ARCH=$(uname -m)

if [ "$OS" = "Darwin" ]; then
    BRIDGE_CC="clang"
    EXTRA_LIBS=""
elif [ "$OS" = "Linux" ]; then
    BRIDGE_CC="gcc"
    EXTRA_LIBS="-lX11 -ldl -lpthread -lm"
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

# Compile Box3D bridge
"$BRIDGE_CC" -c "$SRC_DIR/box3d/bridge.c" -I"$BOX3D_DIR/include" -O2 -o "$OUT_DIR/box3d_bridge.o"

# Copy Box3D library to package directory (for Odin foreign import)
cp "$SCRIPT_DIR/build/box3d/src/libbox3d.a" "$SRC_DIR/box3d/"

# Build game. Odin dev-2026-07+ ships vendor:raylib 6.0.
odin build "$SRC_DIR" -out:"$OUT_DIR/game" -o:speed \
    -extra-linker-flags:"$OUT_DIR/box3d_bridge.o $SCRIPT_DIR/build/box3d/src/libbox3d.a $EXTRA_LIBS"

echo "Desktop build created in ${OUT_DIR}/game"
