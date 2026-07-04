#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PORT="${1:-8765}"
URL="http://localhost:${PORT}/"

bash "$SCRIPT_DIR/build_web.sh"

echo ""
echo "Starting local web server for the game..."
echo "Opening $URL in Chrome."
echo "Press Ctrl+C to stop the server."
echo ""

cd "$SCRIPT_DIR/build/web"
python3 -m http.server "$PORT" >/dev/null 2>&1 &
SERVER_PID=$!

cleanup() {
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
}
trap cleanup EXIT

# Give the server a moment to start before opening the browser.
sleep 1

case "$(uname -s)" in
    Darwin)
        if command -v open >/dev/null 2>&1; then
            open -a "Google Chrome" "$URL" || open "$URL"
        fi
        ;;
    Linux)
        if command -v google-chrome >/dev/null 2>&1; then
            google-chrome "$URL" &
        elif command -v chromium >/dev/null 2>&1; then
            chromium "$URL" &
        elif command -v chromium-browser >/dev/null 2>&1; then
            chromium-browser "$URL" &
        elif command -v xdg-open >/dev/null 2>&1; then
            xdg-open "$URL" &
        else
            echo "Could not detect a browser opener. Open $URL manually."
        fi
        ;;
    CYGWIN*|MINGW*|MSYS*)
        start "$URL"
        ;;
    *)
        echo "Open $URL in your browser."
        ;;
esac

wait "$SERVER_PID"
