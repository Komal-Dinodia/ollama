import runpod
import requests
import os
import json

OLLAMA_BASE = os.environ.get("OLLAMA_BASE", "http://127.0.0.1:11434")

def _call_ollama(prompt, model="llama3:70b", timeout=120):
    """
    Example: POST to Ollama endpoint. Exact path/payload depends on Ollama server API.
    Check Ollama docs for the exact REST shape and adapt here.
    """
    url = f"{OLLAMA_BASE}/api/models/{model}/generate"  # <-- placeholder path
    payload = {"prompt": prompt, "max_tokens": 512}
    # Adjust headers if Ollama server requires them
    resp = requests.post(url, json=payload, timeout=timeout)
    resp.raise_for_status()
    return resp.json()

def handler(event):
    """
    Runpod calls this for each request.
    event["input"] should contain {"prompt": "text..."} or other params.
    """
    body = event.get("input", {})
    prompt = body.get("prompt", "")
    if not prompt:
        return {"error": "missing prompt"}

    try:
        result = _call_ollama(prompt, model="llama3:70b")
        # Adapt parsing depending on Ollama response format
        return {"status": "ok", "result": result}
    except Exception as e:
        return {"status": "error", "message": str(e)}

# Start runpod handler
if __name__ == "__main__":
    runpod.serverless.start({"handler": handler})
