import mimetypes
import os
from pathlib import Path

from dotenv import load_dotenv
from google import genai
from google.genai import types

load_dotenv()

_GEMINI_MODEL = "gemini-embedding-2-preview"
_DIMENSIONS = int(os.getenv("EMBEDDING_DIMENSIONS", "1536").strip())


def _get_client() -> genai.Client:
    api_key = os.getenv("GEMINI_API_KEY", "").strip()
    if not api_key:
        raise ValueError("GEMINI_API_KEY is not set in environment")
    return genai.Client(api_key=api_key)


def _embed(contents: list, task_type: str | None) -> list[float]:
    client = _get_client()
    # task_type is only valid for text-only embeddings; omit it for image/video
    config = (
        types.EmbedContentConfig(task_type=task_type, output_dimensionality=_DIMENSIONS)
        if task_type
        else types.EmbedContentConfig(output_dimensionality=_DIMENSIONS)
    )
    response = client.models.embed_content(
        model=_GEMINI_MODEL,
        contents=contents,
        config=config,
    )
    return response.embeddings[0].values


def embed_text(text: str, task_type: str = "RETRIEVAL_DOCUMENT") -> list[float]:
    contents = [types.Content(parts=[types.Part(text=text)])]
    return _embed(contents, task_type)


def embed_image(image_path: str, task_type: str | None = None) -> list[float]:
    path = Path(image_path)
    mime_type, _ = mimetypes.guess_type(str(path))
    if mime_type not in ("image/png", "image/jpeg", "image/webp", "image/gif"):
        mime_type = "image/jpeg"

    with open(path, "rb") as f:
        raw_bytes = f.read()

    contents = [types.Part.from_bytes(data=raw_bytes, mime_type=mime_type)]
    return _embed(contents, task_type)


def embed_video(video_path: str, task_type: str | None = None) -> list[float]:
    path = Path(video_path)
    mime_type, _ = mimetypes.guess_type(str(path))
    if mime_type not in ("video/mp4", "video/quicktime", "video/webm"):
        mime_type = "video/mp4"

    with open(path, "rb") as f:
        raw_bytes = f.read()

    contents = [types.Part.from_bytes(data=raw_bytes, mime_type=mime_type)]
    return _embed(contents, task_type)
