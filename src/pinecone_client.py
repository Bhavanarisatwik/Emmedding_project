import os
from dotenv import load_dotenv
from pinecone import Pinecone, ServerlessSpec

load_dotenv()

_INDEX_NAME = os.getenv("PINECONE_INDEX_NAME", "multimodal-index").strip()
_REGION = os.getenv("PINECONE_REGION", "us-east-1").strip()
_DIMENSIONS = int(os.getenv("EMBEDDING_DIMENSIONS", "1536").strip())


def _get_client() -> Pinecone:
    api_key = os.getenv("PINECONE_API_KEY", "").strip()
    if not api_key:
        raise ValueError("PINECONE_API_KEY is not set in environment")
    return Pinecone(api_key=api_key)


def init_index():
    pc = _get_client()
    existing = [idx.name for idx in pc.list_indexes()]
    if _INDEX_NAME not in existing:
        pc.create_index(
            name=_INDEX_NAME,
            dimension=_DIMENSIONS,
            metric="cosine",
            spec=ServerlessSpec(cloud="aws", region=_REGION),
        )
    return pc.Index(_INDEX_NAME)


def upsert(id: str, vector: list[float], metadata: dict):
    index = init_index()
    index.upsert(vectors=[{"id": id, "values": vector, "metadata": metadata}])


def query(vector: list[float], top_k: int = 5) -> list[dict]:
    index = init_index()
    result = index.query(vector=vector, top_k=top_k, include_metadata=True)
    return [
        {"id": m.id, "score": m.score, "metadata": m.metadata}
        for m in result.matches
    ]


def query_filtered(vector: list[float], filter_dict: dict, top_k: int = 3) -> list[dict]:
    index = init_index()
    result = index.query(vector=vector, top_k=top_k, include_metadata=True, filter=filter_dict)
    return [
        {"id": m.id, "score": m.score, "metadata": m.metadata}
        for m in result.matches
    ]


def delete(id: str):
    index = init_index()
    index.delete(ids=[id])


def delete_all():
    index = init_index()
    index.delete(delete_all=True)
    print("Pinecone index wiped.")
