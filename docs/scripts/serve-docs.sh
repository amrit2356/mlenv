#!/usr/bin/env bash
# Serve documentation locally

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_DIR="$(dirname "$SCRIPT_DIR")"

PORT="${1:-8000}"

echo "=== MLEnv Documentation Server ==="
echo
echo "Serving documentation at: http://localhost:$PORT"
echo "Press Ctrl+C to stop"
echo

cd "$DOCS_DIR"

# Try Jekyll first (best for GitHub Pages preview)
if command -v jekyll >/dev/null 2>&1; then
    echo "Using Jekyll (GitHub Pages compatible)"
    jekyll serve --port "$PORT" --livereload
elif command -v python3 >/dev/null 2>&1; then
    echo "Using Python HTTP server"
    python3 -m http.server "$PORT"
elif command -v python >/dev/null 2>&1; then
    echo "Using Python HTTP server"
    python -m SimpleHTTPServer "$PORT"
else
    echo "✖ No server available. Install Jekyll or Python."
    exit 1
fi
