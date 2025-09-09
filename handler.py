"""
Runpod serverless handler that forwards requests to the local Ollama HTTP API.
"""

import os
import requests
import runpod
from typing import Any, Dict

OLLAMA_HOST = os.environ.get("OLLAMA_HOST", "127.0.0.1")
OLLAMA_PORT = os.environ.get("OLLAMA_PORT", "11434")
OLLAMA_BASE = f"http://{OLLAMA_HOST}:{OLLAMA_PORT}"

# Default to a small model for validation. Change MODEL_ID env var in Runpod to deploy 70B.
MODEL_ID = os.environ.get("MODEL_ID", "llama3:8b")
OLLAMA_TIMEOUT = int(os.environ.get("OLLAMA_TIMEOUT", "300"))

def call_ollama_generate(prompt: str, max_tokens: int = 256, **kwargs) -> Dict[str, Any]:
    url = f"{OLLAMA_BASE}/api/generate"
    payload = {
        "model": MODEL_ID,
        "prompt": prompt,
        "max_tokens": max_tokens
    }
    payload.update(kwargs)
    resp = requests.post(url, json=payload, timeout=OLLAMA_TIMEOUT)
    resp.raise_for_status()
    return resp.json()

def handler(event):
    """
    event["input"] expected shape:
      {"prompt": "text...", "max_tokens": 200, ...}
    """
    body = event.get("input") or {}
    prompt = body.get("prompt")
    if not prompt:
        return {"error": "prompt field is required in input"}

    max_tokens = int(body.get("max_tokens", 256))
    try:
        result = call_ollama_generate(prompt=prompt, max_tokens=max_tokens)
        return {"status": "ok", "result": result}
    except Exception as e:
        # Show helpful log-friendly message
        return {"status": "error", "message": str(e)}

if __name__ == "__main__":
    runpod.serverless.start({"handler": handler})
