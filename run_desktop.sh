#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

bash "$SCRIPT_DIR/build_desktop.sh"

echo "Running desktop build..."
mkdir -p "$SCRIPT_DIR/telemetry"
"$SCRIPT_DIR/build/desktop/game"
