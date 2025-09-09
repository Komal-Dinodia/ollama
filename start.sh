#!/usr/bin/env bash
set -euo pipefail

OLLAMA_HOST=${OLLAMA_HOST:-127.0.0.1}
OLLAMA_PORT=${OLLAMA_PORT:-11434}
OLLAMA_CMD=${OLLAMA_CMD:-/usr/local/bin/ollama}
MODEL_ID=${MODEL_ID:-"llama3:8b"}   # default to small test model - change to 70b when ready
OLLAMA_TIMEOUT=${OLLAMA_TIMEOUT:-300}

echo "Starting Ollama server (background) using ${OLLAMA_CMD} ..."

# start Ollama server (bind to localhost only)
# Note: Ollama CLI may offer `serve` or `daemon` depending on version. Using `serve` here.
# If your Ollama version requires a different command, override OLLAMA_CMD env var in Runpod.
$OLLAMA_CMD serve --host ${OLLAMA_HOST} --port ${OLLAMA_PORT} &

OLLAMA_PID=$!

# Wait for health endpoint (give up after 300s)
echo "Waiting for Ollama to become healthy..."
for i in $(seq 1 300); do
  if curl -s "http://${OLLAMA_HOST}:${OLLAMA_PORT}/health" >/dev/null 2>&1; then
    echo "Ollama is healthy."
    break
  fi
  sleep 1
  if [ $i -eq 300 ]; then
    echo "Timeout waiting for Ollama to become healthy." >&2
    # Dump a little debug info
    ps aux || true
    echo "=== /usr/local/bin listing ==="
    ls -la /usr/local/bin || true
    exit 1
  fi
done

# Optional: warm model into VRAM (quick 1-token gen). If model not present locally, Ollama may download on first run.
echo "Optional: warming model ${MODEL_ID} (this may trigger a model download if not present)..."
curl -s -X POST "http://${OLLAMA_HOST}:${OLLAMA_PORT}/api/generate" \
  -H "Content-Type: application/json" \
  -d "{\"model\":\"${MODEL_ID}\",\"prompt\":\" \",\"max_tokens\":1}" \
  --max-time 60 || echo "warm call failed or timed out - continuing"

# Execute handler in foreground (replace shell process)
exec python3 /app/handler.py
