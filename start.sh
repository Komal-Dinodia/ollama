#!/usr/bin/env bash
set -euo pipefail

# Start Ollama server/daemon in background.
# NOTE: Replace 'ollama serve' with the official command if different.
# Some Ollama setups use a built-in server; if not available, you may run a small wrapper.
ollama serve --host 127.0.0.1 --port 11434 &

# Wait for Ollama to be healthy (adjust health path if needed)
echo "Waiting for Ollama to start..."
for i in $(seq 1 120); do
  if curl -s http://127.0.0.1:11434/health >/dev/null 2>&1; then
    echo "Ollama is up"
    break
  fi
  sleep 1
done

# Start the Runpod handler (keeps the worker process in foreground)
python3 /app/handler.py
