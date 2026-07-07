#!/usr/bin/env bash
set -eu

OUT_DIR="build/desktop"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$SCRIPT_DIR/src"

mkdir -p "$OUT_DIR"

odin build "$SRC_DIR" -out:"$OUT_DIR/game" -o:speed

echo "Desktop build created in ${OUT_DIR}/game"
