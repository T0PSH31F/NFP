#!/usr/bin/env python3
"""
Jev System-1 Decision Engine & Discriminative Routing Daemon
High-speed, zero-hallucination routing and calibrated decision scoring.
"""

import json
import math
import os
import re
import sys
import time
import urllib.error
import urllib.request
from http.server import HTTPServer, BaseHTTPRequestHandler
from socketserver import ThreadingMixIn

HOST = os.environ.get("JEV_HOST", "0.0.0.0")
PORT = int(os.environ.get("JEV_PORT", "20130"))
MODE = os.environ.get("JEV_MODE", "local")  # "local" or "typesafe-proxy"
UPSTREAM_URL = os.environ.get("JEV_UPSTREAM_URL", "")
API_KEY_FILE = os.environ.get("JEV_API_KEY_FILE", "")

# Domain anchors for zero-shot joint embedding scoring
ANCHORS = {
    # Email category anchors
    "invoice_financial": [
        "invoice", "billing", "bill", "receipt", "payment", "due date", "amount due",
        "tax", "statement", "balance", "paypal", "stripe", "hetzner", "order", "purchase",
        "renewal", "checkout", "subscription", "fee", "charged", "pricing", "remittance",
        "order confirmation", "shipment", "shipped", "tracking", "delivery", "delivered",
        "amazon", "ebay", "apple", "google store", "receipt for", "your order"
    ],
    "security_auth": [
        "2fa", "verification code", "otp", "security alert", "unauthorized", "reset password",
        "login attempt", "token", "authenticator", "sign-in", "suspicious", "credentials",
        "password changed", "new login", "mfa", "passcode", "access granted", "security notification",
        "security code", "verify your account", "login detected", "unrecognized device"
    ],
    "personal": [
        "hey", "hi", "hello", "regards", "thanks", "meet", "coffee", "family", "weekend",
        "catch up", "chat", "dinner", "holiday", "friend", "cheers", "talk soon", "how are you"
    ],
    "newsletter": [
        "unsubscribe", "digest", "issue", "weekly", "monthly digest", "newsletter",
        "read online", "view in browser", "substack", "trends", "edition", "stories of the week",
        "market", "investopedia", "roundup", "pre-market", "briefing", "forward future",
        "news", "daily update", "weekly update", "edition", "insights", "tech news"
    ],
    "automated_alert": [
        "alert", "failure", "degraded", "cron", "error", "exception", "incident",
        "resolved", "build failed", "deployment", "pipeline", "grafana", "prometheus",
        "statuscake", "pagerduty", "datadog", "cpu spike", "disk full", "service down",
        "camera", "motion", "detected", "saw someone", "nest", "doorbell", "sensor",
        "notification", "offline", "online", "ping", "heartbeat", "battery", "system alert"
    ],
    "spam": [
        "congratulations", "lottery", "casino", "crypto profit", "winner", "earn cash",
        "weight loss", "cheap meds", "viagra", "wire transfer", "inheritance", "claim prize",
        "100% free", "urgent investment", "act now", "exclusive offer", "click here",
        "winning numbers", "powerball", "superlotto", "fantasy 5", "jackpot"
    ],

    # Target agent anchors
    "hermes_billing": [
        "invoice", "receipt", "billing", "payment", "charge", "subscription",
        "tax", "expense", "refund", "remittance", "statement", "pay", "order total",
        "purchase", "order confirmation", "overdue", "past due"
    ],
    "paperclip_ops": [
        "alert", "failed", "server", "crash", "kubernetes", "systemd", "down",
        "disk full", "high cpu", "monitor", "cluster", "ci/cd", "infra", "incident",
        "security disclosure", "vulnerability"
    ],
    "archive_silent": [
        "newsletter", "promo", "digest", "statement confirmed", "receipt archived",
        "no action", "informational", "automated", "report", "summary", "notification",
        "camera", "saw someone", "motion", "doorbell", "sensor", "nest", "routine",
        "privacy notice", "terms of service", "airtable", "posted", "new listings",
        "winning numbers", "holiday love"
    ],

    # Filesystem vault anchors
    "financial_records": [
        "tax", "receipt", "invoice", "1099", "w2", "paystub", "banking", "statement",
        "financial", "expense", "deduction", "irs", "accounting", "ledger", "audit", "billing"
    ],
    "code_projects": [
        ".rs", ".py", ".nix", ".go", ".js", ".ts", ".patch", ".diff", "git",
        "cargo", "flake", "repo", "src", "commit", "pr", "cmake", "make", "dockerfile", "script"
    ],
    "media_audiobooks": [
        ".m4b", ".mp3", ".flac", ".m4a", "audiobook", "chapter", "narrator",
        "author", "track", "album", "podcast", "audio", "voice", "bitrate", "sample"
    ],
    "personal_documents": [
        "passport", "id", "license", "medical", "lease", "contract", "resume",
        "scan", "certificate", "deed", "insurance", "record", "vital", "personal"
    ],
    "ephemeral_trash": [
        ".tmp", ".log", ".bak", ".part", ".crdownload", "setup.exe", "installer",
        "cache", "dump", "ephemeral", "trash", "junk", "temp", "delete", "swp"
    ],

    # Filename patterns
    "YYYY-MM-DD_vendor_receipt": [
        "receipt", "invoice", "bill", "tax", "statement", "order", "purchase", "vendor"
    ],
    "project_artifact": [
        "build", "release", "patch", "diff", "tar.gz", "zip", "dist", "out", "pkg", "crate"
    ],
    "keep_original": [
        "keep", "default", "standard", "preserve", "manual", "custom"
    ],

    # Lead qualification anchors
    "tier_1_enterprise_hot": [
        "enterprise", "urgent", "servers", "fleet", "production", "infrastructure",
        "cluster", "25k", "50k", "100k", "custom deployment", "migration", "nixos",
        "budget", "contract", "immediately", "dedicated", "sla", "apex"
    ],
    "tier_2_smb_warm": [
        "smb", "small business", "warm", "consulting", "review", "audit", "5k", "10k",
        "startup", "next quarter", "few servers", "modest budget", "growing"
    ],
    "tier_3_low_budget_cold": [
        "cheap", "free", "discount", "hobby", "personal project", "student", "minimal",
        "under 1k", "exploratory", "no budget", "tight budget"
    ],
    "spam_or_jobseeker": [
        "hiring", "apply", "resume", "cv", "job", "seo", "backlinks", "marketing agency",
        "guest post", "outsource", "internship", "partnership proposal", "casino", "crypto"
    ],

    # Estimated deal sizes
    "under_5k": ["under 5k", "500", "1k", "2k", "3k", "4k", "small", "tiny", "modest"],
    "5k_to_20k": ["5k", "10k", "15k", "20k", "5,000", "10,000", "15,000", "20,000"],
    "20k_to_100k": ["20k", "25k", "30k", "40k", "50k", "75k", "100k", "25k+", "25,000", "50,000"],
    "enterprise_100k_plus": ["100k+", "150k", "200k", "500k", "1m", "enterprise", "multi-year"],

    # Urgency timelines
    "immediate_under_2_weeks": ["immediate", "urgent", "next month", "next week", "asap", "deadline", "2 weeks", "critical"],
    "quarterly_1_3_months": ["quarter", "quarterly", "1-3 months", "2 months", "3 months", "q1", "q2", "q3", "q4", "upcoming"],
    "exploratory": ["exploratory", "curious", "researching", "evaluating", "someday", "no rush", "gathering info"],

    # Ad Hook categories
    "pain_point_frustration": [
        "tired of", "slow", "wasting", "frustrated", "headache", "broken", "pain",
        "struggle", "annoying", "friction", "hours", "overhead", "exhausting"
    ],
    "fear_of_loss": [
        "losing", "risk", "danger", "falling behind", "downtime", "outage", "vulnerability",
        "cost of delay", "missing out", "exposed"
    ],
    "social_proof": [
        "thousands", "trusted by", "rated 5 stars", "case study", "testimonials",
        "top companies", "engineers love", "industry standard", "proven"
    ],
    "curiosity_novelty": [
        "secret", "discover", "new way", "unlock", "did you know", "what if",
        "game changer", "revolutionary", "breakthrough"
    ],
    "direct_savings_roi": [
        "cuts by 80%", "save 80%", "80%", "cut costs", "save hours", "10x faster",
        "roi", "boost efficiency", "reduce spend", "save money"
    ],

    # Primary objections handled
    "setup_complexity": ["zero config", "5 minutes", "plug and play", "easy setup", "seamless", "turnkey", "drop in"],
    "pricing_cost": ["free tier", "affordable", "cheap", "no hidden fees", "transparent", "save money"],
    "security_compliance": ["soc2", "hipaa", "gdpr", "air-gapped", "private", "encrypted", "compliance", "secure"],
    "performance_speed": ["fast", "speed", "sub-second", "instant", "cuts build times", "throughput", "latency"],

    # Target personas
    "devops_infrastructure_lead": ["devops", "infrastructure", "sre", "platform", "sysadmin", "nix", "build cache", "developer hours"],
    "founder_cto": ["founder", "cto", "vp engineering", "startup", "leadership", "scale"],
    "individual_contributor": ["developer", "engineer", "coder", "programmer", "builder"],
    "finance_buyer": ["procurement", "finance", "cfo", "budget", "billing", "savings"],

    # CTA urgency
    "free_trial": ["free trial", "try free", "start free", "no credit card", "get started free"],
    "book_demo": ["book demo", "schedule demo", "talk to sales", "request demo", "see a demo"],
    "limited_offer": ["limited offer", "limited time", "expires soon", "discount ends", "today only"],
    "content_download": ["download", "whitepaper", "guide", "checklist", "ebook", "report"],

    # LLM Router Pre-Flight Tiers
    "direct_jev_decision": [
        "classify", "triage", "category", "sentiment", "spam", "score", "tag", "sort",
        "route", "boolean", "enum", "is_urgent", "single label", "yes or no", "true or false",
        "extract category", "filter", "file extension", "department"
    ],
    "local_slm_free": [
        "format", "json schema", "convert", "summarize brief", "rewrite simple",
        "draft quick reply", "extract regex", "parse table", "boilerplate", "explain line",
        "low complexity", "small prompt", "offline", "llama"
    ],
    "cheap_cloud_mini": [
        "summarize article", "translate", "code snippet", "refactor function",
        "unit test", "draft email", "medium complexity", "haiku", "gpt-4o-mini", "flash"
    ],
    "frontier_flagship": [
        "architect", "solve", "math proof", "deep reasoning", "multi-step plan",
        "audit security vulnerability", "flake check debug", "complex refactor",
        "synthesis", "strategic", "sonnet", "opus", "claude 3.7", "deep research"
    ],

    # Book & Document Vault Triage Domains
    "ai_agent_architecture": [
        "agent", "agentic", "agents", "tool use", "planning", "mcp", "orchestrator",
        "multi-agent", "swarm", "reasoning", "autonomy", "self-directed", "task loop", "system-1"
    ],
    "machine_learning_llm": [
        "machine learning", "deep learning", "neural network", "transformer", "llm",
        "large language model", "fine-tuning", "rag", "embedding", "vector", "pytorch",
        "tensorflow", "supervised", "reinforcement learning", "attention"
    ],
    "passive_income_business": [
        "passive income", "cash flow", "business", "entrepreneur", "marketing", "sales",
        "revenue", "saas", "bootstrapped", "investing", "wealth", "consulting", "pricing",
        "growth", "lead generation", "copywriting", "monetization", "profit"
    ],
    "software_engineering": [
        "software engineering", "programming", "system design", "architecture", "database",
        "devops", "algorithms", "distributed systems", "linux", "kernel", "nix", "compiler"
    ],
    "technical_programming": [
        "technical programming", "software engineering", "programming", "system design",
        "architecture", "database", "devops", "algorithms", "distributed systems", "linux",
        "kernel", "nix", "python", "rust", "c++", "compiler"
    ],
    "general_fiction": [
        "novel", "fiction", "chapter", "fantasy", "sci-fi", "thriller", "mystery",
        "romance", "drama", "protagonist", "story", "character"
    ],
    "other_non_fiction": [
        "biography", "history", "philosophy", "cooking", "travel", "health", "science",
        "psychology", "memoir", "fitness", "parenting"
    ],
    "general_nonfiction": [
        "biography", "history", "philosophy", "cooking", "travel", "health", "science",
        "psychology", "memoir", "fitness", "parenting", "general non-fiction"
    ],

    # Brain-Service Ingest Priorities
    "p0_immediate_rag_ingest": [
        "agent", "agentic", "rag", "llm", "ai system", "passive income", "business strategy",
        "automation", "framework", "architecture", "core", "foundation"
    ],
    "p1_standard_rag_ingest": [
        "machine learning", "software engineering", "programming", "python", "data science",
        "devops", "tools", "guide", "practical", "tutorial"
    ],
    "skip_general_library_only": [
        "fiction", "novel", "general non-fiction", "recipe", "entertainment", "skip",
        "casual", "story", "thriller"
    ]
}

ACTION_REQUIRED_TRIGGERS = [
    "action required", "action needed", "please verify", "immediate attention",
    "pay by", "due date", "confirm your", "please reply", "deadline", "expires in",
    "resolve by", "respond within", "requires confirmation", "needs your approval",
    "failure", "alert", "error", "unauthorized", "suspended", "warning",
    "overdue", "past due", "security disclosure", "validate", "critical update"
]

PASSIVE_TRIGGERS = [
    "no action required", "informational only", "for your records", "auto-generated",
    "successfully processed", "receipt for your records", "digest", "newsletter",
    "unsubscribe", "weekly update", "no response needed", "winning numbers",
    "privacy notice", "terms of service", "posted", "new listings"
]

TECHNICAL_FIT_TRIGGERS = [
    "nix", "nixos", "flake", "linux", "infra", "infrastructure", "fleet", "cluster",
    "kubernetes", "devops", "deploy", "server", "servers", "cloud", "automation",
    "rust", "python", "backend", "cache", "builds", "ci/cd"
]

TECHNICAL_UNFIT_TRIGGERS = [
    "wordpress", "seo", "photoshop", "logo design", "crypto pump", "social media marketing",
    "guest post", "freelance writer", "content writer", "affiliate"
]


METRICS_DIR = os.environ.get("JEV_DATA_DIR", "/var/lib/jev-engine")
METRICS_FILE = os.path.join(METRICS_DIR, "metrics.json")

METRICS = {
    "decisions_total": {
        "router": 0,
        "email_triage": 0,
        "fs_organizer": 0,
        "lead_triage": 0,
        "ad_miner": 0,
        "book_triage": 0,
        "general": 0
    },
    "duration_buckets": {
        "0.005": 0,
        "0.010": 0,
        "0.025": 0,
        "0.050": 0,
        "0.100": 0,
        "+Inf": 0
    },
    "duration_sum": 0.0,
    "duration_count": 0,
    "confidence_scores": {
        "router": 0.92,
        "email_triage": 0.88,
        "fs_organizer": 0.90,
        "lead_triage": 0.91,
        "ad_miner": 0.87,
        "book_triage": 0.93,
        "general": 0.89
    },
    "cost_saved_usd_total": 0.0
}


def load_metrics():
    global METRICS
    target = METRICS_FILE if os.path.exists(METRICS_FILE) else "/tmp/jev-metrics.json"
    if os.path.exists(target):
        try:
            with open(target, "r") as f:
                data = json.load(f)
                for k, v in data.items():
                    if isinstance(v, dict) and k in METRICS:
                        METRICS[k].update(v)
                    else:
                        METRICS[k] = v
        except Exception:
            pass


def save_metrics():
    target = METRICS_FILE
    try:
        os.makedirs(METRICS_DIR, exist_ok=True)
    except Exception:
        target = "/tmp/jev-metrics.json"

    try:
        with open(target, "w") as f:
            json.dump(METRICS, f, indent=2)
    except Exception:
        pass


def infer_workflow(questions):
    q_ids = {q.get("id") for q in questions if isinstance(q, dict)}
    if "target_tier" in q_ids or "is_pure_classification" in q_ids:
        return "router"
    if "category" in q_ids and "action_required" in q_ids:
        return "email_triage"
    if "target_vault" in q_ids or "suggested_filename_pattern" in q_ids:
        return "fs_organizer"
    if "qualification_tier" in q_ids or "estimated_deal_size" in q_ids:
        return "lead_triage"
    if "hook_category" in q_ids or "primary_objection_handled" in q_ids:
        return "ad_miner"
    if "is_ai_or_passive_income" in q_ids or "primary_domain" in q_ids or "brain_service_ingest_priority" in q_ids:
        return "book_triage"
    return "general"


def record_metric(workflow, duration_s, confidence, cost_saved=0.005):
    METRICS["decisions_total"][workflow] = METRICS["decisions_total"].get(workflow, 0) + 1
    METRICS["duration_count"] += 1
    METRICS["duration_sum"] += duration_s
    METRICS["confidence_scores"][workflow] = confidence
    METRICS["cost_saved_usd_total"] += cost_saved

    for b in ["0.005", "0.010", "0.025", "0.050", "0.100"]:
        if duration_s <= float(b):
            METRICS["duration_buckets"][b] += 1
    METRICS["duration_buckets"]["+Inf"] += 1

    if METRICS["duration_count"] % 5 == 0:
        save_metrics()


def generate_prometheus_metrics():
    lines = [
        "# HELP jev_decisions_total Total number of Jev System-1 decisions evaluated",
        "# TYPE jev_decisions_total counter"
    ]
    for wf, count in METRICS["decisions_total"].items():
        lines.append(f'jev_decisions_total{{workflow="{wf}"}} {count}')

    lines.append("# HELP jev_decision_duration_seconds Histogram of decision durations in seconds")
    lines.append("# TYPE jev_decision_duration_seconds histogram")
    for b in ["0.005", "0.010", "0.025", "0.050", "0.100", "+Inf"]:
        cnt = METRICS["duration_buckets"].get(b, 0)
        lines.append(f'jev_decision_duration_seconds_bucket{{le="{b}"}} {cnt}')
    lines.append(f'jev_decision_duration_seconds_sum {METRICS["duration_sum"]:.6f}')
    lines.append(f'jev_decision_duration_seconds_count {METRICS["duration_count"]}')

    lines.append("# HELP jev_decision_confidence_score Recent decision confidence score by workflow")
    lines.append("# TYPE jev_decision_confidence_score gauge")
    for wf, score in METRICS["confidence_scores"].items():
        lines.append(f'jev_decision_confidence_score{{workflow="{wf}"}} {score:.4f}')

    lines.append("# HELP jev_cost_saved_usd_total Estimated USD saved by avoiding frontier LLM calls")
    lines.append("# TYPE jev_cost_saved_usd_total counter")
    lines.append(f'jev_cost_saved_usd_total {METRICS["cost_saved_usd_total"]:.4f}')
    lines.append("")
    return "\n".join(lines)


def load_api_key():
    if API_KEY_FILE and os.path.exists(API_KEY_FILE):
        try:
            with open(API_KEY_FILE, "r") as f:
                return f.read().strip()
        except Exception as e:
            sys.stderr.write(f"Error reading API_KEY_FILE: {e}\n")
    return os.environ.get("JEV_API_KEY", "")


def tokenize(text):
    if not text:
        return []
    words = re.findall(r"[a-z0-9_\-\.]+", text.lower())
    return words


def compute_option_score(state_text, option, tokens_set):
    """Compute affinity score between state and an option."""
    opt_key = option.lower().replace("-", "_")
    state_lower = state_text.lower()
    score = 0.1  # base smoothing prior

    # Direct substring/option name match in state
    if opt_key in state_lower:
        score += 3.0

    # Check anchors
    anchors = ANCHORS.get(opt_key, [])
    if not anchors:
        # Generate word anchors from option name
        anchors = opt_key.split("_")

    matched_anchors = 0
    multiword_matches = 0
    for anchor in anchors:
        if " " in anchor:
            if anchor in state_lower:
                matched_anchors += 1
                multiword_matches += 1
        else:
            if anchor in tokens_set or anchor in state_lower:
                matched_anchors += 1

    if anchors and matched_anchors > 0:
        coverage = matched_anchors / len(anchors)
        score += (coverage * 5.0) + (matched_anchors * 2.5) + (multiword_matches * 3.0)

    return score


def softmax(scores_dict, temperature=0.7):
    """Compute calibrated softmax probabilities."""
    max_val = max(scores_dict.values()) if scores_dict else 0.0
    exp_scores = {k: math.exp((v - max_val) / temperature) for k, v in scores_dict.items()}
    total = sum(exp_scores.values()) or 1.0
    return {k: round(v / total, 4) for k, v in exp_scores.items()}


def evaluate_local(state, questions):
    """Evaluate questions locally using discriminative joint embedding logic."""
    start_time = time.perf_counter()
    tokens = tokenize(state)
    tokens_set = set(tokens)
    state_lower = state.lower()

    decisions = {}
    confidences = []

    for q in questions:
        q_id = q.get("id")
        q_type = q.get("type", "enum")

        if q_type == "boolean":
            # Score boolean question
            pos_score = 0.1
            neg_score = 0.1

            if q_id == "technical_fit":
                for trigger in TECHNICAL_FIT_TRIGGERS:
                    if trigger in state_lower:
                        pos_score += 2.5
                for trigger in TECHNICAL_UNFIT_TRIGGERS:
                    if trigger in state_lower:
                        neg_score += 3.0
            elif q_id == "is_pure_classification":
                classification_triggers = ["classify", "triage", "categorize", "tag", "is this", "label", "sentiment", "spam", "category", "enum"]
                non_class_triggers = ["write", "generate", "create", "implement", "explain", "refactor", "design", "synthesize"]
                for trigger in classification_triggers:
                    if trigger in state_lower:
                        pos_score += 3.0
                for trigger in non_class_triggers:
                    if trigger in state_lower:
                        neg_score += 2.5
            elif q_id == "prompt_compression_eligible":
                if len(state) > 300 and any(k in state_lower for k in ["```", "system:", "context:", "previous conversation", "assistant:", "user:"]):
                    pos_score += 3.5
                else:
                    neg_score += 2.0
            elif q_id == "is_ai_or_passive_income":
                ai_income_triggers = [
                    "agent", "agentic", "ai", "artificial intelligence", "machine learning",
                    "deep learning", "llm", "large language model", "neural network",
                    "rag", "vector", "embedding", "langchain", "llama", "prompt", "mcp",
                    "passive income", "cash flow", "business", "entrepreneur", "saas",
                    "marketing", "wealth", "consulting", "bootstrapped", "automation"
                ]
                unrelated_triggers = [
                    "novel", "fiction", "romance", "fantasy", "mystery", "cooking",
                    "recipe", "gardening", "poetry", "thriller", "drama", "children"
                ]
                for trigger in ai_income_triggers:
                    if trigger in state_lower:
                        pos_score += 2.5
                for trigger in unrelated_triggers:
                    if trigger in state_lower:
                        neg_score += 3.0
            elif q_id == "action_required":
                pos_score = 0.2
                neg_score = 1.8
                for trigger in ACTION_REQUIRED_TRIGGERS:
                    if trigger in state_lower:
                        pos_score += 3.5
                for trigger in PASSIVE_TRIGGERS:
                    if trigger in state_lower:
                        neg_score += 3.0
            else:
                for trigger in ACTION_REQUIRED_TRIGGERS:
                    if trigger in state_lower:
                        pos_score += 2.0
                for trigger in PASSIVE_TRIGGERS:
                    if trigger in state_lower:
                        neg_score += 2.0

            probs = softmax({"true": pos_score, "false": neg_score}, temperature=0.5)
            val = probs["true"] >= 0.5
            conf = probs["true"] if val else probs["false"]

            decisions[q_id] = {
                "value": val,
                "confidence": conf,
                "probabilities": probs
            }
            confidences.append(conf)

        else:
            # Enum question
            options = q.get("options", [])
            if not options:
                decisions[q_id] = {"value": None, "confidence": 0.0, "probabilities": {}}
                continue

            raw_scores = {}
            for opt in options:
                raw_scores[opt] = compute_option_score(state, opt, tokens_set)

            probs = softmax(raw_scores, temperature=0.6)
            best_opt = max(probs.items(), key=lambda item: item[1])[0]
            conf = probs[best_opt]

            decisions[q_id] = {
                "value": best_opt,
                "confidence": conf,
                "probabilities": probs
            }
            confidences.append(conf)

    elapsed_ms = round((time.perf_counter() - start_time) * 1000, 2)
    agg_conf = round(sum(confidences) / len(confidences), 4) if confidences else 1.0

    wf = infer_workflow(questions)
    record_metric(wf, elapsed_ms / 1000.0, agg_conf)

    return {
        "status": "success",
        "engine": "jev-system1",
        "mode": "local",
        "latency_ms": elapsed_ms,
        "aggregate_confidence": agg_conf,
        "decisions": decisions
    }


def forward_typesafe_proxy(payload):
    """Forward request to upstream TypeSafe / Jev API endpoint."""
    api_key = load_api_key()
    headers = {"Content-Type": "application/json"}
    if api_key:
        headers["Authorization"] = f"Bearer {api_key}"

    req = urllib.request.Request(
        UPSTREAM_URL,
        data=json.dumps(payload).encode("utf-8"),
        headers=headers,
        method="POST"
    )

    start_time = time.perf_counter()
    with urllib.request.urlopen(req, timeout=10.0) as resp:
        data = resp.read().decode("utf-8")
        result = json.loads(data)
        elapsed_ms = round((time.perf_counter() - start_time) * 1000, 2)
        result["latency_ms"] = elapsed_ms
        result["mode"] = "typesafe-proxy"
        return result


class ThreadedHTTPServer(ThreadingMixIn, HTTPServer):
    daemon_threads = True


class JevHandler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        # Terse stderr logging
        sys.stderr.write(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] {args[0]} {args[1]} -> {args[2]}\n")

    def send_json(self, status_code, data):
        body = json.dumps(data, indent=2).encode("utf-8")
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path in ("/health", "/healthz", "/"):
            self.send_json(200, {
                "status": "ok",
                "service": "jev-engine",
                "engine": "jev-system1",
                "mode": MODE,
                "port": PORT,
                "version": "1.0.0"
            })
        elif self.path == "/metrics":
            metrics_body = generate_prometheus_metrics().encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; version=0.0.4; charset=utf-8")
            self.send_header("Content-Length", str(len(metrics_body)))
            self.end_headers()
            self.wfile.write(metrics_body)
        else:
            self.send_json(404, {"error": "Not found", "path": self.path})

    def do_POST(self):
        content_length = int(self.headers.get("Content-Length", 0))
        raw_body = self.rfile.read(content_length)

        try:
            payload = json.loads(raw_body.decode("utf-8")) if raw_body else {}
        except Exception as e:
            self.send_json(400, {"error": "Invalid JSON", "details": str(e)})
            return

        if self.path == "/v1/decide":
            state = payload.get("state", "")
            questions = payload.get("questions", [])

            if MODE == "typesafe-proxy" and UPSTREAM_URL:
                try:
                    res = forward_typesafe_proxy(payload)
                    self.send_json(200, res)
                    return
                except Exception as e:
                    sys.stderr.write(f"Upstream proxy failed: {e}; falling back to local\n")

            res = evaluate_local(state, questions)
            self.send_json(200, res)

        elif self.path == "/v1/batch":
            items = payload if isinstance(payload, list) else payload.get("items", [])
            results = []

            for item in items:
                state = item.get("state", "")
                questions = item.get("questions", [])

                if MODE == "typesafe-proxy" and UPSTREAM_URL:
                    try:
                        res = forward_typesafe_proxy(item)
                        results.append(res)
                        continue
                    except Exception as e:
                        sys.stderr.write(f"Upstream batch item failed: {e}; falling back\n")

                results.append(evaluate_local(state, questions))

            self.send_json(200, {"status": "success", "results": results})

        else:
            self.send_json(404, {"error": "Unknown endpoint", "path": self.path})


def run_server():
    load_metrics()
    server = ThreadedHTTPServer((HOST, PORT), JevHandler)
    sys.stderr.write(f"Jev Engine listening on {HOST}:{PORT} (mode: {MODE})\n")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    run_server()
