#!/bin/bash

REPO_DIR="/app/mrch"
PORT="${PORT:-4747}"

echo "==> Starting GitNexus server on port $PORT..."
node /app/dist/cli/index.js serve --host 0.0.0.0 --port "$PORT" &
SERVER_PID=$!

# Clone + analyze in background — server is already up for the healthcheck
(
  echo "==> Cloning latest MRCH..."
  if [ -d "$REPO_DIR/.git" ]; then
    git -C "$REPO_DIR" fetch --depth=1 origin HEAD && git -C "$REPO_DIR" reset --hard FETCH_HEAD
  else
    git clone --depth=1 "https://${GITHUB_TOKEN}@github.com/${MRCH_REPO}.git" "$REPO_DIR"
  fi && \
  echo "==> Indexing MRCH..." && \
  node /app/dist/cli/index.js analyze "$REPO_DIR" && \
  echo "==> Index complete."
) &

# If server dies, exit so Railway restarts the container
wait $SERVER_PID
