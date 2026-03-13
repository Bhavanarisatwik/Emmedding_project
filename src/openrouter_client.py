import os
import time
import requests
from dotenv import load_dotenv

load_dotenv()

_BASE_URL = "https://opencode.ai/zen/go/v1/chat/completions"
_DEFAULT_MODEL = os.getenv("CHAT_MODEL", "kimi-k2.5")


def chat(system_prompt: str, user_message: str, model: str = None) -> str:
    api_key = os.getenv("OPENCODE_API_KEY", "").strip()
    if not api_key:
        raise ValueError("OPENCODE_API_KEY is not set in environment")

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    }
    combined = f"{system_prompt}\n\n{user_message}" if system_prompt else user_message
    payload = {
        "model": model or _DEFAULT_MODEL,
        "messages": [
            {"role": "user", "content": combined},
        ],
    }
    for attempt in range(3):
        response = requests.post(_BASE_URL, headers=headers, json=payload, timeout=60)
        if response.status_code == 429:
            retry_after = response.headers.get("Retry-After")
            wait = int(retry_after) if retry_after else 5 * (attempt + 1)
            time.sleep(wait)
            continue
        response.raise_for_status()
        return response.json()["choices"][0]["message"]["content"]
    response.raise_for_status()
