import os
from pathlib import Path

from tqdm import tqdm

from src import embedder, pinecone_client

_IMAGE_EXTS = {".jpg", ".jpeg", ".png", ".gif", ".webp"}
_VIDEO_EXTS = {".mp4", ".mov", ".webm", ".avi", ".mkv"}
_TEXT_EXTS = {".txt", ".md", ".csv", ".json", ".html"}
_PDF_EXT = ".pdf"
_DOCX_EXT = ".docx"
_SKIP_EXTS = {".pptx", ".xlsx", ".xls", ".docm"}


def _extract_pdf(path: Path) -> str:
    from pypdf import PdfReader
    reader = PdfReader(str(path))
    pages = []
    for page in reader.pages:
        text = page.extract_text()
        if text:
            pages.append(text)
    return "\n".join(pages)


def _extract_docx(path: Path) -> str:
    from docx import Document
    doc = Document(str(path))
    return "\n".join(p.text for p in doc.paragraphs if p.text.strip())


def ingest_text(text: str, id: str, metadata: dict = None):
    vector = embedder.embed_text(text)
    meta = {"type": "text", "content_preview": text[:3000], **(metadata or {})}
    pinecone_client.upsert(id, vector, meta)
    print(f"[text] ingested id={id}")


def ingest_image(image_path: str, id: str, metadata: dict = None):
    vector = embedder.embed_image(image_path)
    meta = {"type": "image", "path": Path(image_path).as_posix(), **(metadata or {})}
    pinecone_client.upsert(id, vector, meta)
    print(f"[image] ingested id={id}")


def ingest_video(video_path: str, id: str, metadata: dict = None):
    vector = embedder.embed_video(video_path)
    meta = {"type": "video", "path": Path(video_path).as_posix(), **(metadata or {})}
    pinecone_client.upsert(id, vector, meta)
    print(f"[video] ingested id={id}")


def ingest_directory(directory: str):
    root = Path(directory)
    files = [f for f in root.rglob("*") if f.is_file()]

    for file in tqdm(files, desc="Ingesting"):
        ext = file.suffix.lower()
        id = file.stem + "_" + str(abs(hash(str(file))))[:8]
        rel_path = file.relative_to(root).as_posix()  # e.g. "images/addhr.jpeg"
        metadata = {"filename": file.name, "path": file.as_posix(), "rel_path": rel_path}

        try:
            if ext in _IMAGE_EXTS:
                ingest_image(str(file), id, metadata)
            elif ext in _VIDEO_EXTS:
                ingest_video(str(file), id, metadata)
            elif ext in _TEXT_EXTS:
                content = file.read_text(errors="ignore")
                ingest_text(content, id, {**metadata, "source": "text_file"})
            elif ext == _PDF_EXT:
                content = _extract_pdf(file)
                if content.strip():
                    ingest_text(content, id, {**metadata, "source": "pdf"})
                else:
                    print(f"[skip] no extractable text in PDF: {file.name}")
            elif ext == _DOCX_EXT:
                content = _extract_docx(file)
                if content.strip():
                    ingest_text(content, id, {**metadata, "source": "docx"})
                else:
                    print(f"[skip] no extractable text in DOCX: {file.name}")
            elif ext in _SKIP_EXTS:
                print(f"[skip] unsupported extension: {file.name}")
            else:
                print(f"[skip] unknown extension: {file.name}")
        except Exception as e:
            print(f"[error] {file.name}: {e}")
