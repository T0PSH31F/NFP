#!/usr/bin/env python3
"""
Hermes Autonomous Ratchet Harness (The Karpathy Method for NFP)
==============================================================
Implements autonomous, unattended task execution and verification:
1. Reads objectives from ~/Notes/EverOS/todo.md (## Hermes / @hermes) or feature_list.json.
2. Isolates work in an ephemeral git worktree (/tmp/hermes-scratch/<slug>).
3. Dispatches coding and patch generation to the Pi/Hermes durable worker (:8089).
4. Runs the Immutable Judge: deterministic static checks, flake evaluation, and rubric verification.
5. Autonomous Ratchet:
   - PASS -> Fast-forward merges to main, commits evidence, updates blackboard, vocalizes via GLaDOS voice.
   - FAIL -> Discards with git reset/prune, records failure log, preserves pristine clean state on main.
6. Enforces RAM pre-flight (<75%) and nix-build single process concurrency.
"""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import time
import urllib.request
import urllib.error
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

REPO_ROOT = Path(os.environ.get("NFP_REPO_ROOT", "/home/t0psh31f/Clan/NFP"))
SCRATCH_BASE = Path(os.environ.get("HERMES_SCRATCH_DIR", "/tmp/hermes-scratch"))
TODO_FILE = Path(os.environ.get("NFP_TODO_FILE", "/home/t0psh31f/Notes/EverOS/todo.md"))
FEATURE_LIST_FILE = REPO_ROOT / "feature_list.json"
PROGRESS_FILE = REPO_ROOT / "agent-progress.md"
PI_A2A_URL = os.environ.get("PI_A2A_URL", "http://127.0.0.1:8089/v1/delegate")
NFP_TODO_BIN = Path(os.environ.get("NFP_TODO_BIN", "/home/t0psh31f/.local/bin/nfp-todo"))
GLADOS_TTS_BIN = Path(os.environ.get("GLADOS_TTS_BIN", "/home/t0psh31f/.local/bin/glados-tts-cli"))
CHECK_SCRIPT = REPO_ROOT / "layers/00-cyberia/06-scripts/nfp-check.sh"
MAX_RAM_PERCENT = float(os.environ.get("HERMES_MAX_RAM_PCT", "75.0"))


def speak_glados(text: str) -> None:
    """Mandatory GLaDOS voice notification (non-blocking)."""
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


def check_system_resources() -> Tuple[bool, str]:
    """Pre-flight safety check: RAM < 75% and no active Nix build/eval processes."""
    # 1. Active nix processes
    try:
        ps_out = subprocess.check_output(
            ["ps", "-eo", "pid,cmd"],
            text=True,
            timeout=5,
        )
        for line in ps_out.splitlines():
            if re.search(r"\b(nix-build|nix eval|nix build|nixos-rebuild|clan machines update)\b", line):
                if "grep" not in line and "hermes-ratchet" not in line:
                    return False, f"Active nix process running: {line.strip()}"
    except Exception as e:
        return False, f"Failed to check active processes: {e}"

    # 2. Memory threshold
    try:
        with open("/proc/meminfo", "r") as f:
            lines = f.readlines()
        meminfo = {}
        for line in lines:
            parts = line.split(":")
            if len(parts) == 2:
                key = parts[0].strip()
                val = parts[1].strip().split()[0]
                meminfo[key] = int(val)
        total = meminfo.get("MemTotal", 1)
        avail = meminfo.get("MemAvailable", total)
        used_pct = ((total - avail) / total) * 100.0
        if used_pct >= MAX_RAM_PERCENT:
            return False, f"Memory usage ({used_pct:.1f}%) exceeds safety cap ({MAX_RAM_PERCENT}%)"
    except Exception as e:
        return False, f"Failed to read meminfo: {e}"

    return True, "System green"


def find_pending_task() -> Optional[Dict[str, Any]]:
    """Scan todo.md and feature_list.json for actionable tasks."""
    # Priority 1: Check ## Hermes in todo.md
    if TODO_FILE.exists():
        try:
            content = TODO_FILE.read_text(encoding="utf-8")
            # First look for tasks assigned in ## Hermes
            hermes_match = re.search(r"## Hermes\s*\n((?:[^\n#]+\n*)*)", content)
            if hermes_match:
                section_text = hermes_match.group(1)
                for line in section_text.splitlines():
                    task_match = re.search(r"-\s*\[\s*\]\s+(.+)$", line)
                    if task_match:
                        raw_task = task_match.group(1).strip()
                        if not raw_task.startswith("[BLOCKED]"):
                            return {
                                "source": "todo.md",
                                "title": raw_task,
                                "type": "todo",
                                "id": f"todo-{int(time.time())}",
                            }

            # Check if Erik delegated something with @hermes
            erik_match = re.search(r"## Erik\s*\n((?:[^\n#]+\n*)*)", content)
            if erik_match:
                section_text = erik_match.group(1)
                for line in section_text.splitlines():
                    task_match = re.search(r"-\s*\[\s*\]\s+@hermes\s+(.+)$", line)
                    if task_match:
                        raw_task = task_match.group(1).strip()
                        # Auto-claim via nfp-todo CLI if available
                        if NFP_TODO_BIN.exists() and os.access(NFP_TODO_BIN, os.X_OK):
                            try:
                                subprocess.run(
                                    [str(NFP_TODO_BIN), "--agent", "hermes", "claim", raw_task],
                                    check=True,
                                    capture_output=True,
                                    text=True,
                                    timeout=5,
                                )
                            except Exception:
                                pass
                        return {
                            "source": "todo.md",
                            "title": raw_task,
                            "type": "todo",
                            "id": f"todo-{int(time.time())}",
                        }
        except Exception as e:
            print(f"[hermes-ratchet] Error reading todo.md: {e}", file=sys.stderr)

    # Priority 2: Check feature_list.json in repo root
    if FEATURE_LIST_FILE.exists():
        try:
            with open(FEATURE_LIST_FILE, "r", encoding="utf-8") as f:
                data = json.load(f)
            features = data.get("features", [])
            for feat in features:
                if feat.get("state") in ("untried", "in-progress"):
                    return {
                        "source": "feature_list.json",
                        "title": feat.get("name", feat.get("id", "unnamed-feature")),
                        "behavior": feat.get("behavior", ""),
                        "verification": feat.get("verification", []),
                        "type": "feature",
                        "id": feat.get("id"),
                    }
        except Exception as e:
            print(f"[hermes-ratchet] Error reading feature_list.json: {e}", file=sys.stderr)

    return None


def create_worktree(slug: str) -> Tuple[Path, str]:
    """Create an isolated git worktree and branch for the experiment."""
    branch_name = f"hermes/{slug}-{int(time.time())}"
    worktree_path = SCRATCH_BASE / slug

    if worktree_path.exists():
        shutil.rmtree(worktree_path, ignore_errors=True)
    SCRATCH_BASE.mkdir(parents=True, exist_ok=True)

    subprocess.run(
        ["git", "worktree", "add", "-b", branch_name, str(worktree_path), "HEAD"],
        cwd=str(REPO_ROOT),
        check=True,
        capture_output=True,
        text=True,
    )
    return worktree_path, branch_name


def prune_worktree(worktree_path: Path, branch_name: str) -> None:
    """Remove ephemeral worktree and branch."""
    try:
        subprocess.run(
            ["git", "worktree", "remove", "--force", str(worktree_path)],
            cwd=str(REPO_ROOT),
            capture_output=True,
            timeout=10,
        )
    except Exception:
        pass
    if worktree_path.exists():
        shutil.rmtree(worktree_path, ignore_errors=True)
    try:
        subprocess.run(
            ["git", "branch", "-D", branch_name],
            cwd=str(REPO_ROOT),
            capture_output=True,
            timeout=5,
        )
    except Exception:
        pass


def run_worker_task(task_spec: Dict[str, Any], worktree_path: Path) -> Dict[str, Any]:
    """Invoke the durable Pi/Hermes agent worker over A2A bridge."""
    title = task_spec["title"]
    desc = task_spec.get("behavior", "")
    session_id = f"hermes-ratchet-{task_spec.get('id', 'job')}"

    prompt = f"""You are executing an autonomous Karpathy Ratchet task for the NFP Flake repository.
Working Directory: {worktree_path}

Task: {title}
Description / Criteria: {desc}

Operational Directives:
1. Scoped Changes Only: Modify only the files strictly required to accomplish the task.
2. Flake Parity: Preserve existing code format, comments, and structure.
3. No Secrets in Store: Never write unencrypted secrets to Nix files.
4. When finished editing, ensure files are saved cleanly.
"""
    payload = json.dumps({
        "task": prompt,
        "session_id": session_id,
        "notify_voice": False,
    }).encode("utf-8")

    req = urllib.request.Request(
        PI_A2A_URL,
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=300) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except Exception as e:
        return {"error": f"Failed to call worker A2A bridge: {e}"}


def verify_changes(worktree_path: Path, custom_verifications: Optional[List[str]] = None) -> Tuple[bool, str]:
    """The Immutable Judge: Run strict deterministic tests."""
    logs = []

    # 1. Check if git diff exists (did the worker change anything?)
    diff_check = subprocess.run(
        ["git", "status", "--porcelain"],
        cwd=str(worktree_path),
        capture_output=True,
        text=True,
    )
    if not diff_check.stdout.strip():
        return False, "No modifications produced by worker."

    # 2. Run static formatter and linter check
    if CHECK_SCRIPT.exists() and os.access(CHECK_SCRIPT, os.X_OK):
        proc = subprocess.run(
            [str(CHECK_SCRIPT), "static"],
            cwd=str(worktree_path),
            capture_output=True,
            text=True,
            timeout=60,
        )
        logs.append(f"[nfp-check static: {proc.returncode}]\n{proc.stdout}")
        if proc.returncode != 0:
            return False, f"Static check failed:\n{proc.stderr}\n{proc.stdout}"

    # 3. Verify Flake Evaluation (sanji closure derivation check)
    proc = subprocess.run(
        ["nix", "eval", ".#nixosConfigurations.sanji.config.system.build.toplevel.drvPath", "--raw"],
        cwd=str(worktree_path),
        capture_output=True,
        text=True,
        timeout=120,
    )
    logs.append(f"[nix eval sanji: {proc.returncode}]\n{proc.stdout}")
    if proc.returncode != 0:
        return False, f"Nix evaluation failed:\n{proc.stderr}"

    # 4. Custom feature verifications
    if custom_verifications:
        for cmd in custom_verifications:
            proc = subprocess.run(
                cmd,
                shell=True,
                cwd=str(worktree_path),
                capture_output=True,
                text=True,
                timeout=180,
            )
            logs.append(f"[{cmd}: {proc.returncode}]\n{proc.stdout}")
            if proc.returncode != 0:
                return False, f"Custom verification command failed: '{cmd}'\n{proc.stderr}"

    return True, "\n".join(logs)


def record_progress(title: str, state: str, evidence: str) -> None:
    """Append verified audit trail entry to agent-progress.md."""
    if not PROGRESS_FILE.exists():
        return
    ts = time.strftime("%Y-%m-%d %H:%M:%S UTC", time.gmtime())
    entry = f"""
### [{ts}] Hermes Ratchet: {title}
- **State**: {state}
- **Evidence**:
```
{evidence[:1000]}
```
"""
    with open(PROGRESS_FILE, "a", encoding="utf-8") as f:
        f.write(entry)


def execute_cycle() -> bool:
    """Run one complete Karpathy Ratchet cycle."""
    # Step 1: Pre-flight resource check
    green, reason = check_system_resources()
    if not green:
        print(f"[hermes-ratchet] Pre-flight skipped: {reason}", flush=True)
        return False

    # Step 2: Task acquisition
    task = find_pending_task()
    if not task:
        print("[hermes-ratchet] No pending tasks found. Resting.", flush=True)
        return False

    title = task["title"]
    slug = re.sub(r"[^a-zA-Z0-9_-]", "_", title.lower())[:24]
    print(f"\n[hermes-ratchet] Claimed task: '{title}' (slug: {slug})", flush=True)

    # Step 3: Ephemeral worktree sandboxing
    worktree_path, branch_name = create_worktree(slug)
    print(f"[hermes-ratchet] Created isolated worktree at {worktree_path} on {branch_name}", flush=True)

    try:
        # Step 4: Worker task dispatch
        worker_res = run_worker_task(task, worktree_path)
        if "error" in worker_res:
            print(f"[hermes-ratchet] Worker error: {worker_res['error']}", flush=True)
            prune_worktree(worktree_path, branch_name)
            record_progress(title, "error", str(worker_res["error"]))
            return False

        # Step 5: Immutable Judge verification
        passed, evidence = verify_changes(worktree_path, task.get("verification"))

        # Step 6: The Ratchet Decision
        if passed:
            print(f"[hermes-ratchet] RATIFIED! Task '{title}' passed all verifications.", flush=True)
            # Commit in worktree
            subprocess.run(
                ["git", "commit", "-am", f"feat(hermes): {title} [karpathy-ratchet verified]"],
                cwd=str(worktree_path),
                check=True,
                capture_output=True,
            )
            # Merge to main
            subprocess.run(
                ["git", "merge", "--ff-only", branch_name],
                cwd=str(REPO_ROOT),
                check=True,
                capture_output=True,
            )
            # Update blackboard
            if task.get("type") == "todo" and NFP_TODO_BIN.exists() and os.access(NFP_TODO_BIN, os.X_OK):
                subprocess.run(
                    [str(NFP_TODO_BIN), "--agent", "hermes", "toggle", title],
                    capture_output=True,
                )
            elif task.get("type") == "feature" and FEATURE_LIST_FILE.exists():
                with open(FEATURE_LIST_FILE, "r+", encoding="utf-8") as f:
                    data = json.load(f)
                    for feat in data.get("features", []):
                        if feat.get("id") == task["id"]:
                            feat["state"] = "passing"
                            feat["evidence"] = [evidence[:500]]
                    f.seek(0)
                    json.dump(data, f, indent=2)
                    f.truncate()

            record_progress(title, "passing", evidence)
            speak_glados(f"Task {title} has passed all verifications and has been ratcheted into main.")
            prune_worktree(worktree_path, branch_name)
            return True
        else:
            print(f"[hermes-ratchet] REVERTED. Task '{title}' failed verification: {evidence[:200]}", flush=True)
            record_progress(title, "failed", evidence)
            speak_glados(f"Hypothesis for {title} failed deterministic verification. Reverting to clean state.")
            prune_worktree(worktree_path, branch_name)
            return False

    except Exception as e:
        print(f"[hermes-ratchet] Exception during cycle: {e}", flush=True)
        prune_worktree(worktree_path, branch_name)
        return False


def main() -> None:
    parser = argparse.ArgumentParser(description="Hermes Autonomous Ratchet Harness")
    parser.add_argument("--once", action="store_true", help="Run a single cycle and exit")
    parser.add_argument("--interval", type=int, default=120, help="Poll interval in seconds (default: 120)")
    args = parser.parse_args()

    print("[hermes-ratchet] Autonomous Karpathy Ratchet Harness starting...", flush=True)
    if args.once:
        execute_cycle()
        return

    while True:
        try:
            execute_cycle()
        except KeyboardInterrupt:
            print("\n[hermes-ratchet] Terminated by user.", flush=True)
            break
        except Exception as e:
            print(f"[hermes-ratchet] Unexpected error in main loop: {e}", file=sys.stderr, flush=True)
        time.sleep(args.interval)


if __name__ == "__main__":
    main()
