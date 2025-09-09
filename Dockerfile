# Pick an image with CUDA that matches Runpod worker GPUs; adjust CUDA version as needed.
FROM nvidia/cuda:11.8.0-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

# Basic deps
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    python3 \
    python3-pip \
    git \
    wget \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Ollama (replace with official install command from Ollama if it changes)
# NOTE: verify latest install method from official Ollama docs.
RUN curl -fsSL https://ollama.com/download/ollama-linux-amd64.tgz | tar -xvz -C /usr/local/bin

# Ensure CLI is executable
RUN /usr/local/bin/ollama --version || true

# Optionally pre-pull the model (bakes model into image).
# WARNING: this drastically increases image size and build time.
# Uncomment if you have permission and want the image to include the model binary files:
# RUN ollama pull llama3:70b   # <-- replace with exact Ollama model tag you will use

# Python deps for handler
COPY requirements.txt /tmp/requirements.txt
RUN pip3 install -r /tmp/requirements.txt

# Copy start script and handler
WORKDIR /app
COPY start.sh /app/start.sh
COPY handler.py /app/handler.py
RUN chmod +x /app/start.sh

# Expose (no public port needed — we call via Runpod handler)
CMD [ "/app/start.sh" ]
