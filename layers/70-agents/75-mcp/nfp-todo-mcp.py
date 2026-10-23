#!/usr/bin/env python3
"""
NFP Shared Multi-Agent Todo System (CLI + MCP Stdio Server)
Canonical file: ~/Notes/EverOS/todo.md (symlinked to ~/Notes/todo.md)

Features:
- Single canonical Markdown file with fenced per-owner sections:
  ## Erik, ## Hermes, ## Pi, ## OpenCode, ## Claude, ## Gemini, ## Ideas
- Exclusive file locking via fcntl.flock (/tmp/nfp-todo.lock)
- Section-scoped write guard:
  * Human ('erik') can write/toggle across all sections and route via @agent tags.
  * AI Agents ('hermes', 'pi', 'opencode', 'claude', 'gemini') can read all sections,
    write/toggle/update ONLY inside their own `## <Agent>` section, and claim tasks
    from `## Erik` that are tagged `@<agent>`.
- Dual interface:
  * CLI (`nfp-todo list|add|toggle|claim|init`)
  * MCP stdio JSON-RPC server (`nfp-todo --mcp [--agent <id>]`)
"""

import argparse
import datetime
import fcntl
import json
import os
import re
import sys
from typing import Any, Dict, List, Optional, Tuple

DEFAULT_VAULT_TODO = os.path.expanduser("~/Notes/EverOS/todo.md")
DEFAULT_LEGACY_TODO = os.path.expanduser("~/Notes/todo.md")
LOCK_PATH = "/tmp/nfp-todo.lock"

# Canonical section registry: slug -> Markdown heading title
CANONICAL_SECTIONS: Dict[str, str] = {
    "erik": "Erik",
    "hermes": "Hermes",
    "pi": "Pi",
    "opencode": "OpenCode",
    "claude": "Claude",
    "gemini": "Gemini",
    "ideas": "Ideas",
}

TAG_TO_SECTION: Dict[str, str] = {
    "@erik": "erik",
    "@me": "erik",
    "@hermes": "hermes",
    "@pi": "pi",
    "@opencode": "opencode",
    "@claude": "claude",
    "@gemini": "gemini",
    "@idea": "ideas",
    "@ideas": "ideas",
}

HEADING_RE = re.compile(r"^#{1,2}\s+(.+?)\s*$")
TASK_RE = re.compile(r"^(\s*)-\s+\[([ xX>~])\]\s+(.+?)\s*$")


def resolve_todo_path() -> str:
    env_path = os.environ.get("TODO_FILE")
    if env_path:
        return os.path.expanduser(env_path)
    return DEFAULT_VAULT_TODO


def normalize_section_slug(raw_heading: str) -> Optional[str]:
    clean = raw_heading.strip().lower()
    # Map legacy '# Tasks' to 'erik'
    if clean in ("tasks", "erik", "inbox", "erik / inbox"):
        return "erik"
    for slug, title in CANONICAL_SECTIONS.items():
        if clean == slug or clean == title.lower():
            return slug
    return None


def default_template() -> str:
    return (
        "# NFP Shared Todo List\n\n"
        "> Shared between Erik and NFP AI Agents. Tag tasks with `@hermes`, `@pi`, `@opencode`, `@claude`, or `@gemini`.\n\n"
        "## Erik\n"
        "- [ ] Review agent progress and daily priorities\n\n"
        "## Hermes\n\n"
        "## Pi\n\n"
        "## OpenCode\n\n"
        "## Claude\n\n"
        "## Gemini\n\n"
        "## Ideas\n"
    )


def ensure_todo_file(todo_path: str) -> None:
    os.makedirs(os.path.dirname(todo_path), exist_ok=True)
    # Migrate existing ~/Notes/todo.md if ~/Notes/EverOS/todo.md does not exist yet
    if (
        todo_path == DEFAULT_VAULT_TODO
        and not os.path.exists(DEFAULT_VAULT_TODO)
        and os.path.exists(DEFAULT_LEGACY_TODO)
        and not os.path.islink(DEFAULT_LEGACY_TODO)
    ):
        with open(DEFAULT_LEGACY_TODO, "r", encoding="utf-8") as src:
            legacy_content = src.read()
        with open(DEFAULT_VAULT_TODO, "w", encoding="utf-8") as dst:
            dst.write(legacy_content)

    if not os.path.exists(todo_path):
        with open(todo_path, "w", encoding="utf-8") as f:
            f.write(default_template())

    # Ensure ~/Notes/todo.md points to ~/Notes/EverOS/todo.md
    if todo_path == DEFAULT_VAULT_TODO:
        os.makedirs(os.path.dirname(DEFAULT_LEGACY_TODO), exist_ok=True)
        if os.path.lexists(DEFAULT_LEGACY_TODO):
            if not os.path.islink(DEFAULT_LEGACY_TODO):
                try:
                    os.replace(DEFAULT_LEGACY_TODO, DEFAULT_LEGACY_TODO + ".bak")
                    os.symlink(DEFAULT_VAULT_TODO, DEFAULT_LEGACY_TODO)
                except OSError:
                    pass
        else:
            try:
                os.symlink(DEFAULT_VAULT_TODO, DEFAULT_LEGACY_TODO)
            except OSError:
                pass


class FileLock:
    def __init__(self, lock_path: str = LOCK_PATH) -> None:
        self.lock_path = lock_path
        self.fd: Optional[int] = None

    def __enter__(self) -> "FileLock":
        self.fd = os.open(self.lock_path, os.O_CREAT | os.O_RDWR, 0o666)
        fcntl.flock(self.fd, fcntl.LOCK_EX)
        return self

    def __exit__(self, exc_type: Any, exc_val: Any, exc_tb: Any) -> None:
        if self.fd is not None:
            try:
                fcntl.flock(self.fd, fcntl.LOCK_UN)
            finally:
                os.close(self.fd)
                self.fd = None


def parse_document(content: str) -> Tuple[List[str], Dict[str, List[Dict[str, Any]]]]:
    """
    Parse markdown into preamble lines and a dict mapping canonical section slugs
    to lists of task items `{status, text, raw_indent}`.
    """
    sections: Dict[str, List[Dict[str, Any]]] = {k: [] for k in CANONICAL_SECTIONS}
    preamble: List[str] = []
    current_section: Optional[str] = None

    for raw_line in content.splitlines():
        m_head = HEADING_RE.match(raw_line)
        if m_head:
            heading_text = m_head.group(1)
            slug = normalize_section_slug(heading_text)
            if slug is not None:
                current_section = slug
                continue
            elif current_section is None:
                preamble.append(raw_line)
                continue

        if current_section is None:
            if raw_line.strip():
                preamble.append(raw_line)
            continue

        m_task = TASK_RE.match(raw_line)
        if m_task:
            indent, status_ch, text = m_task.group(1), m_task.group(2), m_task.group(3)
            sections[current_section].append({
                "status": "x" if status_ch in ("x", "X") else status_ch,
                "text": text.strip(),
                "indent": indent,
            })

    if not preamble:
        preamble = [
            "# NFP Shared Todo List",
            "",
            "> Shared between Erik and NFP AI Agents. Tag tasks with `@hermes`, `@pi`, `@opencode`, `@claude`, or `@gemini`.",
        ]
    return preamble, sections


def render_document(preamble: List[str], sections: Dict[str, List[Dict[str, Any]]]) -> str:
    lines: List[str] = list(preamble)
    if lines and lines[-1] != "":
        lines.append("")

    for slug, title in CANONICAL_SECTIONS.items():
        lines.append(f"## {title}")
        items = sections.get(slug, [])
        for item in items:
            indent = item.get("indent", "")
            status = item.get("status", " ")
            text = item.get("text", "").strip()
            lines.append(f"{indent}- [{status}] {text}")
        lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def check_write_permission(caller_agent: str, target_section: str) -> Tuple[bool, str]:
    """
    Enforce section-scoped write guard:
    - 'erik' (human / rofi keybind) can modify any section.
    - An AI agent ('hermes', 'pi', 'opencode', 'claude', 'gemini') can ONLY modify
      its own matching section (and 'ideas' if adding an idea).
    """
    caller = caller_agent.strip().lower()
    target = target_section.strip().lower()
    if caller in ("erik", "human", "user", "t0psh31f", "root"):
        return True, "ok"
    if caller == target:
        return True, "ok"
    return (
        False,
        f"Write guard violation: agent '{caller}' is only permitted to modify section '## {CANONICAL_SECTIONS.get(caller, caller)}' (attempted '## {CANONICAL_SECTIONS.get(target, target)}'). Use 'todo_claim' to claim a task tagged @{caller} from ## Erik.",
    )


def extract_section_tag(raw_text: str, default_section: str) -> Tuple[str, str]:
    """
    If raw_text starts with `@hermes `, `@pi `, etc. (or `add:`), route to that section.
    """
    text = raw_text.strip()
    if text.lower().startswith("add:"):
        text = text[4:].strip()
    elif text.startswith("+ "):
        text = text[2:].strip()

    parts = text.split(None, 1)
    if parts:
        first_lower = parts[0].lower()
        if first_lower in TAG_TO_SECTION and len(parts) > 1:
            return TAG_TO_SECTION[first_lower], parts[1].strip()
    return default_section, text


def op_list(
    todo_path: str,
    section_filter: Optional[str] = None,
    status_filter: Optional[str] = None,
) -> Dict[str, Any]:
    with FileLock():
        ensure_todo_file(todo_path)
        with open(todo_path, "r", encoding="utf-8") as f:
            _, sections = parse_document(f.read())

    out_sections: Dict[str, List[Dict[str, Any]]] = {}
    flat_tasks: List[Dict[str, Any]] = []

    for slug, items in sections.items():
        if section_filter and slug != section_filter.lower():
            continue
        filtered_items = []
        for idx, it in enumerate(items):
            is_done = it["status"] == "x"
            if status_filter == "open" and is_done:
                continue
            if status_filter == "done" and not is_done:
                continue
            entry = {
                "section": slug,
                "section_title": CANONICAL_SECTIONS[slug],
                "index": idx,
                "status": it["status"],
                "done": is_done,
                "text": it["text"],
            }
            filtered_items.append(entry)
            flat_tasks.append(entry)
        out_sections[slug] = filtered_items

    return {
        "status": "ok",
        "file": todo_path,
        "count": len(flat_tasks),
        "tasks": flat_tasks,
        "sections": out_sections,
    }


def op_add(
    todo_path: str,
    raw_text: str,
    caller_agent: str = "erik",
    explicit_section: Optional[str] = None,
) -> Dict[str, Any]:
    caller = caller_agent.strip().lower()
    default_sec = explicit_section.lower() if explicit_section else (caller if caller in CANONICAL_SECTIONS else "erik")
    target_sec, clean_text = extract_section_tag(raw_text, default_sec)
    if explicit_section:
        target_sec = explicit_section.lower()

    if target_sec not in CANONICAL_SECTIONS:
        return {"status": "error", "error": f"Unknown section '{target_sec}'. Valid: {list(CANONICAL_SECTIONS.keys())}"}

    allowed, reason = check_write_permission(caller, target_sec)
    if not allowed:
        return {"status": "error", "error": reason}

    if not clean_text:
        return {"status": "error", "error": "Task text cannot be empty."}

    with FileLock():
        ensure_todo_file(todo_path)
        with open(todo_path, "r", encoding="utf-8") as f:
            preamble, sections = parse_document(f.read())

        sections[target_sec].append({
            "status": " ",
            "text": clean_text,
            "indent": "",
        })
        rendered = render_document(preamble, sections)
        with open(todo_path, "w", encoding="utf-8") as f:
            f.write(rendered)

    return {
        "status": "ok",
        "action": "added",
        "caller": caller,
        "section": target_sec,
        "section_title": CANONICAL_SECTIONS[target_sec],
        "text": clean_text,
    }


def op_toggle(
    todo_path: str,
    target_query: str,
    caller_agent: str = "erik",
    explicit_section: Optional[str] = None,
    force_state: Optional[str] = None,
) -> Dict[str, Any]:
    caller = caller_agent.strip().lower()
    with FileLock():
        ensure_todo_file(todo_path)
        with open(todo_path, "r", encoding="utf-8") as f:
            preamble, sections = parse_document(f.read())

        search_Order = (
            [explicit_section.lower()]
            if explicit_section and explicit_section.lower() in CANONICAL_SECTIONS
            else ([caller] if caller in CANONICAL_SECTIONS and caller != "erik" else list(CANONICAL_SECTIONS.keys()))
        )

        matched_sec: Optional[str] = None
        matched_item: Optional[Dict[str, Any]] = None
        q_clean = target_query.strip()

        for sec in search_Order:
            for item in sections.get(sec, []):
                if item["text"] == q_clean or q_clean.lower() in item["text"].lower():
                    matched_sec = sec
                    matched_item = item
                    break
            if matched_item:
                break

        if not matched_sec or not matched_item:
            return {"status": "error", "error": f"Task matching '{target_query}' not found in permitted sections."}

        allowed, reason = check_write_permission(caller, matched_sec)
        if not allowed:
            return {"status": "error", "error": reason}

        if force_state is not None:
            new_status = force_state
        else:
            new_status = " " if matched_item["status"] == "x" else "x"
        matched_item["status"] = new_status

        rendered = render_document(preamble, sections)
        with open(todo_path, "w", encoding="utf-8") as f:
            f.write(rendered)

    return {
        "status": "ok",
        "action": "toggled",
        "caller": caller,
        "section": matched_sec,
        "section_title": CANONICAL_SECTIONS[matched_sec],
        "new_status": new_status,
        "done": new_status == "x",
        "text": matched_item["text"],
    }


def op_claim(
    todo_path: str,
    target_query: str,
    caller_agent: str,
) -> Dict[str, Any]:
    """
    Allow an AI agent (`hermes`, `pi`, `opencode`, `claude`, `gemini`) to claim an open task
    from `## Erik` (especially one tagged `@<agent>`) and copy it into `## <Agent>`.
    """
    caller = caller_agent.strip().lower()
    if caller not in CANONICAL_SECTIONS or caller in ("erik", "ideas"):
        return {"status": "error", "error": f"Agent '{caller}' cannot claim tasks into a dedicated agent section."}

    with FileLock():
        ensure_todo_file(todo_path)
        with open(todo_path, "r", encoding="utf-8") as f:
            preamble, sections = parse_document(f.read())

        matched_item: Optional[Dict[str, Any]] = None
        q_clean = target_query.strip().lower()
        for item in sections["erik"]:
            if item["status"] != "x" and (q_clean in item["text"].lower()):
                matched_item = item
                break

        if not matched_item:
            return {"status": "error", "error": f"Open task matching '{target_query}' not found in ## Erik."}

        orig_text = matched_item["text"]
        matched_item["status"] = ">"
        if f"(claimed by @{caller})" not in orig_text:
            matched_item["text"] = f"{orig_text} (claimed by @{caller})"

        sections[caller].append({
            "status": " ",
            "text": orig_text,
            "indent": "",
        })

        rendered = render_document(preamble, sections)
        with open(todo_path, "w", encoding="utf-8") as f:
            f.write(rendered)

    return {
        "status": "ok",
        "action": "claimed",
        "agent": caller,
        "section": caller,
        "text": orig_text,
    }


def format_rofi_lines(todo_path: str, section_filter: Optional[str] = None) -> str:
    data = op_list(todo_path, section_filter=section_filter)
    lines: List[str] = []
    for t in data["tasks"]:
        mark = "✓" if t["done"] else ("▶" if t["status"] == ">" else "☐")
        sec_badge = f"[{t['section_title']}]"
        lines.append(f"{mark} {sec_badge:<10} {t['text']}")
    return "\n".join(lines)


# ── MCP Stdio JSON-RPC 2.0 Server ─────────────────────────────────────────
def detect_default_agent() -> str:
    for env_k in ("NFP_AGENT_ID", "AGENT_NAME", "MCP_CLIENT_NAME"):
        if os.environ.get(env_k):
            val = os.environ[env_k].strip().lower()
            if val in CANONICAL_SECTIONS:
                return val
    return "hermes"


def run_mcp_stdio(todo_path: str, default_agent: str) -> None:
    tools = [
        {
            "name": "todo_list",
            "description": "Read the shared NFP Todo list across Erik and all AI agent sections (## Erik, ## Hermes, ## Pi, ## OpenCode, ## Claude, ## Gemini, ## Ideas).",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "section": {
                        "type": "string",
                        "description": "Optional section slug filter: erik, hermes, pi, opencode, claude, gemini, ideas",
                    },
                    "status": {
                        "type": "string",
                        "enum": ["all", "open", "done"],
                        "description": "Filter by task completion status (default: all)",
                    },
                },
            },
        },
        {
            "name": "todo_add",
            "description": "Add a task to your own agent section in the shared NFP Todo list. Write guard enforces that each AI agent only writes to its own `## <Agent>` section.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "text": {"type": "string", "description": "Task description to add"},
                    "agent": {
                        "type": "string",
                        "description": "Your agent identity (hermes, pi, opencode, claude, gemini, or erik)",
                    },
                    "section": {
                        "type": "string",
                        "description": "Target section (must match your agent identity unless caller is erik)",
                    },
                },
                "required": ["text"],
            },
        },
        {
            "name": "todo_complete",
            "description": "Mark a task completed ([x]) or reopen ([ ]) inside your own agent section.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "query": {"type": "string", "description": "Exact or substring match of the task text"},
                    "agent": {
                        "type": "string",
                        "description": "Your agent identity (hermes, pi, opencode, claude, gemini, or erik)",
                    },
                    "done": {"type": "boolean", "description": "True to mark [x], False to reopen [ ] (default: True)"},
                },
                "required": ["query"],
            },
        },
        {
            "name": "todo_claim",
            "description": "Claim an open task from `## Erik` into your own `## <Agent>` section.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "query": {"type": "string", "description": "Task text substring in ## Erik to claim"},
                    "agent": {
                        "type": "string",
                        "description": "Your agent identity (hermes, pi, opencode, claude, gemini)",
                    },
                },
                "required": ["query", "agent"],
            },
        },
    ]

    for raw_line in sys.stdin:
        line = raw_line.strip()
        if not line:
            continue
        try:
            req = json.loads(line)
        except Exception:
            continue

        req_id = req.get("id")
        method = req.get("method", "")
        params = req.get("params") or {}

        if method == "initialize":
            resp = {
                "jsonrpc": "2.0",
                "id": req_id,
                "result": {
                    "protocolVersion": "2024-11-05",
                    "capabilities": {"tools": {}},
                    "serverInfo": {"name": "nfp-todo-mcp", "version": "1.0.0"},
                },
            }
            sys.stdout.write(json.dumps(resp) + "\n")
            sys.stdout.flush()
        elif method == "notifications/initialized":
            continue
        elif method == "tools/list":
            resp = {"jsonrpc": "2.0", "id": req_id, "result": {"tools": tools}}
            sys.stdout.write(json.dumps(resp) + "\n")
            sys.stdout.flush()
        elif method == "tools/call":
            tname = params.get("name", "")
            args = params.get("arguments") or {}
            caller = str(args.get("agent") or default_agent).strip().lower()

            if tname == "todo_list":
                sec = args.get("section")
                st = args.get("status")
                if st == "all":
                    st = None
                res = op_list(todo_path, section_filter=sec, status_filter=st)
            elif tname == "todo_add":
                res = op_add(
                    todo_path,
                    raw_text=str(args.get("text", "")),
                    caller_agent=caller,
                    explicit_section=args.get("section"),
                )
            elif tname == "todo_complete":
                done_flag = args.get("done", True)
                res = op_toggle(
                    todo_path,
                    target_query=str(args.get("query", "")),
                    caller_agent=caller,
                    explicit_section=args.get("section"),
                    force_state="x" if done_flag else " ",
                )
            elif tname == "todo_claim":
                res = op_claim(
                    todo_path,
                    target_query=str(args.get("query", "")),
                    caller_agent=caller,
                )
            else:
                res = {"status": "error", "error": f"Unknown tool: {tname}"}

            is_err = res.get("status") == "error"
            resp = {
                "jsonrpc": "2.0",
                "id": req_id,
                "result": {
                    "content": [{"type": "text", "text": json.dumps(res, indent=2)}],
                    "isError": is_err,
                },
            }
            sys.stdout.write(json.dumps(resp) + "\n")
            sys.stdout.flush()
        elif req_id is not None:
            resp = {
                "jsonrpc": "2.0",
                "id": req_id,
                "error": {"code": -32601, "message": f"Method not found: {method}"},
            }
            sys.stdout.write(json.dumps(resp) + "\n")
            sys.stdout.flush()


def main() -> None:
    parser = argparse.ArgumentParser(description="NFP Shared Multi-Agent Todo CLI & MCP Server")
    parser.add_argument("--file", default=None, help="Path to todo.md (default: ~/Notes/EverOS/todo.md)")
    parser.add_argument("--agent", default=None, help="Caller identity (erik, hermes, pi, opencode, claude, gemini)")
    parser.add_argument("--mcp", action="store_true", help="Run as MCP stdio JSON-RPC server")

    subparsers = parser.add_subparsers(dest="subcommand")

    p_init = subparsers.add_parser("init", help="Ensure canonical todo file and symlinks exist")

    p_list = subparsers.add_parser("list", help="List tasks")
    p_list.add_argument("--section", default=None, help="Filter by section")
    p_list.add_argument("--status", choices=["all", "open", "done"], default="all")
    p_list.add_argument("--rofi", action="store_true", help="Output formatted lines for Rofi")
    p_list.add_argument("--json", action="store_true", help="Output JSON")

    p_add = subparsers.add_parser("add", help="Add a task (supports @hermes, @pi, @opencode, @claude, @gemini tags)")
    p_add.add_argument("text", nargs="+", help="Task text")
    p_add.add_argument("--section", default=None, help="Explicit section override")

    p_toggle = subparsers.add_parser("toggle", help="Toggle completion of a task")
    p_toggle.add_argument("query", nargs="+", help="Task text or substring")
    p_toggle.add_argument("--section", default=None, help="Section filter")

    p_claim = subparsers.add_parser("claim", help="Claim an open task from ## Erik into an agent section")
    p_claim.add_argument("query", nargs="+", help="Task text substring in ## Erik")

    args = parser.parse_args()
    todo_path = os.path.expanduser(args.file) if args.file else resolve_todo_path()

    if args.mcp:
        caller = args.agent or detect_default_agent()
        run_mcp_stdio(todo_path, caller)
        return

    caller = args.agent or os.environ.get("NFP_AGENT_ID") or "erik"

    if args.subcommand == "init":
        with FileLock():
            ensure_todo_file(todo_path)
        print(json.dumps({"status": "ok", "file": todo_path}))
        return

    if args.subcommand in (None, "list"):
        rofi_mode = getattr(args, "rofi", False)
        sec = getattr(args, "section", None)
        st = getattr(args, "status", "all")
        if rofi_mode:
            print(format_rofi_lines(todo_path, section_filter=sec))
            return
        res = op_list(todo_path, section_filter=sec, status_filter=None if st == "all" else st)
        if getattr(args, "json", False):
            print(json.dumps(res, indent=2))
        else:
            for slug, items in res["sections"].items():
                print(f"## {CANONICAL_SECTIONS[slug]}")
                for it in items:
                    print(f"  - [{it['status']}] {it['text']}")
                print()
        return

    if args.subcommand == "add":
        raw_text = " ".join(args.text)
        res = op_add(todo_path, raw_text=raw_text, caller_agent=caller, explicit_section=args.section)
        print(json.dumps(res))
        sys.exit(0 if res.get("status") == "ok" else 1)

    if args.subcommand == "toggle":
        q = " ".join(args.query)
        res = op_toggle(todo_path, target_query=q, caller_agent=caller, explicit_section=args.section)
        print(json.dumps(res))
        sys.exit(0 if res.get("status") == "ok" else 1)

    if args.subcommand == "claim":
        q = " ".join(args.query)
        res = op_claim(todo_path, target_query=q, caller_agent=caller)
        print(json.dumps(res))
        sys.exit(0 if res.get("status") == "ok" else 1)


if __name__ == "__main__":
    main()
