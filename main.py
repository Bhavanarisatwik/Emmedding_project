import argparse
import sys


def cmd_ingest(args):
    from src.pipeline import ingest_text, ingest_image, ingest_video, ingest_directory

    if args.dir:
        ingest_directory(args.dir)
        return

    if not args.type or not args.input or not args.id:
        print("Error: --type, --input, and --id are required when not using --dir")
        sys.exit(1)

    if args.type == "text":
        ingest_text(args.input, args.id)
    elif args.type == "image":
        ingest_image(args.input, args.id)
    elif args.type == "video":
        ingest_video(args.input, args.id)
    else:
        print(f"Unknown type: {args.type}. Use text, image, or video.")
        sys.exit(1)


def cmd_search(args):
    from src.retriever import search

    results = search(args.query, top_k=args.top_k)
    if not results:
        print("No results found.")
        return
    for r in results:
        print(f"  id={r['id']}  score={r['score']:.4f}  metadata={r['metadata']}")


def cmd_ask(args):
    from src.retriever import rag_query

    answer = rag_query(args.question, top_k=args.top_k)
    print(answer)


def cmd_delete(args):
    from src.pinecone_client import delete

    delete(args.id)
    print(f"Deleted id={args.id}")


def cmd_wipe(args):
    from src.pinecone_client import delete_all

    confirm = input("This will delete ALL vectors from Pinecone. Type 'yes' to confirm: ")
    if confirm.strip().lower() == "yes":
        delete_all()
    else:
        print("Aborted.")


def main():
    parser = argparse.ArgumentParser(
        description="Multimodal vector DB pipeline using Gemini Embeddings 2 + Pinecone"
    )
    sub = parser.add_subparsers(dest="command", required=True)

    # ingest
    p_ingest = sub.add_parser("ingest", help="Embed and store content")
    p_ingest.add_argument("--type", choices=["text", "image", "video"], help="Content type")
    p_ingest.add_argument("--input", help="Text string or file path")
    p_ingest.add_argument("--id", help="Unique ID for this entry")
    p_ingest.add_argument("--dir", help="Directory to ingest (auto-detects type)")

    # search
    p_search = sub.add_parser("search", help="Semantic search by text query")
    p_search.add_argument("--query", required=True, help="Search query text")
    p_search.add_argument("--top-k", type=int, default=5, dest="top_k")

    # ask
    p_ask = sub.add_parser("ask", help="RAG: answer a question using stored content")
    p_ask.add_argument("--question", required=True, help="Question to answer")
    p_ask.add_argument("--top-k", type=int, default=5, dest="top_k")

    # delete
    p_delete = sub.add_parser("delete", help="Remove an entry by ID")
    p_delete.add_argument("--id", required=True, help="ID to delete")

    # wipe
    sub.add_parser("wipe", help="Delete ALL vectors from Pinecone index")

    args = parser.parse_args()

    dispatch = {
        "ingest": cmd_ingest,
        "search": cmd_search,
        "ask": cmd_ask,
        "delete": cmd_delete,
        "wipe": cmd_wipe,
    }
    dispatch[args.command](args)


if __name__ == "__main__":
    main()
