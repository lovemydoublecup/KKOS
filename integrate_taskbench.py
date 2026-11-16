import json
import os
import sys

try:
    import chromadb
    from fastembed import TextEmbedding
except ImportError as e:
    print(f"Error: Missing local dependencies for offline memory ({e})")
    print("Run 'python setup.py' to initialize the local environment.")
    sys.exit(1)

# Path Configuration
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(BASE_DIR, "data")
CHROMA_PATH = os.path.join(DATA_DIR, "chroma")
JSON_SOURCE = os.path.join(BASE_DIR, "JARVIS-main", "JARVIS-main", "taskbench", "data_huggingface", "user_requests.json")

def integrate():
    print(f"--- Starting Integration: Taskbench to Odysseus ---")
    
    if not os.path.exists(JSON_SOURCE):
        print(f"[Error] Source file not found: {JSON_SOURCE}")
        return

    # 1. Initialize local ChromaDB (Matching Odysseus configuration)
    client = chromadb.PersistentClient(path=CHROMA_PATH)
    collection = client.get_or_create_collection(name="odysseus_memory")
    
    # 2. Initialize the embedding model (Gemma-aware or standard ONNX)
    print("[1/3] Loading embedding model...")
    model = TextEmbedding()

    ids = []
    documents = []
    metadatas = []

    print("[2/3] Parsing Taskbench JSON Lines...")
    # Insight: Ensure the JSON_SOURCE path is actually reachable 
    # and handled as a JSONL (JSON Lines) file.
    with open(JSON_SOURCE, 'r', encoding='utf-8') as f:
        for line in f:
            if not line.strip(): continue
            try:
                entry = json.loads(line)
                if not entry.get('id') or not entry.get('user_request'): continue
                ids.append(entry['id'])
                documents.append(entry['user_request'])
                metadatas.append({"source": "jarvis_taskbench", "task_id": entry['id']})
            except json.JSONDecodeError:
                continue

    # 3. Upsert into Odysseus Store
    print(f"[3/3] Inserting {len(documents)} tasks into Odysseus memory...")
    
    # Chroma handles embedding automatically if we use their default or 
    # we can compute them with fastembed for precision
    collection.add(
        ids=ids,
        documents=documents,
        metadatas=metadatas
    )

    print(f"--- Integration Complete. Odysseus now knows {len(documents)} new skills! ---")

if __name__ == "__main__":
    integrate()