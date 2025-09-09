# Dockerfile - robust Ollama install + Runpod handler environment
FROM nvidia/cuda:11.8.0-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV OLLAMA_PORT=11434
ENV OLLAMA_HOST=127.0.0.1
ENV OLLAMA_BIN=/usr/local/bin/ollama

# -----------------------
# System deps
# -----------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    python3 \
    python3-pip \
    git \
    jq \
    wget \
    unzip \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# -----------------------
# Try install Ollama (official script), fallback to GitHub release if needed
# -----------------------
# 1) Try official installer
RUN set -eux; \
    if curl -fsSL https://ollama.com/install.sh | sh; then \
        echo "install.sh succeeded"; \
    else \
        echo "install.sh failed - proceed to fallback"; \
    fi; \
    # if binary not present, try direct download from GitHub releases
    if [ ! -x "${OLLAMA_BIN}" ]; then \
        echo "ollama not found after install.sh — attempting direct download"; \
        curl -L -o "${OLLAMA_BIN}" "https://github.com/ollama/ollama/releases/latest/download/ollama-linux-amd64" || true; \
        chmod +x "${OLLAMA_BIN}" || true; \
    fi; \
    # final check: install not found -> error out (so build fails fast)
    if [ ! -x "${OLLAMA_BIN}" ]; then \
        echo "ERROR: Ollama binary not found or not executable. Build should be fixed." >&2; \
        ls -la /usr/local/bin || true; \
        exit 1; \
    fi; \
    # verify version (best-effort)
    ${OLLAMA_BIN} --version || true

# -----------------------
# App code & Python deps
# -----------------------
WORKDIR /app
COPY requirements.txt /app/requirements.txt
RUN pip3 install --no-cache-dir -r /app/requirements.txt

COPY start.sh /app/start.sh
COPY handler.py /app/handler.py
RUN chmod +x /app/start.sh

# NOTE: Do not expose ports; Runpod Serverless handles external routing.
# The container will run start.sh which starts Ollama bound to localhost and then the handler.
CMD ["/app/start.sh"]
