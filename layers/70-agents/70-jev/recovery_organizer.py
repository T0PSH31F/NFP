#!/usr/bin/env python3
"""Post-recovery file organizer, PII classifier, and canary-protected vault.

Non-destructive pipeline for PhotoRec / TestDisk output (e.g. Recovered_Hitachi_2TB):
  Tier 0: Deterministic magic-byte, filename, regex PII/secret detection, & Jev (:20130) scoring.
  Tier 1: Local Ollama SLM (:11434) classification, metadata extraction, & clean renaming.
  Stage 2: Non-destructive copy into structured folders + exiftool/PDF metadata tagging.
  Stage 3: Sensitive PII files archived into AES-256 encrypted ZIP with NFP canary tokens
           and live access/HTTP beacon alerting via glados-alert.sh.
"""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import http.server
import json
import mimetypes
import os
import re
import secrets
import shutil
import socketserver
import subprocess
import sys
import threading
import time
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any

JEV_ENGINE_URL = os.environ.get("JEV_ENGINE_URL", "http://127.0.0.1:20130")
OLLAMA_URL = os.environ.get("OLLAMA_URL", "http://127.0.0.1:11434")
OLLAMA_MODEL = os.environ.get("OLLAMA_MODEL", "huihui_ai/qwen2.5-abliterate:7b")
CANARY_PORT = int(os.environ.get("NFP_CANARY_PORT", "20139"))
GLADOS_ALERT_BIN = os.environ.get("GLADOS_ALERT_BIN", "/home/t0psh31f/.local/bin/glados-alert.sh")

PII_REGEXES: list[tuple[str, re.Pattern[str]]] = [
    ("ssn", re.compile(r"\b(?!000|666|9\d\d)\d{3}-(?!00)\d{2}-(?!0000)\d{4}\b")),
    ("private_key", re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH |PGP )?PRIVATE KEY-----")),
    ("credit_card", re.compile(r"\b(?:4\d{3}|5[1-5]\d{2}|3[47]\d{2}|6011)[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{3,4}\b")),
    ("seed_phrase", re.compile(r"\b(?:seed phrase|recovery phrase|mnemonic|bip39|12 words|24 words)\b", re.I)),
    ("tax_id", re.compile(r"\b(?:form\s*(?:w-?2|1099|1040)|social security|driver'?s license|passport no\.?|routing number|account number)\b", re.I)),
]

SENSITIVE_EXTENSIONS = {".kdbx", ".wallet", ".key", ".pem", ".p12", ".pfx", ".ovpn"}
BOOK_EXTENSIONS = {".epub", ".mobi", ".azw3", ".azw", ".kfx", ".djvu", ".fb2", ".cbz", ".cbr"}

CATEGORY_DIRS = {
    "Books": "Books",
    "Financial": "Financial",
    "Legal": "Legal",
    "Technical": "Technical",
    "Code": "Code",
    "Databases": "Databases",
    "Archives": "Archives",
    "Media": "Media",
    "Documents": "Documents",
    "Personal_PII": "PII_Staged",
}


def log(msg: str, level: str = "INFO") -> None:
    ts = dt.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{ts}] [{level}] {msg}", flush=True)


def trigger_glados_alert(title: str, body: str, speech: str, urgency: str = "critical") -> None:
    if os.path.isfile(GLADOS_ALERT_BIN) and os.access(GLADOS_ALERT_BIN, os.X_OK):
        try:
            subprocess.Popen(
                [GLADOS_ALERT_BIN, "--urgency", urgency, "--speech", speech, title, body],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            return
        except Exception as exc:
            log(f"Failed executing glados-alert.sh: {exc}", "WARN")
    log(f"ALERT [{urgency}] {title}: {body}", "WARN")


def extract_text_snippet(path: Path, max_bytes: int = 8192) -> str:
    ext = path.suffix.lower()
    if ext == ".pdf":
        for tool in ("pdftotext",):
            if shutil.which(tool):
                try:
                    res = subprocess.run(
                        [tool, "-f", "1", "-l", "3", str(path), "-"],
                        stdout=subprocess.PIPE,
                        stderr=subprocess.DEVNULL,
                        text=True,
                        timeout=6,
                    )
                    if res.stdout:
                        return " ".join(res.stdout.split())[:2000]
                except Exception:
                    pass
    try:
        raw = path.read_bytes()[:max_bytes]
        text = raw.decode("utf-8", errors="ignore")
        return " ".join(text.split())[:2000]
    except Exception:
        return ""


def detect_pii(path: Path, snippet: str) -> list[str]:
    hits: list[str] = []
    ext = path.suffix.lower()
    name_low = path.name.lower()
    if ext in SENSITIVE_EXTENSIONS or any(k in name_low for k in ("wallet", "keepass", "seed", "passport", "ssn", "tax", "w2", "1040")):
        hits.append(f"sensitive_file:{ext or name_low}")
    for label, rx in PII_REGEXES:
        if rx.search(snippet):
            hits.append(label)
    return hits


def query_jev_category(state_text: str) -> dict[str, Any] | None:
    payload = json.dumps({
        "state": state_text,
        "questions": [{
            "id": "target_vault",
            "type": "enum",
            "options": [
                "financial_records",
                "code_projects",
                "media_audiobooks",
                "personal_documents",
                "ephemeral_trash",
            ],
        }],
    }).encode("utf-8")
    try:
        req = urllib.request.Request(
            f"{JEV_ENGINE_URL.rstrip('/')}/v1/decide",
            data=payload,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        with urllib.request.urlopen(req, timeout=2.5) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except Exception:
        return None


def query_ollama_classify(path: Path, snippet: str) -> dict[str, Any] | None:
    if not snippet.strip():
        return None
    prompt = (
        "Classify this recovered file strictly as JSON with keys: "
        'category (one of: Books, Financial, Legal, Technical, Code, Documents, Personal_PII), '
        'title (short clean title), author (author or Unknown), year (YYYY or ""), '
        'is_pii (boolean true only if personal ID, tax return, SSN, medical, bank account, or credentials). '
        f"Filename: {path.name}\nExtension: {path.suffix}\nSnippet:\n{snippet[:1200]}\nJSON:"
    )
    payload = json.dumps({
        "model": OLLAMA_MODEL,
        "prompt": prompt,
        "stream": False,
        "format": "json",
        "options": {"temperature": 0.1, "num_predict": 180},
    }).encode("utf-8")
    try:
        req = urllib.request.Request(
            f"{OLLAMA_URL.rstrip('/')}/api/generate",
            data=payload,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        with urllib.request.urlopen(req, timeout=20) as resp:
            outer = json.loads(resp.read().decode("utf-8"))
            return json.loads(outer.get("response", "{}"))
    except Exception:
        return None


def sanitize_filename(name: str, fallback: str) -> str:
    clean = re.sub(r'[\\/:*?"<>|\r\n]+', " ", name or "").strip(" .")
    clean = re.sub(r"\s+", " ", clean)
    return (clean[:110] if clean else fallback)


def stamp_metadata(dest: Path, title: str, author: str, category: str) -> None:
    if not shutil.which("exiftool"):
        return
    if dest.suffix.lower() not in {".pdf", ".jpg", ".jpeg", ".png", ".tiff", ".docx", ".epub"}:
        return
    args = ["exiftool", "-overwrite_original", "-q", f"-Subject={category}"]
    if title:
        args.append(f"-Title={title}")
    if author and author != "Unknown":
        args.append(f"-Author={author}")
    args.append(str(dest))
    try:
        subprocess.run(args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=5)
    except Exception:
        pass


def ensure_vault_password(pass_file: Path) -> str:
    if pass_file.exists():
        pw = pass_file.read_text(encoding="utf-8").strip()
        if pw:
            return pw
    pass_file.parent.mkdir(parents=True, exist_ok=True)
    pw = secrets.token_urlsafe(24)
    fd = os.open(pass_file, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        f.write(pw + "\n")
    log(f"Generated new AES-256 PII vault password file at {pass_file} (mode 0600)")
    return pw


def write_canary_files(vault_dir: Path, canary_token: str, canary_host: str) -> list[Path]:
    vault_dir.mkdir(parents=True, exist_ok=True)
    beacon_url = f"http://{canary_host}:{CANARY_PORT}/canary/{canary_token}"
    html_lure = vault_dir / "00_RECOVERY_INDEX_OPEN_ME.html"
    txt_lure = vault_dir / "_ACCESS_NOTICE.txt"
    html_lure.write_text(
        f"""<!doctype html>
<html><head><meta charset="utf-8"><title>Vault Index</title></head>
<body>
<h3>Encrypted Archive Manifest</h3>
<p>Vault Token: <code>{canary_token}</code></p>
<img src="{beacon_url}/pixel.png" width="1" height="1" alt="" />
<script>fetch("{beacon_url}/open").catch(()=>{{}});</script>
</body></html>
""",
        encoding="utf-8",
    )
    txt_lure.write_text(
        f"NFP ENCRYPTED PII ARCHIVE\nCanary Verification URL: {beacon_url}\nToken: {canary_token}\n",
        encoding="utf-8",
    )
    return [html_lure, txt_lure]


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        while chunk := f.read(1024 * 1024):
            h.update(chunk)
    return h.hexdigest()


def organize(args: argparse.Namespace) -> int:
    src = Path(args.source)
    out_root = Path(args.dest)
    vault_dir = Path(args.vault_dir)
    pass_file = Path(args.password_file)
    state_file = out_root / ".organizer_state.json"

    if not src.exists():
        log(f"Source directory does not exist: {src}", "ERROR")
        return 1

    out_root.mkdir(parents=True, exist_ok=True)
    seen_hashes: set[str] = set()
    if state_file.exists():
        try:
            seen_hashes = set(json.loads(state_file.read_text(encoding="utf-8")).get("seen_hashes", []))
        except Exception:
            pass

    now = time.time()
    pii_staged: list[Path] = []
    stats = {"scanned": 0, "skipped_active": 0, "skipped_dup": 0, "organized": 0, "pii": 0}
    manifest_entries: list[dict[str, Any]] = []

    for root_str, _, files in os.walk(src):
        for fname in sorted(files):
            if args.limit and stats["scanned"] >= args.limit:
                break
            fpath = Path(root_str) / fname
            try:
                st = fpath.stat()
            except OSError:
                continue

            # Skip files modified within the last 120s while photorec is still writing
            if now - st.st_mtime < args.min_age_seconds:
                stats["skipped_active"] += 1
                continue
            if st.st_size < 1024:
                continue

            stats["scanned"] += 1
            digest = sha256_file(fpath)
            if digest in seen_hashes:
                stats["skipped_dup"] += 1
                continue

            ext = fpath.suffix.lower()
            snippet = extract_text_snippet(fpath)
            pii_hits = detect_pii(fpath, snippet)

            category = "Documents"
            title = fpath.stem
            author = "Unknown"
            year = ""

            if pii_hits:
                category = "Personal_PII"
            elif ext in BOOK_EXTENSIONS:
                category = "Books"
            elif ext in {".sqlite", ".db", ".sql"}:
                category = "Databases"
            elif ext in {".zip", ".7z", ".tar", ".gz", ".rar"}:
                category = "Archives"
            elif ext in {".jpg", ".jpeg", ".png", ".mp4", ".mkv", ".mp3", ".flac", ".m4b"}:
                category = "Media"
            elif ext in {".py", ".rs", ".nix", ".sh", ".js", ".ts", ".c", ".cpp"}:
                category = "Code"
            else:
                # Tier 0 Jev Engine classification first (zero LLM cost)
                jev_res = query_jev_category(f"Path: {fpath}\nExt: {ext}\nHeader: {snippet[:400]}")
                if jev_res and not args.no_ollama and ext in {".pdf", ".txt", ".doc", ".docx"}:
                    slm = query_ollama_classify(fpath, snippet)
                    if slm:
                        if slm.get("is_pii"):
                            category = "Personal_PII"
                            pii_hits.append("slm_pii")
                        elif slm.get("category") in CATEGORY_DIRS:
                            category = slm["category"]
                        title = str(slm.get("title") or title)
                        author = str(slm.get("author") or "Unknown")
                        year = str(slm.get("year") or "")
                elif jev_res:
                    v = (jev_res.get("answers") or {}).get("target_vault", {}).get("choice", "")
                    if v == "financial_records":
                        category = "Financial"
                    elif v == "code_projects":
                        category = "Code"
                    elif v == "personal_documents":
                        category = "Legal"

            clean_base = sanitize_filename(
                f"{year + '_' if year else ''}{author + ' - ' if author and author != 'Unknown' else ''}{title}",
                fpath.stem,
            )
            dest_sub = CATEGORY_DIRS.get(category, "Documents")
            dest_dir = (vault_dir / "_staged_pii") if category == "Personal_PII" else (out_root / dest_sub)
            dest_path = dest_dir / f"{clean_base}_{digest[:8]}{ext}"

            manifest_entries.append({
                "src": str(fpath),
                "dest": str(dest_path),
                "category": category,
                "pii": pii_hits,
                "sha256": digest,
            })

            if not args.dry_run:
                dest_dir.mkdir(parents=True, exist_ok=True)
                shutil.copy2(fpath, dest_path)
                if category == "Personal_PII":
                    pii_staged.append(dest_path)
                    stats["pii"] += 1
                else:
                    stamp_metadata(dest_path, title, author, category)
                    stats["organized"] += 1
                seen_hashes.add(digest)

    if not args.dry_run and pii_staged:
        vault_zip = vault_dir / "personal_pii_vault.zip"
        pw = ensure_vault_password(pass_file)
        canary_token = hashlib.sha256(f"{vault_zip}:{time.time()}".encode()).hexdigest()[:16]
        lures = write_canary_files(vault_dir, canary_token, args.canary_host)
        (vault_dir / ".canary_token").write_text(canary_token + "\n", encoding="utf-8")

        cmd = ["7z", "a", "-tzip", "-mem=AES256", f"-p{pw}", str(vault_zip)] + [str(p) for p in (pii_staged + lures)]
        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        if res.returncode == 0:
            os.chmod(vault_zip, 0o600)
            for staged in pii_staged:
                staged.unlink(missing_ok=True)
            trigger_glados_alert(
                "Aperture PII Recovery Vault Sealed",
                f"Archived {len(pii_staged)} sensitive files into {vault_zip} with canary token {canary_token}.",
                f"Test Subject. {len(pii_staged)} recovered personal files have been sealed in the encrypted vault with an active canary trap.",
                urgency="normal",
            )
        else:
            log(f"7z archive error: {res.stderr}", "ERROR")

    if not args.dry_run:
        state_file.write_text(json.dumps({"seen_hashes": sorted(seen_hashes), "stats": stats}, indent=2), encoding="utf-8")
    manifest_file = out_root / "organization_manifest.json"
    manifest_file.write_text(json.dumps({"stats": stats, "sample": manifest_entries[:200]}, indent=2), encoding="utf-8")
    log(f"Summary: {json.dumps(stats)} -> manifest at {manifest_file}")
    return 0


def run_canary_daemon(vault_dir: Path, port: int) -> int:
    vault_dir.mkdir(parents=True, exist_ok=True)

    class CanaryHandler(http.server.BaseHTTPRequestHandler):
        def do_GET(self) -> None:
            client = self.client_address[0]
            trigger_glados_alert(
                "APERTURE SECURITY BREACH: CANARY TRIGGERED",
                f"HTTP canary beacon hit from {client} on {self.path}!",
                "Security alert. A canary token from your encrypted vault was just opened.",
                urgency="critical",
            )
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(b"ok\n")

        def log_message(self, format: str, *args: Any) -> None:
            return

    def watch_files() -> None:
        zip_path = vault_dir / "personal_pii_vault.zip"
        last_atime = zip_path.stat().st_atime if zip_path.exists() else None
        if shutil.which("inotifywait"):
            while True:
                proc = subprocess.run(
                    ["inotifywait", "-q", "-e", "open,access,modify,delete", "--format", "%w%f:%e", str(vault_dir)],
                    stdout=subprocess.PIPE,
                    stderr=subprocess.DEVNULL,
                    text=True,
                )
                evt = proc.stdout.strip()
                if evt and (".zip" in evt or "_ACCESS_NOTICE" in evt or "RECOVERY_INDEX" in evt):
                    trigger_glados_alert(
                        "APERTURE PII VAULT ACCESSED",
                        f"Filesystem event detected on protected vault: {evt}",
                        "Attention. Unauthorized or direct access detected on the encrypted P I I vault.",
                        urgency="critical",
                    )
                    time.sleep(5)
        else:
            while True:
                if zip_path.exists():
                    cur_atime = zip_path.stat().st_atime
                    if last_atime is not None and cur_atime > last_atime:
                        trigger_glados_alert(
                            "APERTURE PII VAULT ACCESSED",
                            f"Access timestamp changed on {zip_path}",
                            "Attention. Access detected on the encrypted P I I vault.",
                            urgency="critical",
                        )
                    last_atime = cur_atime
                time.sleep(3)

    t = threading.Thread(target=watch_files, daemon=True)
    t.start()

    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("0.0.0.0", port), CanaryHandler) as httpd:
        log(f"NFP PII Canary Monitor listening on :{port} watching {vault_dir}")
        httpd.serve_forever()
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="NFP Recovery Organizer + PII Canary Vault")
    sub = parser.add_subparsers(dest="cmd", required=True)

    org = sub.add_parser("organize", help="Non-destructively organize recovered files")
    org.add_argument("--source", required=True)
    org.add_argument("--dest", required=True)
    org.add_argument("--vault-dir", required=True)
    org.add_argument("--password-file", default="/persist/secrets/pii_vault.pass")
    org.add_argument("--canary-host", default="luffy.nfp.nix")
    org.add_argument("--min-age-seconds", type=int, default=120)
    org.add_argument("--limit", type=int, default=0)
    org.add_argument("--dry-run", action="store_true")
    org.add_argument("--no-ollama", action="store_true")

    can = sub.add_parser("watch-canary", help="Run PII vault filesystem + HTTP canary alert daemon")
    can.add_argument("--vault-dir", required=True)
    can.add_argument("--port", type=int, default=CANARY_PORT)

    args = parser.parse_args()
    if args.cmd == "organize":
        return organize(args)
    if args.cmd == "watch-canary":
        return run_canary_daemon(Path(args.vault_dir), args.port)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
