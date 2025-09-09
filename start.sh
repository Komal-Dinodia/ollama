#!/usr/bin/env bash
set -euo pipefail

# Configurable env vars (can be overridden in Runpod)
OLLAMA_HOST=${OLLAMA_HOST:-127.0.0.1}
OLLAMA_PORT=${OLLAMA_PORT:-11434}
OLLAMA_CMD=${OLLAMA_CMD:-ollama}

echo "Starting Ollama server (background)..."

# Start Ollama server/daemon bound to localhost.
# NOTE: Confirm correct Ollama command for running a local HTTP server in your Ollama version.
# Some variants: `ollama serve` or `ollama daemon` - check Ollama docs.
# This example uses a generic `ollama serve`.
$OLLAMA_CMD serve --host ${OLLAMA_HOST} --port ${OLLAMA_PORT} &

OLLAMA_PID=$!

# Wait for Ollama health endpoint to respond (max wait ~300s)
echo "Waiting for Ollama to become healthy..."
for i in $(seq 1 300); do
  if curl -s "http://${OLLAMA_HOST}:${OLLAMA_PORT}/health" >/dev/null 2>&1; then
    echo "Ollama is healthy."
    break
  fi
  sleep 1
  if [ $i -eq 300 ]; then
    echo "Timeout waiting for Ollama to become healthy." >&2
    exit 1
  fi
done

# If you want to ensure a model is loaded eagerly when the container starts (helpful if min_workers=1),
# you can call an endpoint to load or run a no-op generation. That forces the model into VRAM.
# Example: small request to warm model. Replace MODEL_ID with your model tag.
MODEL_ID=${MODEL_ID:-"llama3:70b"}   # change if you use a different tag
echo "Warming model (optional). Model id: ${MODEL_ID}"
# THIS requires your Ollama server to accept a generate request; adjust path/payload per Ollama API.
# Try to warm but ignore errors so server still continues.
curl -s -X POST "http://${OLLAMA_HOST}:${OLLAMA_PORT}/api/models/${MODEL_ID}/generate" \
    -H "Content-Type: application/json" \
    -d '{"prompt":" ","max_tokens":1}' || true

# Start Runpod handler (keeps main process in foreground)
python3 /app/handler.py
