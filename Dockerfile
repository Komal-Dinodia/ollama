FROM nvidia/cuda:11.8.0-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
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
# -----------------------
RUN curl -fsSL https://ollama.com/install.sh | sh
ENV PATH="/root/.ollama/bin:${PATH}"

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
# Optional: Pre-pull a quantized model
# -----------------------
# RUN ollama pull llama3:8b   # (test with smaller model first)
# RUN ollama pull llama3:70b-q4_K_M   # (quantized)

# -----------------------
# Entrypoint
# -----------------------
CMD ["/app/start.sh"]
