#!/usr/bin/env python3
"""Book Vault Purifier & RAG Ingestion Pipeline.

Stage 1: File Format Gatekeeper (magic byte verification, quarantine non-books)
Stage 2: Metadata Extraction & Cover Recovery (Calibre ebook-meta / native fallbacks)
Stage 3: Jev Semantic Triage (AI/Passive-Income classification & RAG prioritization)
Stage 4: Calibre/Kavita Standardization & Brain-Service Ingestion Bridge
"""

import argparse
import datetime
import json
import os
import re
import shutil
import subprocess
import sys
import time
import urllib.error
import urllib.request
import zipfile
import xml.etree.ElementTree as ET

JEV_ENGINE_URL = os.environ.get("JEV_ENGINE_URL", "http://127.0.0.1:20130")
BRAIN_SERVICE_URL = os.environ.get("BRAIN_SERVICE_URL", "http://127.0.0.1:8010")

VALID_EXTENSIONS = {".epub", ".pdf", ".mobi", ".azw3", ".cbz"}


def log(msg, level="INFO"):
    ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{ts}] [{level}] {msg}", flush=True)


def create_btrfs_snapshot(target_dir):
    """Create read-only Btrfs snapshot of target directory if on Btrfs subvolume."""
    if not os.path.exists(target_dir):
        return None

    try:
        # Check if filesystem is btrfs
        res = subprocess.run(
            ["btrfs", "subvolume", "show", target_dir],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=3
        )
        if res.returncode == 0:
            snapshot_parent = os.path.join(target_dir, ".snapshots")
            os.makedirs(snapshot_parent, exist_ok=True)
            ts = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
            snap_path = os.path.join(snapshot_parent, f"pre-purify-{ts}")
            snap_res = subprocess.run(
                ["btrfs", "subvolume", "snapshot", "-r", target_dir, snap_path],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                timeout=10
            )
            if snap_res.returncode == 0:
                log(f"Created Btrfs snapshot at {snap_path}")
                return snap_path
            else:
                log(f"Btrfs snapshot failed: {snap_res.stderr.strip()}", level="WARN")
    except FileNotFoundError:
        pass  # btrfs CLI not present
    except Exception as e:
        log(f"Btrfs check non-fatal error: {e}", level="WARN")
    return None


def verify_ebook_magic(path):
    """Validate that file headers match legitimate e-book magic signatures."""
    ext = os.path.splitext(path)[1].lower()
    if ext not in VALID_EXTENSIONS:
        return False, f"Unsupported extension {ext}"

    try:
        with open(path, "rb") as f:
            header = f.read(1024)

        if ext == ".pdf":
            if header.startswith(b"%PDF-"):
                return True, "Valid PDF magic"
            return False, "Corrupted PDF header"

        elif ext == ".epub":
            if not header.startswith(b"PK\x03\x04"):
                return False, "Not a valid ZIP container"
            try:
                with zipfile.ZipFile(path, "r") as zf:
                    if "mimetype" in zf.namelist():
                        mt = zf.read("mimetype").decode("utf-8", errors="ignore").strip()
                        if "application/epub+zip" in mt:
                            return True, "Valid EPUB archive"
                    # Fallback check for container.xml
                    if any("META-INF/container.xml" in n for n in zf.namelist()):
                        return True, "Valid EPUB container.xml"
            except Exception as e:
                return False, f"Invalid EPUB zip structure: {e}"
            return False, "EPUB missing required mimetype"

        elif ext in (".mobi", ".azw3"):
            if len(header) >= 68 and header[60:68] in (b"BOOKMOBI", b"TEXtREAd"):
                return True, f"Valid MOBI/AZW header ({header[60:68].decode('latin-1')})"
            if header.startswith(b"PK\x03\x04"):
                return True, "Valid KF8/AZW3 container"
            return False, "Missing MOBI/PalmDOC header"

        elif ext == ".cbz":
            if not header.startswith(b"PK\x03\x04"):
                return False, "Not a valid ZIP container for CBZ"
            try:
                with zipfile.ZipFile(path, "r") as zf:
                    has_images = any(n.lower().endswith((".jpg", ".jpeg", ".png", ".webp")) for n in zf.namelist())
                    if has_images:
                        return True, "Valid Comic CBZ with image files"
            except Exception as e:
                return False, f"Invalid CBZ zip: {e}"
            return False, "CBZ container contains no images"

    except Exception as e:
        return False, f"Read error: {e}"

    return False, "Unknown format check error"


def extract_metadata_calibre(path):
    """Extract metadata using Calibre ebook-meta utility if available."""
    try:
        res = subprocess.run(
            ["ebook-meta", path],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=10
        )
        if res.returncode == 0:
            meta = {}
            for line in res.stdout.splitlines():
                if ":" in line:
                    k, v = line.split(":", 1)
                    k = k.strip().lower()
                    v = v.strip()
                    meta[k] = v
            title = meta.get("title", "")
            author = meta.get("author(s)", meta.get("author", ""))
            if "&" in author:
                author = author.split("&")[0].strip()
            series = meta.get("series", "")
            series_index = meta.get("series index", "")
            published = meta.get("published", "")
            year = re.search(r"\b(19\d\d|20\d\d)\b", published)
            return {
                "title": title if title and title != "Unknown" else None,
                "author": author if author and author != "Unknown" else None,
                "series": series if series else None,
                "series_index": series_index if series_index else None,
                "year": year.group(1) if year else None,
                "comments": meta.get("comments", "")
            }
    except FileNotFoundError:
        pass
    except Exception as e:
        log(f"Calibre extraction exception on {path}: {e}", level="DEBUG")
    return None


def extract_metadata_native(path):
    """Pure Python metadata extractor for EPUB and PDF."""
    ext = os.path.splitext(path)[1].lower()
    base = os.path.splitext(os.path.basename(path))[0]
    meta = {
        "title": None,
        "author": None,
        "series": None,
        "series_index": None,
        "year": None,
        "comments": ""
    }

    if ext == ".epub":
        try:
            with zipfile.ZipFile(path, "r") as zf:
                # Find OPF path in container.xml
                opf_path = None
                if "META-INF/container.xml" in zf.namelist():
                    root = ET.fromstring(zf.read("META-INF/container.xml"))
                    for elem in root.iter():
                        if elem.tag.endswith("rootfile"):
                            opf_path = elem.attrib.get("full-path")
                            break
                if not opf_path:
                    for n in zf.namelist():
                        if n.endswith(".opf"):
                            opf_path = n
                            break
                if opf_path and opf_path in zf.namelist():
                    opf_root = ET.fromstring(zf.read(opf_path))
                    for elem in opf_root.iter():
                        tag = elem.tag.split("}")[-1].lower()
                        if tag == "title" and not meta["title"] and elem.text:
                            meta["title"] = elem.text.strip()
                        elif tag == "creator" and not meta["author"] and elem.text:
                            meta["author"] = elem.text.strip()
                        elif tag == "date" and not meta["year"] and elem.text:
                            m = re.search(r"\b(19\d\d|20\d\d)\b", elem.text)
                            if m:
                                meta["year"] = m.group(1)
                        elif tag == "description" and elem.text:
                            meta["comments"] = elem.text.strip()[:1000]
                        elif tag == "meta" and elem.attrib.get("name") == "calibre:series":
                            meta["series"] = elem.attrib.get("content")
                        elif tag == "meta" and elem.attrib.get("name") == "calibre:series_index":
                            meta["series_index"] = elem.attrib.get("content")

                # If publication year not found in OPF, inspect first few text/xhtml documents for copyright regex
                if not meta["year"]:
                    text_files = [n for n in zf.namelist() if n.lower().endswith((".xhtml", ".html", ".htm", ".xml"))][:6]
                    for tf in text_files:
                        try:
                            raw_text = zf.read(tf).decode("utf-8", errors="ignore")
                            copy_m = re.search(r"(?:©|\bCopyright\b)\s*(\d{4})", raw_text, re.IGNORECASE)
                            if copy_m:
                                meta["year"] = copy_m.group(1)
                                break
                        except Exception:
                            pass
        except Exception:
            pass

    elif ext == ".pdf":
        try:
            with open(path, "rb") as f:
                content = f.read(256000)
            t_match = re.search(rb"/Title\s*\((.*?)\)", content)
            a_match = re.search(rb"/Author\s*\((.*?)\)", content)
            d_match = re.search(rb"/CreationDate\s*\(D:(\d{4})", content)
            if t_match:
                meta["title"] = t_match.group(1).decode("latin-1", errors="ignore").strip()
            if a_match:
                meta["author"] = a_match.group(1).decode("latin-1", errors="ignore").strip()
            if d_match:
                meta["year"] = d_match.group(1).decode("ascii", errors="ignore")

            # Fallback to copyright regex in PDF content stream
            if not meta["year"]:
                decoded_content = content.decode("latin-1", errors="ignore")
                copy_m = re.search(r"(?:©|\bCopyright\b)\s*(\d{4})", decoded_content, re.IGNORECASE)
                if copy_m:
                    meta["year"] = copy_m.group(1)
        except Exception:
            pass

    # Heuristic fallback from filename
    if not meta["title"] or not meta["author"]:
        clean_base = re.sub(r"\[.*?\]|\(.*?\)", "", base).strip()
        if " - " in clean_base:
            parts = clean_base.split(" - ", 1)
            meta["author"] = meta["author"] or parts[0].strip()
            meta["title"] = meta["title"] or parts[1].strip()
        else:
            meta["title"] = meta["title"] or clean_base
            meta["author"] = meta["author"] or "Unknown Author"

    y_match = re.search(r"\b(19\d\d|20\d\d)\b", base)
    if not meta["year"] and y_match:
        meta["year"] = y_match.group(1)

    return meta


def extract_metadata(path):
    """Combine Calibre and native metadata extraction for maximum coverage."""
    calibre_meta = extract_metadata_calibre(path) or {}
    native_meta = extract_metadata_native(path)
    merged = {}
    for k in ["title", "author", "series", "series_index", "year", "comments"]:
        val = calibre_meta.get(k)
        if not val or val == "Unknown":
            val = native_meta.get(k)
        merged[k] = val
    return merged


def extract_cover_art(book_path, companion_cover_path):
    """Extract embedded cover image to companion .cover.jpg alongside book_path."""
    if os.path.exists(companion_cover_path) and os.path.getsize(companion_cover_path) > 100:
        return True

    # Method 1: Calibre ebook-meta
    try:
        res = subprocess.run(
            ["ebook-meta", book_path, f"--get-cover={companion_cover_path}"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=8
        )
        if res.returncode == 0 and os.path.exists(companion_cover_path) and os.path.getsize(companion_cover_path) > 100:
            return True
    except FileNotFoundError:
        pass
    except Exception:
        pass

    ext = os.path.splitext(book_path)[1].lower()

    # Method 2: EPUB internal zip extraction
    if ext == ".epub":
        try:
            with zipfile.ZipFile(book_path, "r") as zf:
                # Find cover entry
                for n in zf.namelist():
                    n_lower = n.lower()
                    if ("cover" in n_lower or "front" in n_lower) and n_lower.endswith((".jpg", ".jpeg", ".png")):
                        data = zf.read(n)
                        if len(data) > 500:
                            with open(companion_cover_path, "wb") as cf:
                                cf.write(data)
                            return True
        except Exception:
            pass

    # Method 3: PDF page 1 thumbnail via pdftoppm
    if ext == ".pdf":
        try:
            dest_dir = os.path.dirname(companion_cover_path) or "."
            prefix = os.path.join(dest_dir, "cover_tmp")
            res = subprocess.run(
                ["pdftoppm", "-jpeg", "-r", "150", "-f", "1", "-l", "1", book_path, prefix],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                timeout=10
            )
            candidates = [os.path.join(dest_dir, f) for f in os.listdir(dest_dir) if f.startswith("cover_tmp-")]
            if candidates:
                shutil.move(candidates[0], companion_cover_path)
                for c in candidates[1:]:
                    os.remove(c)
                return True
        except FileNotFoundError:
            pass
        except Exception:
            pass

    return False


def build_canonical_filename(meta, ext):
    """Format canonical filename: [YYYY] Book Title - (Author Name).ext (fallback [0000])."""
    author = meta.get("author") or "Unknown Author"
    title = meta.get("title") or "Untitled"
    series = meta.get("series")
    series_idx = meta.get("series_index")
    year = meta.get("year")

    # Sanitize components
    author_clean = re.sub(r'[/\\:*?"<>|]', "", author).strip()
    title_clean = re.sub(r'[/\\:*?"<>|]', "", title).strip()

    if series:
        series_clean = re.sub(r'[/\\:*?"<>|]', "", series).strip()
        if series_idx:
            try:
                idx_fmt = f"#{int(float(series_idx)):02d}"
            except Exception:
                idx_fmt = f"#{series_idx}"
            title_clean += f" [{series_clean} {idx_fmt}]"
        else:
            title_clean += f" [{series_clean}]"

    year_str = str(year or "").strip()
    if not re.match(r"^\d{4}$", year_str):
        year_str = "0000"

    return f"[{year_str}] {title_clean} - ({author_clean}){ext}"


def jev_triage_book(meta, text_snippet=""):
    """Query Jev System-1 Decision Engine for book classification and RAG priority."""
    author = meta.get("author", "Unknown Author")
    title = meta.get("title", "Untitled")
    comments = meta.get("comments", "") or text_snippet

    state = f"Title: {title}\nAuthor: {author}\nExtracted_TOC: {comments[:800]}"

    questions = [
        {"id": "is_ai_or_passive_income", "type": "boolean"},
        {
            "id": "primary_domain",
            "type": "enum",
            "options": [
                "ai_agent_architecture",
                "machine_learning_llm",
                "passive_income_business",
                "technical_programming",
                "general_fiction",
                "general_nonfiction"
            ]
        },
        {
            "id": "brain_service_ingest_priority",
            "type": "enum",
            "options": [
                "p0_immediate_rag_ingest",
                "p1_standard_rag_ingest",
                "skip_general_library_only"
            ]
        }
    ]

    payload = json.dumps({"state": state, "questions": questions}).encode("utf-8")
    url = f"{JEV_ENGINE_URL.rstrip('/')}/v1/decide"

    try:
        req = urllib.request.Request(
            url,
            data=payload,
            headers={"Content-Type": "application/json"},
            method="POST"
        )
        with urllib.request.urlopen(req, timeout=3.0) as resp:
            if resp.status == 200:
                data = json.loads(resp.read().decode("utf-8"))
                decisions = data.get("decisions", {})
                return {
                    "is_ai_or_passive_income": decisions.get("is_ai_or_passive_income", {}).get("value", False),
                    "primary_domain": decisions.get("primary_domain", {}).get("value", "general_nonfiction"),
                    "brain_service_ingest_priority": decisions.get("brain_service_ingest_priority", {}).get("value", "skip_general_library_only"),
                    "confidence": decisions.get("brain_service_ingest_priority", {}).get("confidence", 0.85)
                }
    except Exception as e:
        log(f"Jev Engine unreachable ({e}); applying embedded decision logic", level="DEBUG")

    # Local embedded fallback logic
    combined = f"{title} {author} {comments}".lower()
    is_ai_income = any(w in combined for w in [
        "agent", "agentic", "ai", "machine learning", "deep learning", "llm", "rag",
        "vector", "transformer", "neural", "prompt", "mcp", "passive income",
        "cash flow", "business", "entrepreneur", "saas", "sales", "wealth", "marketing"
    ])

    if any(w in combined for w in ["agent", "agentic", "mcp", "orchestrat"]):
        domain = "ai_agent_architecture"
        priority = "p0_immediate_rag_ingest"
    elif any(w in combined for w in ["machine learning", "deep learning", "llm", "neural", "transformer", "rag"]):
        domain = "machine_learning_llm"
        priority = "p0_immediate_rag_ingest"
    elif any(w in combined for w in ["passive income", "cash flow", "business", "entrepreneur", "marketing"]):
        domain = "passive_income_business"
        priority = "p0_immediate_rag_ingest"
    elif any(w in combined for w in ["programming", "linux", "database", "software", "python", "rust", "nix", "code"]):
        domain = "technical_programming"
        priority = "p1_standard_rag_ingest"
    elif any(w in combined for w in ["novel", "fiction", "fantasy", "mystery", "thriller", "story"]):
        domain = "general_fiction"
        priority = "skip_general_library_only"
    else:
        domain = "general_nonfiction"
        priority = "skip_general_library_only"

    return {
        "is_ai_or_passive_income": is_ai_income,
        "primary_domain": domain,
        "brain_service_ingest_priority": priority,
        "confidence": 0.88
    }


def dispatch_brain_service_ingest(book_path, tags=None):
    """Dispatch document to Brain-Service API for PGVector embedding indexing."""
    payload = json.dumps({"path": os.path.abspath(book_path)}).encode("utf-8")
    for endpoint in ["/ingest/file", "/ingest/path"]:
        url = f"{BRAIN_SERVICE_URL.rstrip('/')}{endpoint}"
        try:
            req = urllib.request.Request(
                url,
                data=payload,
                headers={"Content-Type": "application/json"},
                method="POST"
            )
            with urllib.request.urlopen(req, timeout=5.0) as resp:
                if resp.status == 200:
                    data = json.loads(resp.read().decode("utf-8"))
                    log(f"Brain-service ingested {os.path.basename(book_path)}: {data.get('message', 'ok')}")
                    return True, data
        except Exception:
            continue
    log(f"Brain-service ingest unavailable on {BRAIN_SERVICE_URL} for {os.path.basename(book_path)}", level="WARN")
    return False, None


def purify_file(file_path, library_dir, quarantine_dir, brain_inbox_dir, dry_run=False):
    """Purify a single candidate file through the 4-stage pipeline."""
    filename = os.path.basename(file_path)
    log(f"Inspecting candidate: {filename}")

    # Stage 1: Gatekeeper Check
    is_valid, reason = verify_ebook_magic(file_path)
    if not is_valid:
        log(f"Quarantining non-book ({reason}): {filename}", level="WARN")
        target_quarantine = os.path.join(quarantine_dir, "non-books")
        os.makedirs(target_quarantine, exist_ok=True)
        dest = os.path.join(target_quarantine, filename)
        if not dry_run:
            shutil.move(file_path, dest)
            meta_path = dest + ".quarantine.json"
            with open(meta_path, "w", encoding="utf-8") as qf:
                json.dump({
                    "original_path": file_path,
                    "quarantine_time": datetime.datetime.now().isoformat(),
                    "reason": reason
                }, qf, indent=2)
        return {
            "status": "quarantined",
            "file": filename,
            "reason": reason
        }

    # Stage 2: Metadata & Cover Extraction
    ext = os.path.splitext(file_path)[1].lower()
    meta = extract_metadata(file_path)
    canonical_filename = build_canonical_filename(meta, ext)

    author = re.sub(r'[/\\:*?"<>|]', "", meta.get("author") or "Unknown Author").strip()
    title = re.sub(r'[/\\:*?"<>|]', "", meta.get("title") or "Untitled").strip()

    dest_file = os.path.join(library_dir, canonical_filename)
    companion_cover = os.path.splitext(dest_file)[0] + ".cover.jpg"
    receipt_path = os.path.splitext(dest_file)[0] + ".metadata.json"

    # Stage 3: Jev Semantic Triage
    triage = jev_triage_book(meta)
    log(f"Jev decision: domain={triage['primary_domain']}, priority={triage['brain_service_ingest_priority']}, ai_income={triage['is_ai_or_passive_income']}")

    if dry_run:
        return {
            "status": "purified",
            "dry_run": True,
            "source": file_path,
            "canonical_file": dest_file,
            "author": author,
            "title": title,
            "triage": triage
        }

    # Execute moves and write standardized metadata
    os.makedirs(library_dir, exist_ok=True)
    shutil.move(file_path, dest_file)

    # Cover extraction to companion .cover.jpg
    has_cover = extract_cover_art(dest_file, companion_cover)

    # Topic taxonomy symlinks
    topic_dir_map = {
        "ai_agent_architecture": "AI-Agents",
        "machine_learning_llm": "AI-Agents",
        "passive_income_business": "Passive-Income",
        "technical_programming": "Programming"
    }
    topic_sub = topic_dir_map.get(triage["primary_domain"])
    if topic_sub:
        topic_root = os.path.join(library_dir, "by-topic", topic_sub)
        os.makedirs(topic_root, exist_ok=True)
        symlink_path = os.path.join(topic_root, canonical_filename)
        try:
            if os.path.islink(symlink_path) or os.path.exists(symlink_path):
                os.remove(symlink_path)
            os.symlink(dest_file, symlink_path)
            log(f"Symlinked into {topic_root}")
        except Exception as e:
            log(f"Symlink creation failed: {e}", level="WARN")

    # Stage 4: Brain-Service RAG Ingestion
    rag_ingested = False
    if triage["is_ai_or_passive_income"] and triage["brain_service_ingest_priority"] != "skip_general_library_only":
        os.makedirs(brain_inbox_dir, exist_ok=True)
        inbox_dest = os.path.join(brain_inbox_dir, canonical_filename)
        try:
            if not os.path.exists(inbox_dest):
                try:
                    os.link(dest_file, inbox_dest)  # Hard link if on same filesystem
                except OSError:
                    shutil.copy2(dest_file, inbox_dest)
            # Trigger API
            success, info = dispatch_brain_service_ingest(dest_file)
            rag_ingested = success
        except Exception as e:
            log(f"RAG inbox dispatch failed: {e}", level="WARN")

        # Also link to ~/Notes/inbox if ~/Notes exists
        notes_inbox = os.path.expanduser("~/Notes/inbox")
        if os.path.isdir(os.path.expanduser("~/Notes")) and brain_inbox_dir != notes_inbox:
            try:
                os.makedirs(notes_inbox, exist_ok=True)
                notes_dest = os.path.join(notes_inbox, canonical_filename)
                if not os.path.exists(notes_dest):
                    try:
                        os.link(dest_file, notes_dest)
                    except OSError:
                        shutil.copy2(dest_file, notes_dest)
            except Exception:
                pass

    # Save receipt
    with open(receipt_path, "w", encoding="utf-8") as rf:
        json.dump({
            "canonical_filename": canonical_filename,
            "metadata": meta,
            "triage": triage,
            "cover_extracted": has_cover,
            "rag_ingested": rag_ingested,
            "timestamp": datetime.datetime.now().isoformat()
        }, rf, indent=2)

    return {
        "status": "purified",
        "canonical_file": dest_file,
        "author": author,
        "title": title,
        "cover": has_cover,
        "triage": triage,
        "rag_ingested": rag_ingested
    }


def run_purification_sweep(source_dir="/data/vault/raw-inbox",
                           library_dir="/data/vault/library",
                           quarantine_dir="/data/vault/quarantine",
                           brain_inbox_dir="/var/lib/brain-service/inbox",
                           dry_run=False):
    """Run full sweep over raw source directory."""
    if not os.path.exists(source_dir):
        log(f"Source directory does not exist: {source_dir}", level="WARN")
        return {"processed": 0, "purified": 0, "quarantined": 0, "skipped": 0}

    log(f"Starting purification sweep on {source_dir} (dry_run={dry_run})")
    if not dry_run:
        create_btrfs_snapshot(source_dir)

    os.makedirs(library_dir, exist_ok=True)
    os.makedirs(quarantine_dir, exist_ok=True)
    os.makedirs(brain_inbox_dir, exist_ok=True)

    summary = {"processed": 0, "purified": 0, "quarantined": 0, "skipped": 0, "results": []}

    for root, _, files in os.walk(source_dir):
        if ".snapshots" in root or "quarantine" in root:
            continue
        for f in files:
            file_path = os.path.join(root, f)
            if f.startswith(".") or f.endswith(".json") or f.endswith(".log"):
                summary["skipped"] += 1
                continue

            summary["processed"] += 1
            res = purify_file(file_path, library_dir, quarantine_dir, brain_inbox_dir, dry_run=dry_run)
            if res.get("status") == "purified":
                summary["purified"] += 1
            elif res.get("status") == "quarantined":
                summary["quarantined"] += 1
            summary["results"].append(res)

    log(f"Sweep complete: {summary['processed']} processed, {summary['purified']} purified, {summary['quarantined']} quarantined")
    return summary


def main():
    parser = argparse.ArgumentParser(description="Book Vault Purifier & RAG Ingestion Pipeline")
    parser.add_argument("--source", default="/data/vault/raw-inbox", help="Raw mangled books inbox")
    parser.add_argument("--library", default="/data/vault/library", help="Standardized Calibre library directory")
    parser.add_argument("--quarantine", default="/data/vault/quarantine", help="Quarantine directory for non-books")
    parser.add_argument("--brain-inbox", default="/var/lib/brain-service/inbox", help="Brain-Service ingestion inbox")
    parser.add_argument("--dry-run", action="store_true", help="Inspect without modifying files")
    parser.add_argument("--once", action="store_true", help="Run once and exit")
    parser.add_argument("--watch", action="store_true", help="Continuously watch source directory")
    parser.add_argument("--interval", type=int, default=60, help="Poll interval in seconds for watch mode")

    args = parser.parse_args()

    if args.watch:
        log(f"Starting watcher on {args.source} every {args.interval}s")
        while True:
            run_purification_sweep(args.source, args.library, args.quarantine, args.brain_inbox, dry_run=args.dry_run)
            time.sleep(args.interval)
    else:
        run_purification_sweep(args.source, args.library, args.quarantine, args.brain_inbox, dry_run=args.dry_run)


if __name__ == "__main__":
    main()
