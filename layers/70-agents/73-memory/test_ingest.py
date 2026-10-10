import sys
import os
import asyncio
import time
import tempfile
import types
from unittest.mock import MagicMock

# Create proper package structure for mocks
def create_mock_module(name):
    mod = types.ModuleType(name)
    sys.modules[name] = mod
    return mod

fastapi_mod = create_mock_module('fastapi')
fastapi_resp = create_mock_module('fastapi.responses')
fastapi_cors = create_mock_module('fastapi.middleware.cors')
fastapi_middleware = create_mock_module('fastapi.middleware')
pydantic_mod = create_mock_module('pydantic')

class DummyHTTPException(Exception):
    def __init__(self, status_code, detail):
        self.status_code = status_code
        self.detail = detail

fastapi_mod.HTTPException = DummyHTTPException

class DummyFastAPI:
    def __init__(self, *args, **kwargs):
        pass
    def post(self, *args, **kwargs):
        def decorator(func):
            return func
        return decorator
    def get(self, *args, **kwargs):
        def decorator(func):
            return func
        return decorator
    def middleware(self, *args, **kwargs):
        def decorator(func):
            return func
        return decorator
    def add_middleware(self, *args, **kwargs):
        pass

fastapi_mod.FastAPI = DummyFastAPI
fastapi_mod.Request = MagicMock
fastapi_mod.UploadFile = MagicMock
fastapi_mod.File = MagicMock
fastapi_resp.JSONResponse = MagicMock
fastapi_cors.CORSMiddleware = MagicMock

class DummyBaseModel:
    pass
pydantic_mod.BaseModel = DummyBaseModel

for mod in [
    'uvicorn',
    'llama_index', 'llama_index.core', 'llama_index.core.node_parser',
    'llama_index.vector_stores', 'llama_index.vector_stores.postgres',
    'llama_index.embeddings', 'llama_index.embeddings.ollama',
    'llama_index.llms', 'llama_index.llms.openai', 'llama_index.llms.ollama',
    'fitz', 'ebooklib', 'bs4', 'markdown'
]:
    if mod not in sys.modules:
        sys.modules[mod] = MagicMock()

import brain_server

async def run_tests():
    print("=== Running Functional Tests ===")
    brain_server._require_write = lambda req: None

    # Test 1: Non-existent directory raises HTTPException 404
    try:
        await brain_server.ingest_directory("/non/existent/path/xyz")
        assert False, "Should have raised 404 HTTPException"
    except DummyHTTPException as exc:
        assert exc.status_code == 404, f"Expected 404, got {exc.status_code}"
        print("Test 1 Passed: 404 returned for missing directory")

    # Test 2: Filtering and Manifest skipping
    with tempfile.TemporaryDirectory() as temp_dir:
        f_txt = os.path.join(temp_dir, "doc1.txt")
        f_unsupported = os.path.join(temp_dir, "image.png")
        with open(f_txt, "w") as f: f.write("hello world")
        with open(f_unsupported, "w") as f: f.write("png data")

        brain_server.load_manifest = lambda: {
            "files": {
                f_txt: {"hash": "hash_matching"}
            }
        }
        brain_server.file_hash = lambda p: "hash_matching"

        ingested_files = []
        brain_server.ingest_file = lambda p: (ingested_files.append(p) or {"count": 1})

        res = await brain_server.ingest_directory(temp_dir)
        assert res["status"] == "success"
        assert res["files"] == 1
        assert res["results"][0]["status"] == "skipped"
        assert len(ingested_files) == 0, "Skipped file should not be ingested"
        print("Test 2 Passed: Supported extensions filtered & manifest skipping verified")

async def run_benchmark():
    print("\n=== Running Event-Loop Responsiveness Benchmark ===")
    with tempfile.TemporaryDirectory() as temp_dir:
        for i in range(10):
            subdir = os.path.join(temp_dir, f"subdir_{i}")
            os.makedirs(subdir, exist_ok=True)
            for j in range(50):
                fpath = os.path.join(subdir, f"file_{j}.txt")
                with open(fpath, "w") as f:
                    f.write(f"Sample content for directory file {i}_{j}\n" * 10)

        brain_server._require_write = lambda req: None
        brain_server.load_manifest = lambda: {"files": {}}
        brain_server.file_hash = lambda p: time.sleep(0.001) or "dummyhash12345678"
        brain_server.ingest_file = lambda p: time.sleep(0.002) or {"count": 1, "status": "ok"}

        ping_ticks = 0
        running = True

        async def pinger():
            nonlocal ping_ticks
            while running:
                ping_ticks += 1
                await asyncio.sleep(0.001)

        ping_task = asyncio.create_task(pinger())

        start_time = time.perf_counter()
        response = await brain_server.ingest_directory(temp_dir)
        elapsed = time.perf_counter() - start_time

        running = False
        await ping_task

        print(f"Directory Ingestion Response: status={response.get('status')}, files={response.get('files')}")
        print(f"Elapsed Time: {elapsed:.4f} seconds")
        print(f"Event Loop Ping Ticks during operation: {ping_ticks}")
        assert ping_ticks > 100, f"Expected event loop to remain unblocked, got {ping_ticks} ticks"
        print("Benchmark Passed: Event loop remained unblocked throughout operation!")

if __name__ == "__main__":
    asyncio.run(run_tests())
    asyncio.run(run_benchmark())
