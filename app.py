import base64
import io
import os
import secrets as _secrets
from datetime import datetime, timedelta, timezone
from pathlib import Path
from flask import (
    Flask,
    request,
    jsonify,
    render_template,
    send_file,
    abort,
    session,
    redirect,
    url_for,
)
from flask_cors import CORS
from dotenv import load_dotenv
from werkzeug.utils import secure_filename

load_dotenv()

app = Flask(__name__)
CORS(app)

# ── Auth ─────────────────────────────────────────────────────────────────────
APP_PASSWORD = "Mygoalisbe@0265"  # change this and redeploy to update
app.secret_key = os.getenv("SECRET_KEY", "change-me-in-prod")
_SESSION_MAX_AGE = timedelta(hours=8)


@app.before_request
def require_login():
    public_paths = {"/login", "/favicon.ico"}
    # Add API paths as public (no auth required)
    if request.path.startswith("/api/"):
        return
    if request.path in public_paths or request.path.startswith("/static"):
        return
    if not session.get("authenticated"):
        return redirect(url_for("login"))
    login_time = session.get("login_time")
    if not login_time:
        session.clear()
        return redirect(url_for("login"))
    try:
        elapsed = datetime.now(timezone.utc) - datetime.fromisoformat(login_time)
    except (ValueError, TypeError):
        session.clear()
        return redirect(url_for("login"))
    if elapsed > _SESSION_MAX_AGE:
        session.clear()
        return redirect(url_for("login"))


@app.route("/login", methods=["GET", "POST"])
def login():
    error = None
    if request.method == "POST":
        pw = request.form.get("password", "")
        if _secrets.compare_digest(pw, APP_PASSWORD):
            session.clear()
            session["authenticated"] = True
            session["login_time"] = datetime.now(timezone.utc).isoformat()
            return redirect(url_for("index"))
        error = "Incorrect password."
    return render_template("login.html", error=error)


@app.route("/logout")
def logout():
    session.clear()
    return redirect(url_for("login"))


# ─────────────────────────────────────────────────────────────────────────────


@app.route("/")
def index():
    return render_template("index.html")


# On Vercel only /tmp is writable; use it for uploads
_ON_VERCEL = bool(os.getenv("VERCEL"))
_DATA_ROOT = Path("/tmp/kb_data") if _ON_VERCEL else Path(__file__).parent / "data"

_DATA_ROOT.mkdir(parents=True, exist_ok=True)


def _make_thumbnail_b64(path: Path, max_px: int = 400) -> str | None:
    """Return a data URL for a resized JPEG thumbnail, or None on failure.
    Tries quality 82 → 70 → 55 to stay within Pinecone's 40KB metadata limit.
    """
    try:
        from PIL import Image as _PILImage

        with _PILImage.open(path) as img:
            img = img.convert("RGB")
            img.thumbnail((max_px, max_px), _PILImage.LANCZOS)
            for quality in (82, 70, 55):
                buf = io.BytesIO()
                img.save(buf, format="JPEG", quality=quality)
                b64 = base64.b64encode(buf.getvalue()).decode()
                if len(b64) <= 32_000:
                    return "data:image/jpeg;base64," + b64
        return None
    except Exception:
        return None


@app.route("/media/<path:filename>")
def serve_media(filename):
    file_path = (_DATA_ROOT / filename).resolve()
    # Prevent directory traversal
    if not str(file_path).startswith(str(_DATA_ROOT.resolve())):
        abort(403)
    if not file_path.exists():
        abort(404)
    return send_file(file_path)


@app.route("/api/chat", methods=["POST"])
def chat():
    data = request.get_json()
    question = (data or {}).get("message", "").strip()
    if not question:
        return jsonify({"error": "No message provided"}), 400

    try:
        from src.embedder import embed_text
        from src.pinecone_client import query, query_filtered
        from src.openrouter_client import chat as llm_chat

        vector = embed_text(question, task_type="RETRIEVAL_QUERY")

        # Hybrid query: text gets 7 slots; images/videos get 3 dedicated slots (score >= 0.25)
        # Without dedicated media slots, text documents always fill all top-k results
        # and images (lower cross-modal similarity) are never seen.
        text_results = query(vector, top_k=7)
        media_results = query_filtered(
            vector,
            filter_dict={"type": {"$in": ["image", "video"]}},
            top_k=3,
        )
        all_results = text_results + [r for r in media_results if r["score"] >= 0.25]

        # De-duplicate by filename
        seen_files: set = set()
        deduped = []
        for r in all_results:
            fname = r["metadata"].get("filename", r["id"])
            if fname not in seen_files:
                seen_files.add(fname)
                deduped.append(r)
        results = deduped

        context_parts = []
        for i, r in enumerate(results, 1):
            meta = r["metadata"]
            content_type = meta.get("type", "unknown")
            if content_type == "text":
                snippet = meta.get("content_preview", "")
                source = meta.get("filename", "unknown")
                user_tag = meta.get("user_tag", "")
                tag_note = f" [tagged: {user_tag}]" if user_tag else ""
                context_parts.append(
                    f"[{i}] {source}{tag_note} (score={r['score']:.3f}):\n{snippet}"
                )
            else:
                fname = meta.get("filename", r["id"])
                user_tag = meta.get("user_tag", "")
                tag_note = f" (tagged: {user_tag})" if user_tag else ""
                context_parts.append(f"[{i}] [visual:{fname}{tag_note}]")

        context = (
            "\n\n".join(context_parts)
            if context_parts
            else "No relevant content found."
        )
        model = data.get("model") or os.getenv("CHAT_MODEL", "kimi-k2.5")
        system_prompt = (
            "You are a personal AI assistant with access to the user's documents, images, and files. "
            "Answer using ONLY the retrieved context below. Be specific — quote names, dates, marks, and numbers directly from the context. "
            "Items marked [visual:filename] are images already rendered in the UI; do not mention filenames or say 'image available' — just answer naturally as if you can see them. "
            "If the context does not contain enough detail to answer, say exactly what IS available and what is missing.\n\n"
            f"Context:\n{context}"
        )

        answer = llm_chat(system_prompt, question, model=model)
        sources = []
        for r in results:
            meta = r["metadata"]
            src = {"id": r["id"], "score": round(r["score"], 3), "metadata": meta}
            if meta.get("type") in ("image", "video"):
                if meta.get("data_url"):
                    # Use inline base64 thumbnail — works on Vercel (no file needed)
                    src["url"] = meta["data_url"]
                else:
                    rel = meta.get("rel_path") or meta.get("path", "")
                    rel = Path(rel).as_posix()
                    if "data/" in rel:
                        rel = rel[rel.index("data/") + 5 :]
                    src["url"] = f"/media/{rel}"
            sources.append(src)
        return jsonify({"answer": answer, "sources": sources})

    except Exception as e:
        import traceback

        traceback.print_exc()
        msg = str(e)
        if "429" in msg:
            return jsonify(
                {
                    "error": "Rate limit reached for this free model. Switch to another model in the dropdown and try again."
                }
            ), 429
        return jsonify({"error": msg}), 500


@app.route("/api/search", methods=["POST"])
def search():
    data = request.get_json()
    query_text = (data or {}).get("query", "").strip()
    top_k = int((data or {}).get("top_k", 5))
    if not query_text:
        return jsonify({"error": "No query provided"}), 400

    try:
        from src.embedder import embed_text
        from src.pinecone_client import query as pc_query

        vector = embed_text(query_text, task_type="RETRIEVAL_QUERY")
        results = pc_query(vector, top_k=top_k)
        return jsonify({"results": results})
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/ingest", methods=["POST"])
def ingest():
    data = request.get_json() or {}
    try:
        if "text" in data:
            from src.pipeline import ingest_text

            id = data.get("id") or "text_" + str(abs(hash(data["text"])))[:8]
            ingest_text(data["text"], id)
            return jsonify({"status": "ok", "id": id})

        if "path" in data:
            from src.pipeline import (
                ingest_image,
                ingest_video,
                ingest_text,
                _IMAGE_EXTS,
                _VIDEO_EXTS,
                _PDF_EXT,
                _DOCX_EXT,
                _extract_pdf,
                _extract_docx,
            )
            from pathlib import Path as _P

            file = _P(data["path"])
            ext = file.suffix.lower()
            id = file.stem + "_" + str(abs(hash(str(file))))[:8]
            rel_path = file.as_posix()
            meta = {"filename": file.name, "path": rel_path, "rel_path": rel_path}

            if ext in _IMAGE_EXTS:
                ingest_image(str(file), id, meta)
            elif ext in _VIDEO_EXTS:
                ingest_video(str(file), id, meta)
            elif ext == _PDF_EXT:
                content = _extract_pdf(file)
                ingest_text(content, id, {**meta, "source": "pdf"})
            elif ext == _DOCX_EXT:
                content = _extract_docx(file)
                ingest_text(content, id, {**meta, "source": "docx"})
            else:
                ingest_text(file.read_text(errors="ignore"), id, meta)
            return jsonify({"status": "ok", "id": id})

        return jsonify({"error": "Provide 'path' or 'text' in request body"}), 400
    except Exception as e:
        return jsonify({"error": str(e)}), 500


_IMAGE_EXTS_SET = {".jpg", ".jpeg", ".png", ".gif", ".webp"}
_VIDEO_EXTS_SET = {".mp4", ".mov", ".webm", ".avi", ".mkv"}


@app.route("/api/upload", methods=["POST"])
def upload():
    if "file" not in request.files:
        return jsonify({"error": "No file provided"}), 400

    f = request.files["file"]
    if not f.filename:
        return jsonify({"error": "Empty filename"}), 400

    filename = secure_filename(f.filename)
    ext = Path(filename).suffix.lower()
    tag = request.form.get("tag", "").strip()

    if ext in _IMAGE_EXTS_SET:
        subfolder = "images"
    elif ext in _VIDEO_EXTS_SET:
        subfolder = "videos"
    else:
        subfolder = "documents"

    dest_dir = _DATA_ROOT / subfolder
    dest_dir.mkdir(parents=True, exist_ok=True)
    dest_path = dest_dir / filename
    f.save(str(dest_path))

    try:
        from src.pipeline import (
            ingest_image,
            ingest_video,
            ingest_text,
            _IMAGE_EXTS,
            _VIDEO_EXTS,
            _PDF_EXT,
            _DOCX_EXT,
            _extract_pdf,
            _extract_docx,
        )

        rel_path = f"{subfolder}/{filename}"
        file_id = Path(filename).stem + "_" + str(abs(hash(rel_path)))[:8]
        meta = {
            "filename": filename,
            "path": rel_path,
            "rel_path": rel_path,
            "user_tag": tag,
        }

        if ext in _IMAGE_EXTS:
            # Store thumbnail as data URL so it's serveable on Vercel (no file needed at query time)
            data_url = _make_thumbnail_b64(dest_path)
            if data_url:
                meta["data_url"] = data_url
            ingest_image(str(dest_path), file_id, meta)
            # Also store a text embedding of the tag so text queries can find this image
            if tag:
                from src import embedder as _emb, pinecone_client as _pc

                tag_vec = _emb.embed_text(tag, task_type="RETRIEVAL_DOCUMENT")
                _pc.upsert(
                    file_id + "_tag",
                    tag_vec,
                    {**meta, "type": "image", "tag_vector": True},
                )
        elif ext in _VIDEO_EXTS:
            ingest_video(str(dest_path), file_id, meta)
            if tag:
                from src import embedder as _emb, pinecone_client as _pc

                tag_vec = _emb.embed_text(tag, task_type="RETRIEVAL_DOCUMENT")
                _pc.upsert(
                    file_id + "_tag",
                    tag_vec,
                    {**meta, "type": "video", "tag_vector": True},
                )
        elif ext == _PDF_EXT:
            content = _extract_pdf(dest_path)
            ingest_text(content, file_id, {**meta, "source": "pdf"})
        elif ext == _DOCX_EXT:
            content = _extract_docx(dest_path)
            ingest_text(content, file_id, {**meta, "source": "docx"})
        else:
            ingest_text(dest_path.read_text(errors="ignore"), file_id, meta)

        return jsonify(
            {
                "status": "ok",
                "id": file_id,
                "filename": filename,
                "subfolder": subfolder,
            }
        )
    except Exception as e:
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    port = int(os.getenv("PORT", 5000))
    app.run(debug=False, host="0.0.0.0", port=port)
