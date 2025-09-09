# Base image with CUDA runtime suitable for GPUs on Runpod.
# Adjust CUDA version if Runpod uses a different CUDA runtime for chosen GPU.
FROM nvidia/cuda:11.8.0-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV OLLAMA_BIN=/usr/local/bin/ollama
ENV OLLAMA_PORT=11434
ENV OLLAMA_HOST=127.0.0.1

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
    && rm -rf /var/lib/apt/lists/*

# -----------------------
# Install Ollama CLI/binary
# NOTE: verify latest official install instructions from Ollama.
# This is a common pattern: download a tarball, extract the executable.
# -----------------------
RUN curl -fsSL https://ollama.com/download/ollama-linux-amd64.tgz -o /tmp/ollama.tgz \
    && tar -xvzf /tmp/ollama.tgz -C /usr/local/bin \
    && rm /tmp/ollama.tgz || true

# Ensure ollama is executable
RUN if [ -f "$OLLAMA_BIN" ]; then $OLLAMA_BIN --version || true; fi

# -----------------------
# App code & Python deps
# -----------------------
WORKDIR /app
COPY requirements.txt /app/requirements.txt
RUN pip3 install --no-cache-dir -r /app/requirements.txt

COPY start.sh /app/start.sh
COPY handler.py /app/handler.py
RUN chmod +x /app/start.sh

# -----------------------
# Optional: Pre-pull or pre-load a quantized model
# You may uncomment and adapt one of these blocks if you'd like to bake model files
# into the docker image. WARNING: This will greatly increase image size and build time.
#
# Option A: ollama pull by tag (if Ollama registry supports the tag)
# RUN ollama pull <my-ollama-tag>
#
# Option B: download a quantized GGUF (hosted URL) and place into Ollama models directory
# ENV QUANT_GGUF_URL="https://my-bucket/path/llama3-70b-q4.gguf"
# RUN mkdir -p /root/.ollama/models/llama3-70b-q4 \
#     && curl -L "$QUANT_GGUF_URL" -o /root/.ollama/models/llama3-70b-q4/model.gguf
#
# If you want pre-pull, uncomment and set appropriate values before building.

# Expose none publicly — Runpod Serverless uses its own endpoint. Ollama will bind to localhost.
CMD ["/app/start.sh"]
