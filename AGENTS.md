# AGENTS.md - Agent Coding Guidelines

This document provides guidelines for agentic coding agents operating in this repository.

## Project Overview

This is a Flask-based multimodal embedding pipeline using Gemini Embeddings 2, Pinecone vector database, and OpenRouter LLM. It supports text, image, and video embeddings with RAG capabilities.

## Technology Stack

- **Python**: 3.10+ (uses `str | None` union syntax)
- **Web Framework**: Flask 3.0+ with Flask-CORS
- **Embedding**: Google Gemini Embeddings 2 (via `google-genai`)
- **Vector DB**: Pinecone
- **LLM**: OpenRouter (via `requests`)
- **CLI**: argparse-based command interface

## Build, Lint, and Test Commands

### Installation

```bash
pip install -r requirements.txt
```

### Running the Application

```bash
# Development server
python app.py

# Or with Flask CLI
flask run --debug
```

### Running Tests

This project does not currently have a test suite. To add tests:

```bash
# Install pytest
pip install pytest pytest-cov

# Run all tests
pytest

# Run a single test file
pytest tests/test_embedder.py

# Run a single test function
pytest tests/test_embedder.py::test_embed_text

# Run with verbose output
pytest -v

# Run with coverage
pytest --cov=src --cov-report=html
```

### Linting

No formal linting is configured. To add linting:

```bash
# Install ruff (recommended - fast Python linter)
pip install ruff
ruff check .

# Fix auto-fixable issues
ruff check --fix .

# Install pylint
pip install pylint
pylint src/
```

### Type Checking

```bash
# Install mypy
pip install mypy
mypy src/
```

## Code Style Guidelines

### Imports

Follow this order (separated by blank lines):

1. Standard library (`import os`, `import pathlib`, `from datetime import datetime`)
2. Third-party packages (`from flask import ...`, `from dotenv import load_dotenv`)
3. Local application imports (`from src import embedder`, `from src.pipeline import ...`)

```python
# Correct
import os
from pathlib import Path

from dotenv import load_dotenv
from flask import Flask, jsonify

from src import embedder
from src.pipeline import ingest_text
```

```python
# Wrong - mixed order
from src import embedder
import os
from flask import Flask
```

### Formatting

- **Indentation**: 4 spaces (no tabs)
- **Line length**: Target under 100 characters, max 120
- **Blank lines**: Two between top-level definitions, one between function definitions
- **Trailing commas**: Use trailing commas for multi-line collections and function calls

```python
# Good
config = types.EmbedContentConfig(
    task_type=task_type,
    output_dimensionality=_DIMENSIONS,
)

response = client.models.embed_content(
    model=_GEMINI_MODEL,
    contents=contents,
    config=config,
)
```

### Type Hints

Use Python 3.10+ union syntax (`str | None`) instead of `Optional[str]`:

```python
# Good
def embed_text(text: str, task_type: str = "RETRIEVAL_DOCUMENT") -> list[float]:
    ...

def _get_client() -> genai.Client:
    api_key = os.getenv("GEMINI_API_KEY", "").strip()
    if not api_key:
        raise ValueError("GEMINI_API_KEY is not set in environment")
    return genai.Client(api_key=api_key)

# Good - using | for union types
def _make_thumbnail_b64(path: Path, max_px: int = 400) -> str | None:
```

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Constants | UPPER_SNAKE_CASE | `_GEMINI_MODEL`, `_DIMENSIONS` |
| Module-level private | Leading underscore | `_get_client()`, `_extract_pdf()` |
| Functions | snake_case | `embed_text()`, `ingest_image()` |
| Variables | snake_case | `api_key`, `file_path` |
| Classes | PascalCase | `PdfReader`, `Document` |
| Type aliases | PascalCase | Not heavily used in this project |

### Error Handling

- Use specific exception types when possible
- Provide clear error messages
- Use `ValueError` for validation failures
- Log errors with traceback for debugging

```python
# Good - validation with ValueError
api_key = os.getenv("GEMINI_API_KEY", "").strip()
if not api_key:
    raise ValueError("GEMINI_API_KEY is not set in environment")

# Good - try/except with error handling
try:
    response = requests.post(url, headers=headers, json=payload, timeout=60)
    response.raise_for_status()
except requests.RequestException as e:
    logger.error(f"Request failed: {e}")
    raise

# Good - exception handling in Flask routes
except Exception as e:
    import traceback
    traceback.print_exc()
    return jsonify({"error": str(e)}), 500
```

### Function Design

- Keep functions under 50 lines when possible
- Use early returns for guard clauses
- Use helper functions for complex logic (prefix with `_`)
- Functions should have clear, single responsibilities

### Constants

- Group related constants at module level
- Use descriptive names with underscore prefix for module-private constants
- Use all caps for public constants (rarely needed)

```python
# Good - grouped constants with underscore prefix
_IMAGE_EXTS = {".jpg", ".jpeg", ".png", ".gif", ".webp"}
_VIDEO_EXTS = {".mp4", ".mov", ".webm", ".avi", ".mkv"}
_TEXT_EXTS = {".txt", ".md", ".csv", ".json", ".html"}
```

### Environment Variables

- Always use `os.getenv()` with a default value or `.strip()` for trimming
- Validate required environment variables at module load or function call time
- Use `load_dotenv()` at module level (usually at the top)

```python
# Good
load_dotenv()
_DIMENSIONS = int(os.getenv("EMBEDDING_DIMENSIONS", "1536").strip())
```

### File Structure

```
.
├── app.py              # Flask application entry point
├── main.py            # CLI entry point (argparse)
├── src/
│   ├── __init__.py
│   ├── embedder.py    # Gemini embedding functions
│   ├── pinecone_client.py  # Pinecone vector DB operations
│   ├── openrouter_client.py  # LLM client
│   ├── pipeline.py   # Ingestion pipelines
│   └── retriever.py  # Search and RAG functions
├── templates/         # HTML templates
├── static/           # CSS, JS, images
└── data/            # Uploaded files
```

### Flask Routes

- Use clear route decorators
- Return appropriate HTTP status codes
- Use `jsonify` for JSON responses
- Handle errors consistently

```python
# Good - Flask route with proper error handling
@app.route("/api/chat", methods=["POST"])
def chat():
    data = request.get_json()
    question = (data or {}).get("message", "").strip()
    if not question:
        return jsonify({"error": "No message provided"}), 400

    try:
        # ... implementation
        return jsonify({"answer": answer, "sources": sources})
    except Exception as e:
        return jsonify({"error": str(e)}), 500
```

### Security

- Never hardcode API keys or secrets in source files
- Use `.env` files for secrets (already in `.gitignore`)
- Validate and sanitize user input
- Use `secure_filename` for file uploads
- Implement directory traversal protection

```python
# Good - directory traversal protection
@app.route("/media/<path:filename>")
def serve_media(filename):
    file_path = (_DATA_ROOT / filename).resolve()
    if not str(file_path).startswith(str(_DATA_ROOT.resolve())):
        abort(403)
```

### Adding New Features

1. **New dependencies**: Add to `requirements.txt`
2. **New endpoints**: Add to `app.py` or create new module under `src/`
3. **New CLI commands**: Add to `main.py`
4. **Configuration**: Use environment variables, add defaults in code
