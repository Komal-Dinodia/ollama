"""
Runpod serverless handler that forwards requests to the local Ollama HTTP API.
- Keeps Ollama bound to localhost and does not expose it directly externally.
- Add authentication, rate-limiting, logging as needed.
"""

import os
import requests
import runpod
import json
from typing import Any, Dict

OLLAMA_HOST = os.environ.get("OLLAMA_HOST", "127.0.0.1")
OLLAMA_PORT = os.environ.get("OLLAMA_PORT", "11434")
OLLAMA_BASE = f"http://{OLLAMA_HOST}:{OLLAMA_PORT}"

# Model identifier to use when calling Ollama. Change to your local tag if different.
MODEL_ID = os.environ.get("MODEL_ID", "llama3:70b")

# Timeout settings for Ollama calls
OLLAMA_TIMEOUT = int(os.environ.get("OLLAMA_TIMEOUT", "300"))

def call_ollama_generate(prompt: str, max_tokens: int = 512, **kwargs) -> Dict[str, Any]:
    """
    Example call to Ollama model generate endpoint.
    NOTE: adapt path/body to match Ollama server API for your installed version.
    """
    url = f"{OLLAMA_BASE}/api/models/{MODEL_ID}/generate"
    payload = {
        "prompt": prompt,
        "max_tokens": max_tokens
    }
    # Merge additional kwargs into payload if provided
    payload.update(kwargs)
    resp = requests.post(url, json=payload, timeout=OLLAMA_TIMEOUT)
    resp.raise_for_status()
    return resp.json()

def handler(event):
    """
    event["input"] should be a dict with:
      - "prompt": string (required)
      - optional: "max_tokens", "temperature", etc. (adapted to Ollama)
    """
    body = event.get("input", {}) or {}
    prompt = body.get("prompt")
    if not prompt:
        return {"error": "prompt field is required in input"}

    max_tokens = int(body.get("max_tokens", 512))
    try:
        result = call_ollama_generate(prompt=prompt, max_tokens=max_tokens)
        # Pass through raw result or parse depending on Ollama response shape.
        return {"status": "ok", "result": result}
    except Exception as e:
        # Return error message. Optionally log full traceback to Runpod logs.
        return {"status": "error", "message": str(e)}

if __name__ == "__main__":
    # Start the runpod serverless handler
    runpod.serverless.start({"handler": handler})
