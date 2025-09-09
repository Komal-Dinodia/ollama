#!/usr/bin/env bash
set -euo pipefail

# Configurable env vars (can be overridden in Runpod)
OLLAMA_HOST=${OLLAMA_HOST:-127.0.0.1}
OLLAMA_PORT=${OLLAMA_PORT:-11434}
OLLAMA_CMD=${OLLAMA_CMD:-/usr/local/bin/ollama}  # explicitly use installed path

echo "Starting Ollama server (background)..."

# Start Ollama server bound to localhost
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

# Optional: Warm model into VRAM (if min_workers=1, helps avoid cold latency)
MODEL_ID=${MODEL_ID:-"llama3:8b"}   # suggest testing with smaller model first
echo "Warming model (optional). Model id: ${MODEL_ID}"
curl -s -X POST "http://${OLLAMA_HOST}:${OLLAMA_PORT}/api/generate" \
    -H "Content-Type: application/json" \
    -d "{\"model\":\"${MODEL_ID}\",\"prompt\":\"Hello\",\"stream\":false}" || true

# Start Runpod handler (keeps main process in foreground)
exec python3 /app/handler.py
