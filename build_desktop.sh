#!/usr/bin/env bash
set -eu

OUT_DIR="build/desktop"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$SCRIPT_DIR/src"

mkdir -p "$OUT_DIR"

clang -c "$SRC_DIR/b3_assert.c" -o "$OUT_DIR/b3_assert.o"

odin build "$SRC_DIR" -out:"$OUT_DIR/game" -o:speed -extra-linker-flags:"$OUT_DIR/b3_assert.o"

echo "Desktop build created in ${OUT_DIR}/game"
