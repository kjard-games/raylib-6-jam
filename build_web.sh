#!/usr/bin/env bash
set -eu

OUT_DIR="build/web"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$SCRIPT_DIR/src"
BOX3D_DIR="$SCRIPT_DIR/extern/box3d"
RAYLIB_WASM_LIB="$(odin root)/vendor/raylib/wasm/libraylib.web.a"

mkdir -p "$OUT_DIR"

export EMSDK_QUIET=1

# Build Box3D for wasm
mkdir -p "$SCRIPT_DIR/build/box3d_wasm"
cd "$SCRIPT_DIR/build/box3d_wasm"
emcmake cmake "$BOX3D_DIR" -DBOX3D_SAMPLES=OFF -DBOX3D_UNIT_TESTS=OFF -DBOX3D_BENCHMARKS=OFF -DBOX3D_DISABLE_SIMD=ON
emmake cmake --build . --config Release --parallel --target box3d
cd "$SCRIPT_DIR"

# Build Odin code for wasm
odin build "$SRC_DIR/main_web" -target:js_wasm32 -build-mode:obj -define:RAYLIB_WASM_LIB=env.o -out:"$OUT_DIR/game" -o:speed

ODIN_PATH=$(odin root)
cp "$ODIN_PATH/core/sys/wasm/js/odin.js" "$OUT_DIR"

files=(
    "$OUT_DIR/game.obj"
    "$SCRIPT_DIR/build/box3d_wasm/src/libbox3d.a"
    "$RAYLIB_WASM_LIB"
)

flags=(
    -sEXPORTED_RUNTIME_METHODS=['HEAPF32']
    -sUSE_GLFW=3
    -sWASM_BIGINT
    -sWARN_ON_UNDEFINED_SYMBOLS=0
    -sASSERTIONS
    -sINITIAL_HEAP=33554432
    -sSTACK_SIZE=1048576
    --shell-file "$SRC_DIR/main_web/index_template.html"
    --preload-file assets
)

emcc -o "$OUT_DIR/index.html" "${files[@]}" "${flags[@]}"

rm -f "$OUT_DIR/game.obj"

echo "Web build created in ${OUT_DIR}"
