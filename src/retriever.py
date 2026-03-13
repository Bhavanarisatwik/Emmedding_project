from src import embedder, pinecone_client, openrouter_client


def search(query_text: str, top_k: int = 5) -> list[dict]:
    vector = embedder.embed_text(query_text, task_type="RETRIEVAL_QUERY")
    return pinecone_client.query(vector, top_k=top_k)


def rag_query(question: str, top_k: int = 5) -> str:
    results = search(question, top_k=top_k)

    if not results:
        return "No relevant content found in the database."

    context_parts = []
    for i, r in enumerate(results, 1):
        meta = r["metadata"]
        content_type = meta.get("type", "unknown")
        if content_type == "text":
            snippet = meta.get("content_preview", "")
            context_parts.append(f"[{i}] Text (score={r['score']:.3f}): {snippet}")
        else:
            path = meta.get("path", meta.get("filename", r["id"]))
            context_parts.append(
                f"[{i}] {content_type.capitalize()} file (score={r['score']:.3f}): {path}"
            )

    context = "\n".join(context_parts)
    system_prompt = (
        "You are a helpful assistant. Answer the user's question using only "
        "the retrieved context below. If you cannot answer from the context, say so.\n\n"
        f"Context:\n{context}"
    )
    return openrouter_client.chat(system_prompt, question)
