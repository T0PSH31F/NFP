#!/usr/bin/env python3
"""
nfp-jev — Unified CLI/TUI Control Plane for Jev System-1 Decision Workflows
Commands:
  nfp-jev status                                    # Health and metrics overview
  nfp-jev triage-email [--all | --since 7d]         # Triage fleet Maildir emails
  nfp-jev organize-fs [--path PATH] [--dry-run]     # Classify & file local downloads
  nfp-jev mine-ad-hooks [--input FILE]              # Mine competitor ad hooks
  nfp-jev route-eval [--prompt TEXT]                # Evaluate LLM routing tier & compression
"""

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.request

JEV_ENGINE_URL = os.environ.get("JEV_ENGINE_URL", "http://127.0.0.1:20130")
ROUTER_URL = os.environ.get("JEV_ROUTER_URL", "http://127.0.0.1:20127")
EXPORTER_URL = os.environ.get("JEV_EXPORTER_URL", "http://127.0.0.1:20132")
LEAD_WEBHOOK_URL = os.environ.get("LEAD_WEBHOOK_URL", "http://127.0.0.1:20131")

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.abspath(os.path.join(BASE_DIR, "../../.."))


def check_endpoint(url, timeout=1.0):
    """Check health endpoint."""
    try:
        req = urllib.request.Request(f"{url.rstrip('/')}/health", method="GET")
        t0 = time.perf_counter()
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            elapsed = (time.perf_counter() - t0) * 1000
            if resp.status == 200:
                return True, elapsed, json.loads(resp.read().decode("utf-8"))
    except Exception:
        pass
    return False, 0.0, None


def cmd_status(args):
    """Show operational status of all Jev services."""
    services = [
        ("Jev Engine (Core System-1)", JEV_ENGINE_URL, [20130]),
        ("Router Pre-Flight Hook", ROUTER_URL, [20127]),
        ("Lead Triage Webhook", LEAD_WEBHOOK_URL, [20131]),
        ("Prometheus Exporter", EXPORTER_URL, [20132]),
    ]

    print("\n\033[1;36m=== Jev System-1 Control Plane Operational Status ===\033[0m")
    print(f"{'Service':<32} {'Endpoint':<26} {'Status':<10} {'Latency':<10}")
    print("-" * 80)

    for name, url, ports in services:
        active, ms, info = check_endpoint(url)
        status_str = "\033[1;32mONLINE\033[0m" if active else "\033[1;31mOFFLINE\033[0m"
        lat_str = f"{ms:.1f}ms" if active else "-"
        print(f"{name:<32} {url:<26} {status_str:<19} {lat_str:<10}")

    # Check metrics
    try:
        req = urllib.request.Request(f"{EXPORTER_URL}/metrics", method="GET")
        with urllib.request.urlopen(req, timeout=1.0) as resp:
            text = resp.read().decode("utf-8")
            print("\n\033[1;33m--- Active Telemetry Summary ---\033[0m")
            for line in text.splitlines():
                if line.startswith("jev_decisions_total") or line.startswith("jev_cost_saved_usd_total"):
                    print(f"  {line}")
    except Exception:
        pass
    print()


def cmd_triage_email(args):
    """Execute email triage."""
    script_path = os.path.join(REPO_ROOT, "layers/20-services/24-communication/email-triage-daemon.py")
    if not os.path.exists(script_path):
        print(f"Error: {script_path} not found")
        sys.exit(1)

    import importlib.util
    spec = importlib.util.spec_from_file_location("email_triage_daemon", script_path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)

    print(f"\033[1;34m[*] Running Email Triage (all={args.all}, since={args.since})...\033[0m")
    results = mod.triage_unprocessed_emails(limit=50 if not args.all else 500)
    print(f"\033[1;32m[✓] Processed {len(results)} emails successfully.\033[0m")
    for r in results[:5]:
        d = r.get("decision", {})
        cat = d.get("category", {}).get("value")
        act = d.get("action_required", {}).get("value")
        print(f"  - Subject: {r.get('subject', 'N/A')[:40]:<40} Category: {cat:<18} Action: {act}")


def cmd_organize_fs(args):
    """Execute filesystem classification and reorganization."""
    script_path = os.path.join(REPO_ROOT, "layers/20-services/25-data/fs-organizer-daemon.py")
    if not os.path.exists(script_path):
        print(f"Error: {script_path} not found")
        sys.exit(1)

    import importlib.util
    spec = importlib.util.spec_from_file_location("fs_organizer_daemon", script_path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)

    scan_dir = os.path.expanduser(args.path)
    print(f"\033[1;34m[*] Scanning directory: {scan_dir} (dry_run={args.dry_run})...\033[0m")
    results = mod.organize_inbox(scan_dir, dry_run=args.dry_run)
    print(f"\033[1;32m[✓] Processed {len(results)} items.\033[0m")
    for r in results[:5]:
        print(f"  - File: {os.path.basename(r.get('source_path', '')):<30} Target: {r.get('target_vault'):<20} Conf: {r.get('confidence', 0):.2f}")


def cmd_mine_ad_hooks(args):
    """Mine competitor ad hooks from dump."""
    script_path = os.path.join(REPO_ROOT, "layers/20-services/22-ai/ad-hook-miner.py")
    if not os.path.exists(script_path):
        print(f"Error: {script_path} not found")
        sys.exit(1)

    import importlib.util
    spec = importlib.util.spec_from_file_location("ad_hook_miner", script_path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)

    input_file = os.path.expanduser(args.input) if args.input else None
    if input_file and os.path.exists(input_file):
        items = mod.parse_raw_ad_file(input_file)
    else:
        items = [
            "Tired of waiting 40 minutes on NixOS builds? Save 80% developer hours with remote cache.",
            "Worried about downtime during Kubernetes cluster upgrades? Zero-downtime rolling deploys guaranteed.",
            "Stop wasting engineering budget on unoptimized cloud instances. Try our managed cluster free trial."
        ]

    print(f"\033[1;34m[*] Mining {len(items)} ad copies for hooks & market intelligence...\033[0m")
    for item in items[:5]:
        res = mod.analyze_item(item, input_file or "sample", JEV_ENGINE_URL)
        print(f"\n  Ad: \"{item[:70]}...\"")
        print(f"    Hook Category:     \033[1;33m{res['hook_category']}\033[0m")
        print(f"    Target Persona:    {res['target_persona']}")
        print(f"    Primary Objection: {res['primary_objection_handled']}")
        print(f"    CTA Urgency:       {res['call_to_action_urgency']}")


def cmd_route_eval(args):
    """Evaluate router tier and prompt compression for an arbitrary prompt."""
    prompt = args.prompt
    if not prompt:
        print("Please provide --prompt")
        sys.exit(1)

    script_path = os.path.join(REPO_ROOT, "layers/70-agents/78-llm-routers/jev-router-proxy.py")
    import importlib.util
    spec = importlib.util.spec_from_file_location("jev_router_proxy", script_path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)

    t0 = time.perf_counter()
    res = mod.evaluate_router_preflight(prompt)
    elapsed_ms = (time.perf_counter() - t0) * 1000

    decisions = res.get("decisions", {})
    tier = decisions.get("target_tier", {}).get("value")
    is_class = decisions.get("is_pure_classification", {}).get("value")
    comp = decisions.get("prompt_compression_eligible", {}).get("value")
    conf = res.get("aggregate_confidence", 0.0)

    print("\n\033[1;36m=== Jev LLM Router Pre-Flight Decision ===\033[0m")
    print(f"  Prompt Preview:       \"{prompt[:80]}...\"")
    print(f"  Evaluation Latency:   {elapsed_ms:.2f} ms")
    print(f"  Target Route Tier:    \033[1;32m{tier}\033[0m")
    print(f"  Pure Classification:  {is_class}")
    print(f"  Compression Eligible: {comp}")
    print(f"  Decision Confidence:  {conf:.2f}")

    if tier == "direct_jev_decision" or is_class:
        tokens = len(prompt.split())
        print(f"  \033[1;32m[!] Zero LLM Tokens Needed! Saved {tokens} tokens (~${tokens * 0.000015:.5f})\033[0m")
    elif tier == "local_slm_free":
        print("  \033[1;34m[!] Routing to Local SLM (Ollama / Llama 3) — $0.00 token cost\033[0m")
    elif tier == "frontier_flagship":
        print("  \033[1;35m[!] Routing to Frontier LLM (Claude 3.7 / Sonnet) for high complexity synthesis\033[0m")
    print()


def main():
    parser = argparse.ArgumentParser(prog="nfp-jev", description="Unified Jev System-1 CLI Control Plane")
    subparsers = parser.add_subparsers(dest="command")

    subparsers.add_parser("status", help="Check status of all Jev services")

    p_email = subparsers.add_parser("triage-email", help="Triage inbox emails")
    p_email.add_argument("--all", action="store_true", help="Process all emails without limit")
    p_email.add_argument("--since", default="7d", help="Process emails newer than interval (default 7d)")

    p_fs = subparsers.add_parser("organize-fs", help="Organize and classify filesystem directory")
    p_fs.add_argument("--path", default="~/Downloads", help="Directory path to scan")
    p_fs.add_argument("--dry-run", action="store_true", help="Inspect without moving files")

    p_ad = subparsers.add_parser("mine-ad-hooks", help="Mine competitor ad hooks and market intel")
    p_ad.add_argument("--input", help="Path to input ad dump CSV/JSON")

    p_route = subparsers.add_parser("route-eval", help="Evaluate prompt routing tier & compression")
    p_route.add_argument("--prompt", required=True, help="Input prompt text to evaluate")

    args = parser.parse_args()
    if args.command == "status" or not args.command:
        cmd_status(args)
    elif args.command == "triage-email":
        cmd_triage_email(args)
    elif args.command == "organize-fs":
        cmd_organize_fs(args)
    elif args.command == "mine-ad-hooks":
        cmd_mine_ad_hooks(args)
    elif args.command == "route-eval":
        cmd_route_eval(args)


if __name__ == "__main__":
    main()
