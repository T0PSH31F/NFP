#!/usr/bin/env python3
"""
Jev Decision MCP Server (stdio)
Exposes Jev System-1 high-speed decision, email triage, and filesystem routing tools across the fleet.
"""

import json
import mimetypes
import os
import re
import sys
import urllib.error
import urllib.request

JEV_ENGINE_URLS = [
    os.environ.get("JEV_ENGINE_URL", "http://127.0.0.1:20130"),
    "http://luffy.nfp.nix:20130",
]

EMAIL_TRIAGE_QUESTIONS = [
    {
        "id": "category",
        "type": "enum",
        "options": [
            "invoice_financial",
            "security_auth",
            "personal",
            "newsletter",
            "automated_alert",
            "spam"
        ]
    },
    {
        "id": "action_required",
        "type": "boolean"
    },
    {
        "id": "target_agent",
        "type": "enum",
        "options": [
            "hermes_billing",
            "paperclip_ops",
            "archive_silent"
        ]
    }
]

FS_ORGANIZE_QUESTIONS = [
    {
        "id": "target_vault",
        "type": "enum",
        "options": [
            "financial_records",
            "code_projects",
            "media_audiobooks",
            "personal_documents",
            "ephemeral_trash"
        ]
    },
    {
        "id": "suggested_filename_pattern",
        "type": "enum",
        "options": [
            "YYYY-MM-DD_vendor_receipt",
            "project_artifact",
            "keep_original"
        ]
    }
]

LEAD_SCORING_QUESTIONS = [
    {
        "id": "qualification_tier",
        "type": "enum",
        "options": [
            "tier_1_enterprise_hot",
            "tier_2_smb_warm",
            "tier_3_low_budget_cold",
            "spam_or_jobseeker"
        ]
    },
    {
        "id": "estimated_deal_size",
        "type": "enum",
        "options": [
            "under_5k",
            "5k_to_20k",
            "20k_to_100k",
            "enterprise_100k_plus"
        ]
    },
    {
        "id": "technical_fit",
        "type": "boolean"
    },
    {
        "id": "urgency_timeline",
        "type": "enum",
        "options": [
            "immediate_under_2_weeks",
            "quarterly_1_3_months",
            "exploratory"
        ]
    }
]

AD_HOOK_QUESTIONS = [
    {
        "id": "hook_category",
        "type": "enum",
        "options": [
            "pain_point_frustration",
            "fear_of_loss",
            "social_proof",
            "curiosity_novelty",
            "direct_savings_roi"
        ]
    },
    {
        "id": "primary_objection_handled",
        "type": "enum",
        "options": [
            "setup_complexity",
            "pricing_cost",
            "security_compliance",
            "performance_speed"
        ]
    },
    {
        "id": "target_persona",
        "type": "enum",
        "options": [
            "devops_infrastructure_lead",
            "founder_cto",
            "individual_contributor",
            "finance_buyer"
        ]
    },
    {
        "id": "call_to_action_urgency",
        "type": "enum",
        "options": [
            "free_trial",
            "book_demo",
            "limited_offer",
            "content_download"
        ]
    }
]

TOOLS = [
    {
        "name": "evaluate_decision",
        "description": "Evaluate input state against typed questions returning deterministic values and confidence distributions.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "state": {
                    "type": "string",
                    "description": "Textual state context (e.g. email headers/body, file metadata)"
                },
                "questions": {
                    "type": "array",
                    "description": "List of typed questions with enum options or boolean type",
                    "items": {
                        "type": "object",
                        "properties": {
                            "id": {"type": "string"},
                            "type": {"type": "string", "enum": ["enum", "boolean"]},
                            "options": {"type": "array", "items": {"type": "string"}}
                        },
                        "required": ["id", "type"]
                    }
                }
            },
            "required": ["state", "questions"]
        }
    },
    {
        "name": "jev_evaluate_decision",
        "description": "Alias for evaluate_decision: evaluate state against typed questions.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "state": {"type": "string"},
                "questions": {"type": "array"}
            },
            "required": ["state", "questions"]
        }
    },
    {
        "name": "jev_decide",
        "description": "Alias for evaluate_decision: evaluate state against typed questions.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "state": {"type": "string"},
                "questions": {"type": "array"}
            },
            "required": ["state", "questions"]
        }
    },
    {
        "name": "jev_lead_triage",
        "description": "Score and qualify inbound leads with qualification tier, deal size, technical fit, and urgency timeline.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "state": {
                    "type": "string",
                    "description": "Raw lead text or structured lead representation"
                },
                "lead": {
                    "type": "object",
                    "description": "Structured lead object (name, email, company, message, source, budget_self_reported)"
                }
            }
        }
    },
    {
        "name": "jev_ad_hook_mine",
        "description": "Analyze ad copy and customer reviews to extract hook categories, handled objections, target personas, and CTA urgency.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "ad_copy": {
                    "type": "string",
                    "description": "Ad headline, body copy, or competitor review text"
                },
                "items": {
                    "type": "array",
                    "items": {"type": "string"},
                    "description": "Batch list of ad copies to analyze"
                }
            }
        }
    },
    {
        "name": "jev_classify_batch",
        "description": "Batch evaluate multiple state items against question schemas.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "items": {
                    "type": "array",
                    "items": {
                        "type": "object",
                        "properties": {
                            "state": {"type": "string"},
                            "questions": {"type": "array"}
                        },
                        "required": ["state", "questions"]
                    }
                }
            },
            "required": ["items"]
        }
    },
    {
        "name": "triage_email_batch",
        "description": "Triage a batch of emails (file paths or raw text) with category, action_required, and target_agent.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "mail_ids": {
                    "type": "array",
                    "items": {"type": "string"},
                    "description": "List of Maildir file paths or raw email header/body strings"
                }
            },
            "required": ["mail_ids"]
        }
    },
    {
        "name": "classify_file_batch",
        "description": "Classify a batch of file paths proposing destination vault and filename pattern.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "file_paths": {
                    "type": "array",
                    "items": {"type": "string"},
                    "description": "List of filesystem file paths to inspect and classify"
                }
            },
            "required": ["file_paths"]
        }
    },
    {
        "name": "trigger_jev_workflow",
        "description": "Trigger an autonomous Jev System-1 workflow: email_triage, fs_organizer, lead_triage, ad_miner, router_eval, or book_purifier.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "name": {
                    "type": "string",
                    "enum": ["email_triage", "fs_organizer", "lead_triage", "ad_miner", "router_eval", "book_purifier"],
                    "description": "Workflow identifier to execute"
                },
                "params": {
                    "type": "object",
                    "description": "Parameters for the workflow execution (e.g. prompt, lead, path, dry_run, items)"
                }
            },
            "required": ["name"]
        }
    },
    {
        "name": "triage_book_metadata",
        "description": "Extract book metadata and evaluate with Jev System-1 for AI/income RAG ingestion suitability, domain classification, and canonical library path.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "path": {
                    "type": "string",
                    "description": "Absolute filesystem path to the e-book (.epub, .pdf, .mobi, .azw3, .cbz)"
                },
                "title": {
                    "type": "string",
                    "description": "Optional book title override"
                },
                "author": {
                    "type": "string",
                    "description": "Optional author name override"
                },
                "snippet": {
                    "type": "string",
                    "description": "Optional TOC or summary snippet for classification"
                }
            },
            "required": ["path"]
        }
    }
]


def query_engine_decide(state, questions):
    """Query Jev Engine endpoint with failover."""
    payload = json.dumps({"state": state, "questions": questions}).encode("utf-8")

    for base_url in JEV_ENGINE_URLS:
        url = f"{base_url.rstrip('/')}/v1/decide"
        try:
            req = urllib.request.Request(
                url,
                data=payload,
                headers={"Content-Type": "application/json"},
                method="POST"
            )
            with urllib.request.urlopen(req, timeout=3.0) as resp:
                if resp.status == 200:
                    data = resp.read().decode("utf-8")
                    return json.loads(data)
        except Exception:
            continue

    # Fallback embedded evaluation if remote engine unreachable
    return fallback_local_decide(state, questions)


def fallback_local_decide(state, questions):
    """Embedded fallback decision scoring."""
    state_lower = state.lower()
    decisions = {}
    confidences = []

    for q in questions:
        q_id = q.get("id")
        q_type = q.get("type", "enum")
        options = q.get("options", [])

        if q_type == "boolean":
            if q_id == "is_ai_or_passive_income":
                ai_triggers = [
                    "agent", "agentic", "ai", "machine learning", "deep learning", "llm",
                    "passive income", "cash flow", "business", "entrepreneur", "marketing",
                    "rag", "vector", "embedding", "saas", "prompt", "swarms"
                ]
                pos = any(t in state_lower for t in ai_triggers)
            else:
                pos_triggers = ["action required", "action needed", "due", "verify", "pay by", "alert", "error"]
                pos = any(t in state_lower for t in pos_triggers)
            conf = 0.90 if pos else 0.85
            decisions[q_id] = {
                "value": pos,
                "confidence": conf,
                "probabilities": {"true": conf if pos else 1 - conf, "false": 1 - conf if pos else conf}
            }
            confidences.append(conf)
        else:
            best_opt = options[0] if options else "unknown"
            best_score = 0
            for opt in options:
                words = opt.replace("_", " ").split()
                score = sum(1 for w in words if w in state_lower)
                if score > best_score:
                    best_score = score
                    best_opt = opt
            conf = 0.85 if best_score > 0 else 0.50
            decisions[q_id] = {
                "value": best_opt,
                "confidence": conf,
                "probabilities": {best_opt: conf}
            }
            confidences.append(conf)

    agg = round(sum(confidences) / len(confidences), 4) if confidences else 0.5
    return {
        "status": "success",
        "engine": "jev-fallback-embedded",
        "aggregate_confidence": agg,
        "decisions": decisions
    }


def handle_evaluate_decision(args):
    state = args.get("state", "")
    questions = args.get("questions", [])
    return query_engine_decide(state, questions)


def handle_jev_classify_batch(args):
    items = args.get("items", [])
    results = []
    for it in items:
        res = query_engine_decide(it.get("state", ""), it.get("questions", []))
        results.append(res)
    return {"results": results}


def handle_triage_email_batch(args):
    mail_ids = args.get("mail_ids", [])
    results = []

    for item in mail_ids:
        # Check if item is a local file path
        content = item
        if os.path.exists(item) and os.path.isfile(item):
            try:
                with open(item, "r", encoding="utf-8", errors="ignore") as f:
                    content = f.read(4096)  # Read header + first part of body
            except Exception as e:
                content = f"Error reading file {item}: {e}"

        res = query_engine_decide(content, EMAIL_TRIAGE_QUESTIONS)
        results.append({
            "mail_id": item,
            "decision": res.get("decisions", {}),
            "aggregate_confidence": res.get("aggregate_confidence", 0.0),
            "needs_escalation": res.get("aggregate_confidence", 0.0) < 0.80
        })

    return {"count": len(results), "triage_results": results}


def handle_classify_file_batch(args):
    file_paths = args.get("file_paths", [])
    results = []

    for path in file_paths:
        meta_parts = [f"Path: {path}"]
        if os.path.exists(path):
            stat = os.stat(path)
            meta_parts.append(f"Size: {stat.st_size} bytes")
            mime, _ = mimetypes.guess_type(path)
            if mime:
                meta_parts.append(f"MIME: {mime}")

            # If readable text, grab snippet
            try:
                with open(path, "r", encoding="utf-8", errors="ignore") as f:
                    snippet = f.read(1024)
                    if snippet.strip():
                        meta_parts.append(f"Snippet: {snippet.strip()[:300]}")
            except Exception:
                pass
        else:
            meta_parts.append(f"Basename: {os.path.basename(path)}")

        state_str = "\n".join(meta_parts)
        res = query_engine_decide(state_str, FS_ORGANIZE_QUESTIONS)
        decisions = res.get("decisions", {})

        target_vault = decisions.get("target_vault", {}).get("value", "personal_documents")
        pattern = decisions.get("suggested_filename_pattern", {}).get("value", "keep_original")
        conf = res.get("aggregate_confidence", 0.0)

        results.append({
            "source_path": path,
            "target_vault": target_vault,
            "suggested_pattern": pattern,
            "confidence": conf,
            "needs_escalation": conf < 0.80,
            "decisions": decisions
        })

    return {"count": len(results), "classifications": results}


def handle_jev_lead_triage(args):
    lead = args.get("lead")
    state = args.get("state", "")
    if lead and isinstance(lead, dict):
        state_parts = []
        for k in ("company", "name", "email", "budget_self_reported", "source", "message"):
            if lead.get(k):
                state_parts.append(f"{k.replace('_', ' ').title()}: {lead.get(k)}")
        state = "\n".join(state_parts)

    res = query_engine_decide(state, LEAD_SCORING_QUESTIONS)
    decisions = res.get("decisions", {})
    agg_conf = res.get("aggregate_confidence", 0.0)

    tier = decisions.get("qualification_tier", {}).get("value", "tier_3_low_budget_cold")
    deal_size = decisions.get("estimated_deal_size", {}).get("value", "under_5k")
    tech_fit = decisions.get("technical_fit", {}).get("value", False)
    timeline = decisions.get("urgency_timeline", {}).get("value", "exploratory")

    is_hot = (tier == "tier_1_enterprise_hot" and agg_conf >= 0.85)

    return {
        "status": "success",
        "qualification_tier": tier,
        "estimated_deal_size": deal_size,
        "technical_fit": tech_fit,
        "urgency_timeline": timeline,
        "aggregate_confidence": agg_conf,
        "is_hot_lead": is_hot,
        "needs_escalation": agg_conf < 0.80,
        "decisions": decisions,
    }


def handle_jev_ad_hook_mine(args):
    ad_copy = args.get("ad_copy", "")
    items = args.get("items", [])
    if ad_copy and not items:
        items = [ad_copy]

    results = []
    for item in items:
        res = query_engine_decide(item, AD_HOOK_QUESTIONS)
        decisions = res.get("decisions", {})
        agg_conf = res.get("aggregate_confidence", 0.0)

        results.append({
            "ad_copy_preview": item[:120],
            "hook_category": decisions.get("hook_category", {}).get("value", "pain_point_frustration"),
            "primary_objection_handled": decisions.get("primary_objection_handled", {}).get("value", "setup_complexity"),
            "target_persona": decisions.get("target_persona", {}).get("value", "devops_infrastructure_lead"),
            "call_to_action_urgency": decisions.get("call_to_action_urgency", {}).get("value", "free_trial"),
            "confidence": agg_conf,
            "decisions": decisions,
        })

    return {"count": len(results), "mined_hooks": results}


def handle_trigger_jev_workflow(args):
    wf_name = args.get("name", "")
    params = args.get("params", {})

    if wf_name == "email_triage":
        mail_ids = params.get("mail_ids", [])
        if mail_ids:
            return handle_triage_email_batch({"mail_ids": mail_ids})
        email_script = os.path.join(os.path.dirname(__file__), "../jev/email-triage-daemon.py")
        if os.path.exists(email_script):
            try:
                import importlib.util
                spec = importlib.util.spec_from_file_location("email_triage_daemon", email_script)
                mod = importlib.util.module_from_spec(spec)
                spec.loader.exec_module(mod)
                limit = params.get("limit", 20)
                res = mod.triage_unprocessed_emails(limit=limit)
                return {"status": "success", "workflow": "email_triage", "processed_count": len(res), "results": res[:10]}
            except Exception as e:
                return {"status": "error", "message": f"Email triage execution failed: {e}"}
        return {"status": "error", "message": "email-triage-daemon.py not found"}

    elif wf_name == "fs_organizer":
        file_paths = params.get("file_paths", [])
        if file_paths:
            return handle_classify_file_batch({"file_paths": file_paths})
        fs_script = os.path.join(os.path.dirname(__file__), "../jev/fs-organizer-daemon.py")
        if os.path.exists(fs_script):
            try:
                import importlib.util
                spec = importlib.util.spec_from_file_location("fs_organizer_daemon", fs_script)
                mod = importlib.util.module_from_spec(spec)
                spec.loader.exec_module(mod)
                target_path = os.path.expanduser(params.get("path", "~/Downloads"))
                dry_run = params.get("dry_run", True)
                res = mod.organize_inbox(target_path, dry_run=dry_run)
                return {"status": "success", "workflow": "fs_organizer", "processed_count": len(res), "dry_run": dry_run, "results": res[:10]}
            except Exception as e:
                return {"status": "error", "message": f"FS organizer execution failed: {e}"}
        return {"status": "error", "message": "fs-organizer-daemon.py not found"}

    elif wf_name == "lead_triage":
        lead = params.get("lead", params)
        return handle_jev_lead_triage({"lead": lead})

    elif wf_name == "ad_miner":
        items = params.get("items", [])
        ad_copy = params.get("ad_copy", "")
        return handle_jev_ad_hook_mine({"items": items, "ad_copy": ad_copy})

    elif wf_name == "router_eval":
        prompt = params.get("prompt", "")
        if not prompt and "messages" in params:
            msgs = params.get("messages", [])
            prompt = "\n".join(f"{m.get('role', 'user')}: {m.get('content', '')}" for m in msgs)
        router_script = os.path.join(os.path.dirname(__file__), "../jev/jev-router-proxy.py")
        if os.path.exists(router_script):
            try:
                import importlib.util
                spec = importlib.util.spec_from_file_location("jev_router_proxy", router_script)
                mod = importlib.util.module_from_spec(spec)
                spec.loader.exec_module(mod)
                eval_res = mod.evaluate_router_preflight(prompt)
                decisions = eval_res.get("decisions", {})
                tier = decisions.get("target_tier", {}).get("value")
                is_class = decisions.get("is_pure_classification", {}).get("value")
                comp = decisions.get("prompt_compression_eligible", {}).get("value")
                tokens = len(prompt.split())
                return {
                    "status": "success",
                    "workflow": "router_eval",
                    "target_tier": tier,
                    "is_pure_classification": is_class,
                    "prompt_compression_eligible": comp,
                    "estimated_tokens": tokens,
                    "zero_llm_tokens": tier == "direct_jev_decision" or is_class,
                    "estimated_cost_saved_usd": round(tokens * 0.000015, 6) if (tier == "direct_jev_decision" or is_class) else 0.0,
                    "decisions": decisions
                }
            except Exception as e:
                return {"status": "error", "message": f"Router eval execution failed: {e}"}
        return {"status": "error", "message": "jev-router-proxy.py not found"}

    elif wf_name == "book_purifier":
        purifier_script = os.path.join(os.path.dirname(__file__), "../jev/book-vault-purifier.py")
        if os.path.exists(purifier_script):
            try:
                import importlib.util
                spec = importlib.util.spec_from_file_location("book_vault_purifier", purifier_script)
                mod = importlib.util.module_from_spec(spec)
                spec.loader.exec_module(mod)
                source_dir = params.get("source", "/data/vault/raw-inbox")
                dry_run = params.get("dry_run", True)
                res = mod.run_purification_sweep(source_dir=source_dir, dry_run=dry_run)
                return {
                    "status": "success",
                    "workflow": "book_purifier",
                    "dry_run": dry_run,
                    "summary": res
                }
            except Exception as e:
                return {"status": "error", "message": f"Book purifier execution failed: {e}"}
        return {"status": "error", "message": "book-vault-purifier.py not found"}

    return {"status": "error", "message": f"Unknown workflow: {wf_name}"}


def handle_triage_book_metadata(args):
    """Triage e-book metadata and evaluate with Jev for AI/income RAG routing."""
    path = args.get("path", "")
    title = args.get("title")
    author = args.get("author")
    snippet = args.get("snippet", "")

    if not path and not title:
        return {"status": "error", "message": "Either 'path' or 'title' must be provided"}

    ext = os.path.splitext(path)[1].lower() if path else ".epub"
    valid_exts = [".epub", ".pdf", ".mobi", ".azw3", ".cbz"]
    if ext and ext not in valid_exts:
        return {
            "status": "rejected",
            "is_valid_ebook": False,
            "reason": f"Non-book extension '{ext}'. Only .epub, .pdf, .mobi, .azw3, .cbz supported.",
            "quarantine_suggested": True
        }

    title = args.get("title")
    author = args.get("author")
    snippet = args.get("snippet", "")

    base_name = os.path.splitext(os.path.basename(path))[0]
    if not title or not author:
        if " - " in base_name:
            parts = base_name.split(" - ", 1)
            author = author or parts[0].strip()
            title = title or parts[1].strip()
        else:
            title = title or base_name
            author = author or "Unknown Author"

    state_text = f"Title: {title}\nAuthor: {author}\nFormat: {ext}\nExtracted_TOC: {snippet or base_name}"

    questions = [
        {"id": "is_ai_or_passive_income", "type": "boolean"},
        {
            "id": "primary_domain",
            "type": "enum",
            "options": [
                "ai_agent_architecture",
                "machine_learning_llm",
                "passive_income_business",
                "software_engineering",
                "general_fiction",
                "other_non_fiction"
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

    engine_res = query_engine_decide(state_text, questions)
    decisions = engine_res.get("decisions", {})

    is_ai_income = decisions.get("is_ai_or_passive_income", {}).get("value", False)
    domain = decisions.get("primary_domain", {}).get("value", "other_non_fiction")
    priority = decisions.get("brain_service_ingest_priority", {}).get("value", "skip_general_library_only")

    safe_author = re.sub(r'[/\\:*?"<>|]', "", author).strip() or "Unknown Author"
    safe_title = re.sub(r'[/\\:*?"<>|]', "", title).strip() or "Untitled"
    canonical_filename = f"{safe_author} - {safe_title}{ext}"
    canonical_rel_dir = os.path.join(safe_author, safe_title)
    canonical_library_path = os.path.join("/data/vault/library", canonical_rel_dir, canonical_filename)

    topic_subpath = None
    if domain == "ai_agent_architecture":
        topic_subpath = "/data/vault/library/by-topic/AI-Agents"
    elif domain == "machine_learning_llm":
        topic_subpath = "/data/vault/library/by-topic/Machine-Learning"
    elif domain == "passive_income_business":
        topic_subpath = "/data/vault/library/by-topic/Passive-Income"
    elif domain == "software_engineering":
        topic_subpath = "/data/vault/library/by-topic/Software-Engineering"

    rag_ingest_recommended = is_ai_income and (priority in ["p0_immediate_rag_ingest", "p1_standard_rag_ingest"])

    return {
        "status": "success",
        "file_path": path,
        "is_valid_ebook": True,
        "detected_metadata": {
            "title": title,
            "author": author,
            "format": ext,
            "canonical_filename": canonical_filename
        },
        "classification": {
            "is_ai_or_passive_income": is_ai_income,
            "primary_domain": domain,
            "brain_service_ingest_priority": priority,
            "rag_ingest_recommended": rag_ingest_recommended
        },
        "target_paths": {
            "library_file": canonical_library_path,
            "topic_symlink_dir": topic_subpath,
            "brain_service_inbox": "/var/lib/brain-service/inbox/" if rag_ingest_recommended else None
        },
        "decisions": decisions
    }


TOOL_HANDLERS = {
    "evaluate_decision": handle_evaluate_decision,
    "jev_evaluate_decision": handle_evaluate_decision,
    "jev_decide": handle_evaluate_decision,
    "jev_lead_triage": handle_jev_lead_triage,
    "jev_ad_hook_mine": handle_jev_ad_hook_mine,
    "jev_classify_batch": handle_jev_classify_batch,
    "triage_email_batch": handle_triage_email_batch,
    "classify_file_batch": handle_classify_file_batch,
    "trigger_jev_workflow": handle_trigger_jev_workflow,
    "triage_book_metadata": handle_triage_book_metadata,
}


def send_response(req_id, result=None, error=None):
    resp = {"jsonrpc": "2.0", "id": req_id}
    if error is not None:
        resp["error"] = error
    else:
        resp["result"] = result
    line = json.dumps(resp) + "\n"
    sys.stdout.write(line)
    sys.stdout.flush()


def main():
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            req = json.loads(line)
        except Exception:
            continue

        req_id = req.get("id")
        method = req.get("method")
        params = req.get("params", {})

        if method == "initialize":
            send_response(
                req_id,
                {
                    "protocolVersion": "2024-11-05",
                    "capabilities": {"tools": {}},
                    "serverInfo": {"name": "jev-decision-mcp", "version": "1.0.0"},
                },
            )
        elif method == "notifications/initialized":
            pass
        elif method == "tools/list":
            send_response(req_id, {"tools": TOOLS})
        elif method == "tools/call":
            tool_name = params.get("name")
            tool_args = params.get("arguments", {})
            handler = TOOL_HANDLERS.get(tool_name)
            if not handler:
                send_response(
                    req_id,
                    error={"code": -32601, "message": f"Tool '{tool_name}' not found"},
                )
            else:
                out = handler(tool_args)
                send_response(
                    req_id,
                    {
                        "content": [
                            {"type": "text", "text": json.dumps(out, indent=2)}
                        ]
                    },
                )
        else:
            if req_id is not None:
                send_response(
                    req_id,
                    error={"code": -32601, "message": f"Unhandled method '{method}'"},
                )


if __name__ == "__main__":
    main()
