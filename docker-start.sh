#!/bin/bash
set -e

REPO_DIR="/app/mrch"
PORT="${PORT:-4747}"

echo "==> Cloning latest MRCH..."
if [ -d "$REPO_DIR/.git" ]; then
  git -C "$REPO_DIR" fetch --depth=1 origin HEAD
  git -C "$REPO_DIR" reset --hard FETCH_HEAD
else
  git clone --depth=1 "https://${GITHUB_TOKEN}@github.com/${MRCH_REPO}.git" "$REPO_DIR"
fi

echo "==> Starting GitNexus server on port $PORT..."
node /app/dist/cli/index.js serve --host 0.0.0.0 --port "$PORT" &
SERVER_PID=$!

echo "==> Re-indexing MRCH in background..."
node /app/dist/cli/index.js analyze "$REPO_DIR" && echo "==> Index complete." &

# Wait for server process — if it dies, exit so Railway restarts
wait $SERVER_PID
