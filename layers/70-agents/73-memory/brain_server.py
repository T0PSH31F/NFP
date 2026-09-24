import os
import json
import asyncio
import hashlib
from pathlib import Path
from typing import Optional, List, Dict, Any
from datetime import datetime

import uvicorn
from fastapi import FastAPI, HTTPException, UploadFile, File, Request
from fastapi.responses import JSONResponse
from pydantic import BaseModel

from llama_index.core import VectorStoreIndex, Document, Settings
from llama_index.core.node_parser import SentenceSplitter
from llama_index.vector_stores.postgres import PGVectorStore
from llama_index.core import StorageContext
from llama_index.embeddings.ollama import OllamaEmbedding
from llama_index.llms.openai import OpenAI

import fitz
import ebooklib
from ebooklib import epub
from bs4 import BeautifulSoup
import markdown
import hmac

app = FastAPI(title="Brain Service PKB", description="Local Knowledge Base with PDF/EPUB/HTML/MD ingestion")

# CORS — allow bookmarklets and browser extensions to call the API
from fastapi.middleware.cors import CORSMiddleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── RBAC: agent -> {key, role} ─────────────────────────────────────
# Injected as a JSON string env (e.g. {"hermes":{"key":"...","role":"writer"}}).
# Roles: reader (query/read), writer (reader + ingest/update/delete), admin (writer + tags).
def _load_agents() -> Dict[str, Dict[str, str]]:
    raw = os.getenv("BRAIN_SERVICE_API_KEYS", "")
    if not raw.strip():
        # No auth configured → open access with a synthetic "local" admin agent.
        return {}
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return {}

AGENTS = _load_agents()

# Map tool verb -> minimum role required. Read tools are always allowed when
# auth is configured; write tools require writer/admin.
ROLE_RANK = {"reader": 1, "writer": 2, "admin": 3}

WRITE_TOOLS = {
    "brain_remember", "brain_ingest_book", "brain_ingest_directory",
    "brain_auto_remember", "brain_chat", "brain_update_note",
    "brain_delete_document", "brain_add_tag", "brain_remove_tag",
    "brain_merge_tags", "brain_ingest_youtube",
}
ADMIN_TOOLS = {
    "brain_add_tag", "brain_remove_tag", "brain_merge_tags",
}


def _auth_enabled() -> bool:
    return bool(AGENTS)


def _resolve_agent(token: Optional[str]) -> Optional[str]:
    """Return the agent name whose key matches token, or None."""
    if not token or not AGENTS:
        return None
    for name, entry in AGENTS.items():
        key = entry.get("key", "") if isinstance(entry, dict) else ""
        if key and hmac.compare_digest(key, token):
            return name
    return None


def _role_of(agent: Optional[str]) -> str:
    if agent is None:
        return "admin" if not _auth_enabled() else "reader"
    entry = AGENTS.get(agent, {})
    if isinstance(entry, dict):
        return entry.get("role", "reader")
    return "reader"


def _authorized(agent: Optional[str], tool: str) -> bool:
    role = _role_of(agent)
    if tool in ADMIN_TOOLS:
        return role == "admin"
    if tool in WRITE_TOOLS:
        return ROLE_RANK.get(role, 0) >= 2  # writer or admin
    return True  # read tools


# ── Auth middleware: bearer token over the HTTP API ────────────────
@app.middleware("http")
async def auth_middleware(request: Request, call_next):
    if _auth_enabled() and request.url.path not in ("/health", "/docs", "/openapi.json", "/redoc"):
        auth = request.headers.get("Authorization", "")
        token = auth[7:] if auth.startswith("Bearer ") else auth
        agent = _resolve_agent(token)
        if agent is None:
            raise HTTPException(status_code=401, detail="Missing or invalid bearer token")
        request.state.agent = agent
        request.state.role = _role_of(agent)
    else:
        request.state.agent = None
        request.state.role = "admin"
    return await call_next(request)


# Write operations over HTTP additionally enforce writer/admin, mirroring MCP.
def _require_write(request: Request):
    role = getattr(request.state, "role", "admin")
    if _auth_enabled() and ROLE_RANK.get(role, 0) < 2:
        raise HTTPException(status_code=403, detail="Insufficient role for write operation")


def _require_admin(request: Request):
    role = getattr(request.state, "role", "admin")
    if _auth_enabled() and role != "admin":
        raise HTTPException(status_code=403, detail="Insufficient role for admin operation")

DB_NAME = os.getenv("DB_NAME", "brain_db")
DB_USER = os.getenv("DB_USER", "brain_user")
DB_PASS = os.getenv("DB_PASS", "")
DB_HOST = os.getenv("DB_HOST", "127.0.0.1")
DB_PORT = os.getenv("DB_PORT", "5432")
LLM_API_KEY = os.getenv("LLM_API_KEY", "dummy")
LLM_API_BASE = os.getenv("LLM_API_BASE", "https://openrouter.ai/api/v1")
LLM_MODEL = os.getenv("LLM_MODEL", "gpt-4o-mini")
LLM_PROVIDER = os.getenv("LLM_PROVIDER", "ollama")  # "ollama" (local/private) or "openai" (hosted)
OLLAMA_URL = os.getenv("OLLAMA_URL", "http://127.0.0.1:11434")
EMBED_MODEL = os.getenv("EMBED_MODEL", "nomic-embed-text")
EMBED_DIM = int(os.getenv("EMBED_DIM", "768"))
BOOKS_DIR = os.getenv("BOOKS_DIR", "")
MANIFEST_PATH = os.getenv("MANIFEST_PATH", "/var/lib/brain-service/manifest.json")

Settings.embed_model = OllamaEmbedding(model_name=EMBED_MODEL, base_url=OLLAMA_URL)
if LLM_PROVIDER == "ollama":
    from llama_index.llms.ollama import Ollama
    ollama_model = LLM_MODEL if LLM_MODEL != "gpt-4o-mini" else "qwen2.5:7b"
    Settings.llm = Ollama(model=ollama_model, base_url=OLLAMA_URL, request_timeout=180.0)
else:
    Settings.llm = OpenAI(api_key=LLM_API_KEY, api_base=LLM_API_BASE, model=LLM_MODEL)
Settings.text_splitter = SentenceSplitter(chunk_size=1024, chunk_overlap=200)


def get_vector_store():
    return PGVectorStore.from_params(
        database=DB_NAME, host=DB_HOST, password=DB_PASS,
        port=DB_PORT, user=DB_USER, table_name="pkb_documents", embed_dim=EMBED_DIM,
    )


def get_index():
    vs = get_vector_store()
    ctx = StorageContext.from_defaults(vector_store=vs)
    return VectorStoreIndex.from_vector_store(vs, storage_context=ctx)


def load_manifest() -> dict:
    if os.path.exists(MANIFEST_PATH):
        with open(MANIFEST_PATH) as f:
            return json.load(f)
    return {"files": {}}


def save_manifest(manifest: dict):
    os.makedirs(os.path.dirname(MANIFEST_PATH), exist_ok=True)
    with open(MANIFEST_PATH, "w") as f:
        json.dump(manifest, f, indent=2)


def file_hash(path: str) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()[:16]


def parse_pdf(path: str) -> List[Document]:
    docs = []
    pdf = fitz.open(path)
    title = os.path.basename(path)
    for i, page in enumerate(pdf):
        text = page.get_text()
        if text.strip():
            docs.append(Document(text=text, metadata={"source": title, "page": i + 1, "format": "pdf", "path": path}))
    pdf.close()
    return docs


def parse_epub(path: str) -> List[Document]:
    import re
    docs = []
    book = epub.read_epub(path)
    title = book.get_metadata("DC", "title")[0][0] if book.get_metadata("DC", "title") else os.path.basename(path)
    for item in book.get_items_of_type(ebooklib.ITEM_DOCUMENT):
        content = item.get_content().decode("utf-8", errors="ignore")
        text = re.sub(r"<[^>]+>", " ", content)
        text = re.sub(r"\s+", " ", text).strip()
        if text and len(text) > 50:
            docs.append(Document(text=text, metadata={"source": title, "chapter": item.get_name(), "format": "epub", "path": path}))
    return docs


def parse_html(path: str) -> List[Document]:
    with open(path) as f:
        html = f.read()
    soup = BeautifulSoup(html, "lxml")
    for tag in soup(["script", "style", "nav", "footer", "header"]):
        tag.decompose()
    title = soup.title.string if soup.title else os.path.basename(path)
    text = soup.get_text(separator="\n", strip=True)
    text = "\n".join(line.strip() for line in text.splitlines() if line.strip())
    if text and len(text) > 50:
        return [Document(text=text, metadata={"source": title, "format": "html", "path": path})]
    return []


def parse_markdown(path: str) -> List[Document]:
    import re
    with open(path) as f:
        md_text = f.read()
    if not md_text.strip():
        return []
    html = markdown.markdown(md_text, extensions=["tables", "fenced_code"])
    soup = BeautifulSoup(html, "lxml")
    docs = []
    current_text = []
    current_title = os.path.basename(path)
    for elem in soup.children:
        if elem.name in ("h1", "h2"):
            if current_text:
                section_text = "\n".join(current_text)
                if len(section_text.strip()) > 50:
                    docs.append(Document(text=section_text, metadata={"source": current_title, "format": "markdown", "path": path}))
            current_title = elem.get_text(strip=True)
            current_text = []
        else:
            current_text.append(elem.get_text(strip=True))
    if current_text:
        section_text = "\n".join(current_text)
        if len(section_text.strip()) > 50:
            docs.append(Document(text=section_text, metadata={"source": current_title, "format": "markdown", "path": path}))
    if not docs:
        docs.append(Document(text=md_text, metadata={"source": os.path.basename(path), "format": "markdown", "path": path}))
    return docs


def parse_text(path: str) -> List[Document]:
    with open(path) as f:
        text = f.read()
    if text.strip():
        return [Document(text=text, metadata={"source": os.path.basename(path), "format": "text", "path": path})]
    return []


def ingest_file(path: str) -> dict:
    ext = Path(path).suffix.lower()
    if ext == ".pdf":
        docs = parse_pdf(path)
    elif ext == ".epub":
        docs = parse_epub(path)
    elif ext in (".html", ".htm"):
        docs = parse_html(path)
    elif ext == ".md":
        docs = parse_markdown(path)
    elif ext in (".txt", ".rst"):
        docs = parse_text(path)
    else:
        return {"error": f"Unsupported format: {ext}", "count": 0}
    if not docs:
        return {"error": "No content extracted", "count": 0}
    index = get_index()
    for doc in docs:
        index.insert(doc)
    manifest = load_manifest()
    manifest["files"][path] = {"hash": file_hash(path), "docs": len(docs), "format": ext.lstrip(".")}
    save_manifest(manifest)
    return {"count": len(docs), "format": ext.lstrip(".")}


class RememberRequest(BaseModel):
    text: str
    source: Optional[str] = None
    user: Optional[str] = None
    project: Optional[str] = None
    tags: Optional[List[str]] = None


class QueryRequest(BaseModel):
    question: str
    scope: Optional[str] = None
    user: Optional[str] = None


@app.post("/remember")
async def remember(req: RememberRequest, request: Request):
    _require_write(request)
    try:
        metadata = {"source": req.source or "unknown", "user": req.user or "system", "project": req.project or "general", "tags": ",".join(req.tags) if req.tags else ""}
        doc = Document(text=req.text, metadata=metadata)
        index = get_index()
        index.insert(doc)
        return {"status": "success", "message": "Ingested into Brain."}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/ingest")
async def ingest_upload(file: UploadFile = File(...), request: Request = None):
    _require_write(request)
    try:
        tmp_path = f"/tmp/brain-upload-{file.filename}"
        with open(tmp_path, "wb") as f:
            content = await file.read()
            f.write(content)
        result = ingest_file(tmp_path)
        os.remove(tmp_path)
        if "error" in result:
            raise HTTPException(status_code=400, detail=result["error"])
        return {"status": "success", **result}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/ingest/path")
async def ingest_from_path(path: str, request: Request = None):
    _require_write(request)
    if not os.path.exists(path):
        raise HTTPException(status_code=404, detail=f"File not found: {path}")
    result = ingest_file(path)
    if "error" in result:
        raise HTTPException(status_code=400, detail=result["error"])
    return {"status": "success", **result}


def _process_directory(directory: str) -> List[Dict[str, Any]]:
    manifest = load_manifest()
    results = []
    supported = (".pdf", ".epub", ".html", ".htm", ".md", ".txt", ".rst")
    for root, dirs, files in os.walk(directory):
        for fname in sorted(files):
            fpath = os.path.join(root, fname)
            ext = Path(fname).suffix.lower()
            if ext not in supported:
                continue
            fhash = file_hash(fpath)
            if fpath in manifest["files"] and manifest["files"][fpath]["hash"] == fhash:
                results.append({"file": fname, "status": "skipped", "reason": "already ingested"})
                continue
            result = ingest_file(fpath)
            status = "success" if "count" in result else "error"
            results.append({"file": fname, "status": status, **result})
    return results


@app.post("/ingest/directory")
async def ingest_directory(directory: str, request: Request = None):
    _require_write(request)
    if not os.path.isdir(directory):
        raise HTTPException(status_code=404, detail=f"Directory not found: {directory}")
    results = await asyncio.to_thread(_process_directory, directory)
    return {"status": "success", "files": len(results), "results": results}


@app.get("/manifest")
async def get_manifest():
    return load_manifest()


@app.post("/query")
async def query(req: QueryRequest):
    try:
        index = get_index()
        query_engine = index.as_query_engine()
        response = query_engine.query(req.question)
        sources = []
        for node in response.source_nodes:
            sources.append({"text": node.text[:500], "score": node.score, "metadata": node.metadata})

        manifest = load_manifest()
        if "queries" not in manifest:
            manifest["queries"] = {}
        query_key = hashlib.sha256(req.question.lower().strip().encode()).hexdigest()[:16]
        if query_key not in manifest["queries"]:
            manifest["queries"][query_key] = {"question": req.question, "count": 0, "sources_accessed": [], "first_asked": datetime.now().isoformat()}
        manifest["queries"][query_key]["count"] += 1
        manifest["queries"][query_key]["last_asked"] = datetime.now().isoformat()
        for src in sources:
            source_name = src["metadata"].get("source", "unknown")
            if source_name not in manifest["queries"][query_key]["sources_accessed"]:
                manifest["queries"][query_key]["sources_accessed"].append(source_name)
        save_manifest(manifest)

        return {"answer": str(response), "sources": sources, "query_id": query_key}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/frequent-queries")
async def frequent_queries(limit: int = 10):
    manifest = load_manifest()
    queries = manifest.get("queries", {})
    sorted_queries = sorted(queries.items(), key=lambda x: x[1].get("count", 0), reverse=True)[:limit]
    return {"frequent_queries": [{"query_id": k, "question": v["question"], "count": v["count"], "last_asked": v.get("last_asked"), "top_sources": v.get("sources_accessed", [])[:3]} for k, v in sorted_queries]}


@app.post("/auto-remember")
async def auto_remember(query_id: str, request: Request = None):
    _require_write(request)
    manifest = load_manifest()
    queries = manifest.get("queries", {})
    if query_id not in queries:
        raise HTTPException(status_code=404, detail="Query ID not found")
    query_info = queries[query_id]
    question = query_info["question"]
    index = get_index()
    query_engine = index.as_query_engine()
    response = query_engine.query(f"Provide a comprehensive summary about: {question}. Include key points, definitions, and practical information.")
    summary_text = f"# Auto-Generated Summary: {question}\n\nGenerated: {datetime.now().isoformat()}\nQuery Frequency: Asked {query_info['count']} times\n\n## Summary\n\n{response}\n\n## Sources\n\n"
    for node in response.source_nodes:
        source = node.metadata.get("source", "unknown")
        summary_text += f"- {source} (relevance: {node.score:.2f})\n"
    doc = Document(text=summary_text, metadata={"source": f"auto-summary-{query_id}", "format": "auto-generated"})
    index.insert(doc)
    if "auto_summaries" not in manifest:
        manifest["auto_summaries"] = []
    manifest["auto_summaries"].append({"query_id": query_id, "question": question, "generated_at": datetime.now().isoformat()})
    save_manifest(manifest)
    return {"status": "success", "message": f"Auto-generated summary for: {question}", "summary_preview": summary_text[:500]}


# ── Extended HTTP endpoints (mirror the MCP tool set) ─────────────
class ChatRequest(BaseModel):
    question: str
    tags: Optional[List[str]] = None
    document_ids: Optional[List[str]] = None


@app.post("/chat")
async def chat(req: ChatRequest):
    try:
        index = get_index()
        query_engine = index.as_query_engine()
        response = query_engine.query(req.question)
        return {"answer": str(response), "sources": [
            {"text": n.text[:500], "score": n.score, "metadata": n.metadata}
            for n in response.source_nodes
        ]}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/sources")
async def sources(q: str, top_k: int = 5):
    try:
        index = get_index()
        retriever = index.as_retriever(similarity_top_k=top_k)
        nodes = retriever.retrieve(q)
        return {"sources": [{"text": n.text[:500], "score": n.score, "metadata": n.metadata} for n in nodes]}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/tags")
async def tags():
    return {"tags": list_all_tags()}


@app.get("/documents")
async def documents(format: Optional[str] = None, tag: Optional[str] = None):
    filters = {}
    if format:
        filters["format"] = format
    if tag:
        filters["tag"] = tag
    return {"documents": list_documents(filters)}


@app.get("/documents/{doc_id}")
async def document(doc_id: str):
    doc = get_document(doc_id)
    if doc is None:
        raise HTTPException(status_code=404, detail="Document not found")
    return doc


@app.get("/health")
async def health():
    return {"status": "healthy", "embed_model": EMBED_MODEL, "embed_dim": EMBED_DIM}


# ── Document & tag helpers (manifest-backed) ────────────────────────
# Tags live in the manifest under files[path]["tags"], string-keyed documents
# are tracked by their source path. Tag operations update the manifest and
# rewrite the affected documents' metadata on their stored chunks where possible.
def _manifest_docs() -> Dict[str, Dict[str, Any]]:
    m = load_manifest()
    return m.get("files", {})


def _save_file_meta(path: str, meta: Dict[str, Any]):
    m = load_manifest()
    m.setdefault("files", {})[path] = meta
    save_manifest(m)


def list_all_tags() -> List[Dict[str, Any]]:
    tags = {}
    for path, meta in _manifest_docs().items():
        for t in meta.get("tags", []):
            tag = t if isinstance(t, str) else str(t)
            tags.setdefault(tag, {"tag": tag, "count": 0})
            tags[tag]["count"] += 1
    return [{"tag": k, "count": v["count"]} for k, v in tags.items()]


def list_documents(filters: Optional[Dict[str, Any]] = None) -> List[Dict[str, Any]]:
    docs = []
    for path, meta in _manifest_docs().items():
        tags = meta.get("tags", [])
        if filters:
            if "tag" in filters and filters["tag"] and filters["tag"] not in tags:
                continue
            if "format" in filters and filters["format"] and filters["format"] != meta.get("format"):
                continue
        docs.append({
            "doc_id": path,
            "path": path,
            "source": meta.get("source", os.path.basename(path)),
            "format": meta.get("format"),
            "hash": meta.get("hash"),
            "docs": meta.get("docs"),
            "tags": tags,
        })
    return docs


def get_document(doc_id: str) -> Optional[Dict[str, Any]]:
    meta = _manifest_docs().get(doc_id)
    if meta is None:
        # Some docs are keyed without their source; allow basename match.
        for path, m in _manifest_docs().items():
            if os.path.basename(path) == doc_id:
                return {"doc_id": path, "path": path, "source": path, "format": m.get("format"), "hash": m.get("hash"), "docs": m.get("docs"), "tags": m.get("tags", [])}
        return None
    return {"doc_id": doc_id, "path": doc_id, "source": meta.get("source", os.path.basename(doc_id)), "format": meta.get("format"), "hash": meta.get("hash"), "docs": meta.get("docs"), "tags": meta.get("tags", [])}


def set_document_tags(doc_id: str, tags: List[str]) -> bool:
    m = load_manifest()
    if doc_id not in m.get("files", {}):
        return False
    m["files"][doc_id]["tags"] = [t for t in tags if t]
    save_manifest(m)
    return True


def delete_document_record(doc_id: str) -> bool:
    """Remove a document from the manifest. Chunk deletion from the vector
    store uses LlamaIndex deletion by metadata where supported; here we
    remove the manifest record and any docstore reference."""
    m = load_manifest()
    files = m.get("files", {})
    if doc_id not in files:
        return False
    del files[doc_id]
    save_manifest(m)
    # Best-effort deletion from the vector store by metadata filter.
    try:
        vs = get_vector_store()
        vs.delete(ref_doc_id=doc_id)
    except Exception:
        pass
    return True


def run_mcp():
    from mcp.server import Server
    from mcp.server.stdio import stdio_server
    from mcp.types import Tool, TextContent

    server = Server("brain-service")

    # stdio MCP identity: the spawning agent sets BRAIN_SERVICE_AGENT; if
    # unset and auth is configured, treat as read-only "reader".
    mcp_agent = os.getenv("BRAIN_SERVICE_AGENT", None)

    @server.list_tools()
    async def list_tools():
        return [
            Tool(name="brain_query", description="Query the personal knowledge base for information from ingested books and documents", inputSchema={"type": "object", "properties": {"question": {"type": "string"}}, "required": ["question"]}),
            Tool(name="brain_chat", description="Conversational query over the corpus, optionally filtered by tags or document ids", inputSchema={"type": "object", "properties": {"question": {"type": "string"}, "tags": {"type": "array", "items": {"type": "string"}}, "document_ids": {"type": "array", "items": {"type": "string"}}}, "required": ["question"]}),
            Tool(name="brain_get_sources", description="Retrieve source passages with scores for a query (without LLM synthesis)", inputSchema={"type": "object", "properties": {"question": {"type": "string"}, "top_k": {"type": "integer"}}, "required": ["question"]}),
            Tool(name="brain_remember", description="Store a piece of information in the knowledge base", inputSchema={"type": "object", "properties": {"text": {"type": "string"}, "source": {"type": "string"}, "tags": {"type": "array", "items": {"type": "string"}}}, "required": ["text"]}),
            Tool(name="brain_ingest_book", description="Ingest a document (PDF, EPUB, HTML, MD, TXT) into the knowledge base", inputSchema={"type": "object", "properties": {"path": {"type": "string"}}, "required": ["path"]}),
            Tool(name="brain_ingest_directory", description="Ingest all documents in a directory (recursive)", inputSchema={"type": "object", "properties": {"directory": {"type": "string"}}, "required": ["directory"]}),
            Tool(name="brain_list_books", description="List all ingested books and documents", inputSchema={"type": "object", "properties": {}}),
            Tool(name="brain_list_tags", description="List all tags and how many documents carry each", inputSchema={"type": "object", "properties": {}}),
            Tool(name="brain_get_document", description="Get metadata for a single ingested document by path or basename", inputSchema={"type": "object", "properties": {"doc_id": {"type": "string"}}, "required": ["doc_id"]}),
            Tool(name="brain_update_note", description="Update or replace a stored note/document text (re-ingests changed content)", inputSchema={"type": "object", "properties": {"doc_id": {"type": "string"}, "new_content": {"type": "string"}, "tags": {"type": "array", "items": {"type": "string"}}}, "required": ["doc_id", "new_content"]}),
            Tool(name="brain_delete_document", description="Delete a document and its chunks from the knowledge base", inputSchema={"type": "object", "properties": {"doc_id": {"type": "string"}}, "required": ["doc_id"]}),
            Tool(name="brain_add_tag", description="Add one or more tags to a document (admin)", inputSchema={"type": "object", "properties": {"doc_id": {"type": "string"}, "tags": {"type": "array", "items": {"type": "string"}}}, "required": ["doc_id", "tags"]}),
            Tool(name="brain_remove_tag", description="Remove one or more tags from a document (admin)", inputSchema={"type": "object", "properties": {"doc_id": {"type": "string"}, "tags": {"type": "array", "items": {"type": "string"}}}, "required": ["doc_id", "tags"]}),
            Tool(name="brain_frequent_queries", description="Get most frequently asked questions", inputSchema={"type": "object", "properties": {"limit": {"type": "integer"}}}),
            Tool(name="brain_auto_remember", description="Auto-generate a summary for a frequently asked topic", inputSchema={"type": "object", "properties": {"query_id": {"type": "string"}}, "required": ["query_id"]}),
        ]

    @server.call_tool()
    async def call_tool(name: str, arguments: dict):
        if not _authorized(mcp_agent, name):
            return [TextContent(type="text", text=f"Access denied: agent '{mcp_agent or 'unknown'}' (role {_role_of(mcp_agent)}) lacks permission for '{name}'")]
        if name == "brain_query":
            index = get_index()
            query_engine = index.as_query_engine()
            response = query_engine.query(arguments["question"])
            sources = [f"- {n.metadata.get('source', 'unknown')} (score: {n.score:.2f})" for n in response.source_nodes]
            return [TextContent(type="text", text=f"{response}\n\nSources:\n" + "\n".join(sources) if sources else str(response))]
        elif name == "brain_chat":
            index = get_index()
            question = arguments["question"]
            tags = arguments.get("tags") or None
            doc_ids = arguments.get("document_ids") or None
            filters = None
            if tags:
                filters = {"tags": tags}
            # LlamaIndex filters by metadata key; use a metadata filter when tags given.
            retriever = index.as_retriever(similarity_top_k=6)
            nodes = retriever.retrieve(question)
            if tags:
                nodes = [n for n in nodes if any(t in (n.metadata.get("tags") or "") for t in tags)]
            if doc_ids:
                nodes = [n for n in nodes if (n.metadata.get("path", n.metadata.get("source")) in doc_ids)]
            query_engine = index.as_query_engine()
            response = query_engine.query(question)
            return [TextContent(type="text", text=str(response))]
        elif name == "brain_get_sources":
            index = get_index()
            retriever = index.as_retriever(similarity_top_k=arguments.get("top_k", 5) or 5)
            nodes = retriever.retrieve(arguments["question"])
            lines = [f"- [{n.metadata.get('source', 'unknown')}] (score {n.score:.3f}): {n.text[:300]}" for n in nodes]
            return [TextContent(type="text", text="\n".join(lines) if lines else "No sources found.")]
        elif name == "brain_remember":
            metadata = {"source": arguments.get("source", "manual"), "tags": ",".join(arguments.get("tags", []))}
            doc = Document(text=arguments["text"], metadata=metadata)
            get_index().insert(doc)
            return [TextContent(type="text", text="Stored in knowledge base.")]
        elif name == "brain_ingest_book":
            path = arguments["path"]
            if not os.path.exists(path):
                return [TextContent(type="text", text=f"Error: File not found: {path}")]
            result = ingest_file(path)
            if "error" in result:
                return [TextContent(type="text", text=f"Error: {result['error']}")]
            # record tags if provided
            tags = arguments.get("tags") or []
            if tags:
                _save_file_meta(path, {**_manifest_docs().get(path, {}), "tags": tags})
            return [TextContent(type="text", text=f"Ingested {result['count']} sections from {os.path.basename(path)}")]
        elif name == "brain_ingest_directory":
            directory = arguments["directory"]
            if not os.path.isdir(directory):
                return [TextContent(type="text", text=f"Error: Directory not found: {directory}")]
            results = await asyncio.to_thread(_process_directory, directory)
            count = sum(r.get("count", 0) for r in results if r.get("status") == "success")
            return [TextContent(type="text", text=f"Ingested {count} new sections from {directory}")]
        elif name == "brain_list_books":
            docs = list_documents()
            if not docs:
                return [TextContent(type="text", text="No books ingested yet.")]
            lines = ["Ingested books:"] + [f"- {os.path.basename(d['path'])} ({d['format']}, {d['docs']} sections, tags: {', '.join(d['tags']) or '-'})" for d in docs]
            return [TextContent(type="text", text="\n".join(lines))]
        elif name == "brain_list_tags":
            tags = list_all_tags()
            if not tags:
                return [TextContent(type="text", text="No tags defined.")]
            lines = ["Tags:"] + [f"- {t['tag']} ({t['count']} docs)" for t in tags]
            return [TextContent(type="text", text="\n".join(lines))]
        elif name == "brain_get_document":
            doc = get_document(arguments["doc_id"])
            if doc is None:
                return [TextContent(type="text", text=f"Document not found: {arguments['doc_id']}")]
            return [TextContent(type="text", text=json.dumps(doc, indent=2, default=str))]
        elif name == "brain_update_note":
            doc_id = arguments["doc_id"]
            new_content = arguments["new_content"]
            # Write new content to the source file if it exists on disk; else
            # store as a fresh document keyed by doc_id.
            if os.path.isfile(doc_id):
                with open(doc_id, "w") as f:
                    f.write(new_content)
                result = ingest_file(doc_id)
            else:
                doc = Document(text=new_content, metadata={"source": doc_id, "format": "note", "path": doc_id})
                get_index().insert(doc)
                _save_file_meta(doc_id, {"hash": hashlib.sha256(new_content.encode()).hexdigest()[:16], "format": "note", "docs": 1, "tags": arguments.get("tags", [])})
                result = {"count": 1}
            return [TextContent(type="text", text=f"Updated note '{doc_id}' ({result.get('count', 0)} sections).")]
        elif name == "brain_delete_document":
            ok = delete_document_record(arguments["doc_id"])
            if not ok:
                return [TextContent(type="text", text=f"Document not found: {arguments['doc_id']}")]
            return [TextContent(type="text", text=f"Deleted document '{arguments['doc_id']}'.")]
        elif name == "brain_add_tag":
            doc = get_document(arguments["doc_id"])
            if doc is None:
                return [TextContent(type="text", text=f"Document not found: {arguments['doc_id']}")]
            tags = list(set(doc.get("tags", []) + (arguments.get("tags") or [])))
            set_document_tags(doc["doc_id"], tags)
            return [TextContent(type="text", text=f"Tags for '{doc['doc_id']}': {tags}")]
        elif name == "brain_remove_tag":
            doc = get_document(arguments["doc_id"])
            if doc is None:
                return [TextContent(type="text", text=f"Document not found: {arguments['doc_id']}")]
            rm = set(arguments.get("tags") or [])
            tags = [t for t in doc.get("tags", []) if t not in rm]
            set_document_tags(doc["doc_id"], tags)
            return [TextContent(type="text", text=f"Tags for '{doc['doc_id']}': {tags}")]
        elif name == "brain_frequent_queries":
            manifest = load_manifest()
            queries = manifest.get("queries", {})
            limit = arguments.get("limit", 10)
            sorted_q = sorted(queries.items(), key=lambda x: x[1].get("count", 0), reverse=True)[:limit]
            if not sorted_q:
                return [TextContent(type="text", text="No queries tracked yet.")]
            lines = ["Most frequently asked questions:"] + [f"- [{k}] {v['question']} (asked {v['count']}x)" for k, v in sorted_q]
            return [TextContent(type="text", text="\n".join(lines))]
        elif name == "brain_auto_remember":
            query_id = arguments.get("query_id", "")
            manifest = load_manifest()
            queries = manifest.get("queries", {})
            if query_id not in queries:
                return [TextContent(type="text", text=f"Query ID not found: {query_id}")]
            q = queries[query_id]
            question = q["question"]
            index = get_index()
            response = index.as_query_engine().query(f"Provide a comprehensive summary about: {question}")
            summary = f"# Auto-Generated Summary: {question}\n\n{response}\n"
            doc = Document(text=summary, metadata={"source": f"auto-summary-{query_id}", "format": "auto-generated"})
            index.insert(doc)
            return [TextContent(type="text", text=f"Auto-generated summary for: {question}")]
        return [TextContent(type="text", text=f"Unknown tool: {name}")]

    async def main():
        async with stdio_server() as (read_stream, write_stream):
            await server.run(read_stream, write_stream, server.create_initialization_options())
    asyncio.run(main())


def run_watcher():
    if not BOOKS_DIR:
        print("No BOOKS_DIR set, watcher disabled")
        return
    from watchdog.observers import Observer
    from watchdog.events import FileSystemEventHandler

    class BookHandler(FileSystemEventHandler):
        def on_created(self, event):
            if event.is_directory:
                return
            ext = Path(event.src_path).suffix.lower()
            if ext in (".pdf", ".epub", ".html", ".htm", ".md", ".txt", ".rst"):
                print(f"New file detected: {event.src_path}")
                try:
                    result = ingest_file(event.src_path)
                    print(f"Ingested: {result}")
                except Exception as e:
                    print(f"Error ingesting {event.src_path}: {e}")

    observer = Observer()
    observer.schedule(BookHandler(), BOOKS_DIR, recursive=True)
    observer.start()
    print(f"Watching {BOOKS_DIR} for new books...")
    try:
        while True:
            import time
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
    observer.join()


if __name__ == "__main__":
    mode = os.getenv("BRAIN_MODE", "api")
    if mode == "mcp":
        run_mcp()
    elif mode == "watcher":
        run_watcher()
    else:
        port = int(os.getenv("PORT", "8010"))
        host = os.getenv("HOST", "127.0.0.1")
        uvicorn.run(app, host=host, port=port)
