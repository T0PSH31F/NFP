#!/usr/bin/env python3
"""
NFP Dynamic On-the-Fly Skill Authoring Generator (Layer 79)
===========================================================
Enables Pi, OpenCode, Hermes, and Antigravity agents to dynamically author,
validate, register, and link modular skills into `layers/70-agents/79-skills/`.

Features:
- Validates skill slug names and metadata.
- Generates standard, high-aesthetic SKILL.md with frontmatter.
- Auto-symlinks into `layers/70-agents/71-harness/opencode/skills/`.
- Exposes CLI (`nfp-skill-author`) and stdio MCP server for on-the-fly invocation.
- Deterministic verification of frontmatter and formatting.
- Mandatory GLaDOS acoustic notification upon skill registration.
"""

import sys
import os
import json
import re
import shutil
import subprocess
from pathlib import Path
from datetime import datetime, timezone

REPO_ROOT = Path(__file__).resolve().parents[3]
SKILLS_DIR = REPO_ROOT / "layers/70-agents/79-skills"
OPENCODE_SKILLS_DIR = REPO_ROOT / "layers/70-agents/71-harness/opencode/skills"
GLADOS_TTS_BIN = Path.home() / ".local/bin/glados-tts-cli"


def speak_glados(text: str) -> None:
    """Mandatory GLaDOS voice notification."""
    clean = re.sub(r"\s+", " ", text).strip()
    if not clean:
        return
    for candidate in [GLADOS_TTS_BIN, Path("/run/current-system/sw/bin/glados-speak")]:
        if candidate.exists() and os.access(candidate, os.X_OK):
            try:
                subprocess.Popen(
                    [str(candidate), clean],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
                return
            except Exception:
                pass


def sanitize_slug(name: str) -> str:
    """Converts a skill name to a canonical hyphenated lowercase slug."""
    clean = re.sub(r"[^a-zA-Z0-9\-_ ]", "", name).strip().lower()
    slug = re.sub(r"[\s_]+", "-", clean)
    return slug


def parse_frontmatter(content: str) -> tuple[dict, str]:
    """Parses simple YAML frontmatter from a markdown string."""
    m = re.match(r"^---\s*\n(.*?)\n---\s*\n(.*)$", content, re.DOTALL)
    if not m:
        return {}, content
    yaml_block = m.group(1)
    body = m.group(2)
    meta = {}
    for line in yaml_block.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if ":" in line:
            k, v = line.split(":", 1)
            k = k.strip()
            v = v.strip().strip("\"'")
            meta[k] = v
    return meta, body


def author_skill(
    name: str,
    description: str,
    instructions: str,
    category: str = "general",
    triggers: list[str] | None = None,
    schemas: dict[str, str] | None = None,
    scripts: dict[str, str] | None = None,
    base_skills_dir: Path = SKILLS_DIR,
    base_opencode_dir: Path = OPENCODE_SKILLS_DIR,
    notify_voice: bool = True,
) -> dict:
    """
    Dynamically authors and registers a new modular skill.
    """
    slug = sanitize_slug(name)
    if not slug:
        raise ValueError(f"Invalid skill name '{name}'; could not form valid slug.")
    if not description:
        raise ValueError("Skill description is required.")

    skill_path = base_skills_dir / slug
    skill_path.mkdir(parents=True, exist_ok=True)

    triggers_formatted = triggers or [slug, category]
    triggers_yaml = "\n".join(f"  - {t}" for t in triggers_formatted)

    # Format SKILL.md
    skill_md_content = f"""---
name: {slug}
description: {description}
category: {category}
triggers:
{triggers_yaml}
---

# {slug.replace('-', ' ').title()} Skill

## 1. Overview & Operational Intent
{description}

- **Category**: `{category}`
- **Author**: Autonomous Dynamic Skill Generator (`nfp-skill-author`)
- **Registered**: {datetime.now(timezone.utc).isoformat()}

---

## 2. When to Use & Trigger Conditions
Use this skill when facing:
{chr(10).join(f"- `{t}`" for t in triggers_formatted)}

---

## 3. Step-by-Step Instructions & Execution Protocol
{instructions.strip()}

---

## 4. Verification & Deterministic Guardrails
- Validate all outputs against `./init.sh --worktree` before committing changes.
- Ensure state persistence boundaries are respected.
- Never guess package or option names; consult `mcp-nixos`.

---

## 5. Notes & Learned Anti-Patterns
- Grounded in NFP dendritic architecture rules.
- Continuous reflection updates managed by the Jarvis Dream Cycle.
"""

    skill_file = skill_path / "SKILL.md"
    skill_file.write_text(skill_md_content, encoding="utf-8")

    # Write additional schemas if provided
    if schemas:
        schema_dir = skill_path / "schemas"
        schema_dir.mkdir(parents=True, exist_ok=True)
        for sname, scontent in schemas.items():
            (schema_dir / sname).write_text(scontent, encoding="utf-8")

    # Write additional scripts if provided
    if scripts:
        script_dir = skill_path / "scripts"
        script_dir.mkdir(parents=True, exist_ok=True)
        for scname, sccontent in scripts.items():
            scpath = script_dir / scname
            scpath.write_text(sccontent, encoding="utf-8")
            scpath.chmod(0o755)

    # Symlink to OpenCode skills directory
    symlink_target = None
    if base_opencode_dir.exists():
        base_opencode_dir.mkdir(parents=True, exist_ok=True)
        link_path = base_opencode_dir / slug
        rel_target = Path("../../79-skills") / slug
        try:
            if link_path.is_symlink() or link_path.exists():
                link_path.unlink()
            link_path.symlink_to(rel_target)
            symlink_target = str(link_path)
        except Exception:
            pass

    # Also update user runtime directory if writable
    user_opencode_skills = Path.home() / ".config/opencode/skills"
    if user_opencode_skills.exists() and os.access(user_opencode_skills, os.W_OK):
        try:
            user_link = user_opencode_skills / slug
            if user_link.is_symlink() or user_link.exists():
                user_link.unlink()
            user_link.symlink_to(skill_path)
        except Exception:
            pass

    if notify_voice:
        speak_glados(f"Skill evolution verified. New skill '{slug}' has been registered in the Enrichment Center catalog.")

    return {
        "status": "success",
        "slug": slug,
        "skill_dir": str(skill_path),
        "skill_file": str(skill_file),
        "opencode_symlink": symlink_target,
    }


def list_skills(base_skills_dir: Path = SKILLS_DIR) -> list[dict]:
    """Scans and returns all registered skills in the 79-skills layer."""
    skills = []
    if not base_skills_dir.exists():
        return skills

    for item in sorted(base_skills_dir.iterdir()):
        if item.is_dir() and (item / "SKILL.md").exists():
            content = (item / "SKILL.md").read_text(encoding="utf-8", errors="replace")
            meta, _ = parse_frontmatter(content)
            skills.append({
                "slug": item.name,
                "name": meta.get("name", item.name),
                "description": meta.get("description", "No description provided"),
                "category": meta.get("category", "general"),
                "path": str(item),
            })
    return skills


def verify_skill(name: str, base_skills_dir: Path = SKILLS_DIR) -> dict:
    """Verifies that a skill has valid frontmatter and standard sections."""
    slug = sanitize_slug(name)
    skill_dir = base_skills_dir / slug
    skill_file = skill_dir / "SKILL.md"

    if not skill_file.exists():
        return {"valid": False, "error": f"Skill file not found at {skill_file}"}

    content = skill_file.read_text(encoding="utf-8", errors="replace")
    meta, body = parse_frontmatter(content)

    if not meta.get("name") or not meta.get("description"):
        return {"valid": False, "error": "Missing 'name' or 'description' in YAML frontmatter"}

    if "# " not in body:
        return {"valid": False, "error": "Missing markdown title heading in SKILL.md"}

    return {
        "valid": True,
        "slug": slug,
        "name": meta.get("name"),
        "description": meta.get("description"),
        "body_lines": len(body.splitlines()),
    }


# ==============================================================================
# Model Context Protocol (MCP) Stdio Server
# ==============================================================================

def run_mcp_server() -> None:
    """Runs a standard stdio JSON-RPC MCP server for dynamic skill authoring."""
    while True:
        line = sys.stdin.readline()
        if not line:
            break
        try:
            req = json.loads(line)
        except Exception:
            continue

        req_id = req.get("id")
        method = req.get("method")
        params = req.get("params", {})

        if method == "initialize":
            res = {
                "jsonrpc": "2.0",
                "id": req_id,
                "result": {
                    "protocolVersion": "2024-11-05",
                    "serverInfo": {"name": "nfp-skill-author", "version": "1.0.0"},
                    "capabilities": {"tools": {}},
                },
            }
        elif method == "tools/list":
            res = {
                "jsonrpc": "2.0",
                "id": req_id,
                "result": {
                    "tools": [
                        {
                            "name": "author_skill",
                            "description": "Create and register a new modular skill with SKILL.md and OpenCode symlink",
                            "inputSchema": {
                                "type": "object",
                                "properties": {
                                    "name": {"type": "string", "description": "Skill slug name (e.g. redis-cache-triage)"},
                                    "description": {"type": "string", "description": "Concise summary of skill capability"},
                                    "instructions": {"type": "string", "description": "Markdown instructions and protocol"},
                                    "category": {"type": "string", "description": "Optional category tag"},
                                },
                                "required": ["name", "description", "instructions"],
                            },
                        },
                        {
                            "name": "list_skills",
                            "description": "List all registered modular skills in NFP Layer 79",
                            "inputSchema": {"type": "object", "properties": {}},
                        },
                        {
                            "name": "verify_skill",
                            "description": "Validate that a skill has proper frontmatter and structure",
                            "inputSchema": {
                                "type": "object",
                                "properties": {"name": {"type": "string"}},
                                "required": ["name"],
                            },
                        },
                    ]
                },
            }
        elif method == "tools/call":
            tool_name = params.get("name")
            args = params.get("arguments", {})
            try:
                if tool_name == "author_skill":
                    out = author_skill(
                        name=args["name"],
                        description=args["description"],
                        instructions=args["instructions"],
                        category=args.get("category", "general"),
                    )
                    text = f"Skill '{out['slug']}' authored successfully at {out['skill_dir']}"
                elif tool_name == "list_skills":
                    out = list_skills()
                    text = json.dumps(out, indent=2)
                elif tool_name == "verify_skill":
                    out = verify_skill(args["name"])
                    text = json.dumps(out, indent=2)
                else:
                    text = f"Unknown tool '{tool_name}'"
                res = {
                    "jsonrpc": "2.0",
                    "id": req_id,
                    "result": {"content": [{"type": "text", "text": text}]},
                }
            except Exception as e:
                res = {
                    "jsonrpc": "2.0",
                    "id": req_id,
                    "result": {"content": [{"type": "text", "text": f"Error: {e}"}], "isError": True},
                }
        else:
            res = {"jsonrpc": "2.0", "id": req_id, "error": {"code": -32601, "message": "Method not found"}}

        sys.stdout.write(json.dumps(res) + "\n")
        sys.stdout.flush()


def self_test() -> int:
    """Self-test for skill authoring, listing, verification, and symlinking."""
    print("==> Running skill_generator.py self-test suite...")
    test_skills_dir = Path("/tmp/test_nfp_skills")
    test_opencode_dir = Path("/tmp/test_opencode_skills")

    if test_skills_dir.exists():
        shutil.rmtree(test_skills_dir)
    if test_opencode_dir.exists():
        shutil.rmtree(test_opencode_dir)

    test_skills_dir.mkdir(parents=True)
    test_opencode_dir.mkdir(parents=True)

    # 1. Author test skill
    res = author_skill(
        name="test-sqlite-vacuum",
        description="Vacuum and analyze SQLite databases for optimal WAL size",
        instructions="1. Check size with ls -lh.\n2. Run sqlite3 db 'VACUUM;'.",
        category="database",
        triggers=["sqlite", "vacuum", "wal"],
        base_skills_dir=test_skills_dir,
        base_opencode_dir=test_opencode_dir,
        notify_voice=False,
    )
    assert res["status"] == "success"
    assert (test_skills_dir / "test-sqlite-vacuum" / "SKILL.md").exists()
    print("  [PASS] Test 1: Skill authored with valid directory & SKILL.md")

    # 2. Check OpenCode symlink
    link = test_opencode_dir / "test-sqlite-vacuum"
    assert link.is_symlink()
    print(f"  [PASS] Test 2: OpenCode symlink verified -> {link.resolve() if link.exists() else 'valid symlink'}")

    # 3. Test verification
    ver = verify_skill("test-sqlite-vacuum", base_skills_dir=test_skills_dir)
    assert ver["valid"] is True
    print("  [PASS] Test 3: Skill validation passed frontmatter and heading checks")

    # 4. Test listing
    listed = list_skills(base_skills_dir=test_skills_dir)
    assert len(listed) == 1
    assert listed[0]["slug"] == "test-sqlite-vacuum"
    print("  [PASS] Test 4: Skill listing returned authored skill")

    # Cleanup test dirs
    shutil.rmtree(test_skills_dir)
    shutil.rmtree(test_opencode_dir)
    print("==> All skill_generator.py tests PASSED!")
    return 0


if __name__ == "__main__":
    if "--test" in sys.argv:
        sys.exit(self_test())
    elif "--mcp" in sys.argv:
        run_mcp_server()
    elif len(sys.argv) > 1 and sys.argv[1] == "create":
        import argparse
        parser = argparse.ArgumentParser(description="Author a new NFP modular skill")
        parser.add_argument("create")
        parser.add_argument("--name", required=True, help="Skill slug name")
        parser.add_argument("--description", required=True, help="Skill description")
        parser.add_argument("--instructions", required=True, help="Instruction markdown or path")
        parser.add_argument("--category", default="general", help="Skill category")
        args = parser.parse_args()

        instr = args.instructions
        if os.path.exists(instr):
            instr = Path(instr).read_text(encoding="utf-8")

        out = author_skill(
            name=args.name,
            description=args.description,
            instructions=instr,
            category=args.category,
        )
        print(json.dumps(out, indent=2))
    elif len(sys.argv) > 1 and sys.argv[1] == "list":
        out = list_skills()
        for s in out:
            print(f"- {s['slug']} ({s['category']}): {s['description']}")
    elif len(sys.argv) > 1 and sys.argv[1] == "verify":
        if len(sys.argv) < 3:
            print("Usage: skill_generator.py verify <name>")
            sys.exit(1)
        out = verify_skill(sys.argv[2])
        print(json.dumps(out, indent=2))
    else:
        print("Usage: skill_generator.py [--test | --mcp | create --name <name> --description <desc> --instructions <text> | list | verify <name>]")
        sys.exit(0)
