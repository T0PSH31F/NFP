#!/usr/bin/env python3
"""
NFP Durable News & Signal Curation Engine
=========================================
Ingests web feeds, RSS, and webhooks via Jev; categorizes content into
Hype vs. Facts vs. Signal; dynamically weights topic preferences stored in
`.agents/memory/news_weights.json` (adjustable on-the-fly via chat/voice);
and persists ranked intelligence to SQLite.

Part of dendritic layer: layers/70-agents/71-harness/
"""

import sys
import os
import json
import re
import time
import sqlite3
import urllib.request
import urllib.error
from dataclasses import dataclass, asdict
from datetime import datetime, timezone
from pathlib import Path
from typing import List, Dict, Any, Optional, Tuple

REPO_ROOT = Path(__file__).resolve().parents[3]
DEFAULT_WEIGHTS_FILE = REPO_ROOT / ".agents/memory/news_weights.json"
DEFAULT_NEWS_DB = Path(os.environ.get("CURATED_NEWS_DB", Path.home() / ".local/share/jarvis/curated_news.sqlite"))

DEFAULT_TOPIC_WEIGHTS = {
    "ai_infrastructure": 1.5,
    "nix_linux": 1.4,
    "security_systems": 1.3,
    "general_tech": 0.8,
    "crypto_web3": 0.2
}

DEFAULT_TYPE_WEIGHTS = {
    "signal": 1.5,
    "facts": 1.0,
    "hype": 0.2
}

HYPE_TRIGGERS = [
    r"\b(game changer|revolutionary|mind-blowing|1000x|100x|skyrocketing|unbelievable|to the moon|insane|you won't believe|generational wealth)\b",
    r"\b(airdrop|presale|nft drop|memecoin|moonshot|pump)\b",
    r"!{2,}|\?{2,}",
]

SIGNAL_TRIGGERS = [
    r"\b(architecture|benchmark|rfc|compiler|kernel|post-mortem|zero-token|latency|throughput|optimization|reproducible|whitepaper|cve-[0-9]{4})\b",
    r"\b(nixpkgs|wayland|simd|sqlite|concurrency|distributed systems|memory footprint|cache hierarchy)\b",
]

DOMAIN_KEYWORDS = {
    "ai_infrastructure": ["llm", "inference", "vllm", "ollama", "onnx", "transformer", "latency", "gpu", "cuda", "weights", "fastconformer", "tts", "stt"],
    "nix_linux": ["nix", "nixos", "flake", "btrfs", "systemd", "kernel", "wayland", "hyprland", "niri", "cgroups", "pipewire"],
    "security_systems": ["cve", "vulnerability", "exploit", "auth", "zero-day", "sandbox", "crypto", "tls", "sops", "pam"],
    "crypto_web3": ["crypto", "bitcoin", "ethereum", "token", "web3", "defi", "nft", "blockchain", "solana"],
}

@dataclass
class NewsItem:
    item_id: str
    title: str
    summary: str
    url: str
    source: str
    published_at: str

@dataclass
class CuratedItem:
    item_id: str
    title: str
    summary: str
    url: str
    source: str
    category: str      # signal, facts, hype
    domain: str        # ai_infrastructure, nix_linux, security_systems, crypto_web3, general_tech
    score: float       # weighted composite score
    reason: str
    curated_at: str

class PreferenceWeightsManager:
    def __init__(self, filepath: Path = DEFAULT_WEIGHTS_FILE):
        self.filepath = filepath
        self.weights = self.load_weights()

    def load_weights(self) -> Dict[str, Any]:
        if self.filepath.exists():
            try:
                data = json.loads(self.filepath.read_text(encoding="utf-8"))
                return data
            except Exception:
                pass
        # Initialize default weights
        default_data = {
            "version": "1.0.0",
            "last_updated": datetime.now(timezone.utc).isoformat(),
            "topics": dict(DEFAULT_TOPIC_WEIGHTS),
            "content_types": dict(DEFAULT_TYPE_WEIGHTS)
        }
        self.save_weights(default_data)
        return default_data

    def save_weights(self, data: Optional[Dict[str, Any]] = None) -> None:
        if data is None:
            data = self.weights
        data["last_updated"] = datetime.now(timezone.utc).isoformat()
        self.filepath.parent.mkdir(parents=True, exist_ok=True)
        self.filepath.write_text(json.dumps(data, indent=2), encoding="utf-8")
        self.weights = data

    def adjust_via_intent(self, phrase: str) -> Dict[str, Any]:
        """
        Parses voice or chat commands such as:
        'More AI infrastructure signal, less crypto hype'
        'Increase nix linux focus'
        'Reduce crypto'
        """
        clean = phrase.lower()
        delta = 0.3
        changes = []

        # Increase detection
        if any(w in clean for w in ["more", "increase", "boost", "favor", "higher"]):
            if "ai" in clean or "infra" in clean:
                self.weights["topics"]["ai_infrastructure"] = round(self.weights["topics"].get("ai_infrastructure", 1.0) + delta, 2)
                changes.append("+ai_infrastructure")
            if "nix" in clean or "linux" in clean:
                self.weights["topics"]["nix_linux"] = round(self.weights["topics"].get("nix_linux", 1.0) + delta, 2)
                changes.append("+nix_linux")
            if "sec" in clean or "vuln" in clean:
                self.weights["topics"]["security_systems"] = round(self.weights["topics"].get("security_systems", 1.0) + delta, 2)
                changes.append("+security_systems")
            if "signal" in clean:
                self.weights["content_types"]["signal"] = round(self.weights["content_types"].get("signal", 1.0) + delta, 2)
                changes.append("+signal")

        # Decrease detection
        if any(w in clean for w in ["less", "decrease", "drop", "reduce", "lower", "cut"]):
            if "crypto" in clean or "web3" in clean or "nft" in clean:
                self.weights["topics"]["crypto_web3"] = max(0.0, round(self.weights["topics"].get("crypto_web3", 1.0) - delta, 2))
                changes.append("-crypto_web3")
            if "hype" in clean or "clickbait" in clean:
                self.weights["content_types"]["hype"] = max(0.0, round(self.weights["content_types"].get("hype", 0.5) - delta, 2))
                changes.append("-hype")
            if "general" in clean:
                self.weights["topics"]["general_tech"] = max(0.1, round(self.weights["topics"].get("general_tech", 1.0) - delta, 2))
                changes.append("-general_tech")

        self.save_weights()
        return {"status": "updated", "changes": changes, "weights": self.weights}

class NewsCurator:
    def __init__(self, weights_file: Path = DEFAULT_WEIGHTS_FILE, db_path: Path = DEFAULT_NEWS_DB):
        self.weights_mgr = PreferenceWeightsManager(weights_file)
        self.db_path = db_path
        self._init_db()

    def _init_db(self):
        try:
            self.db_path.parent.mkdir(parents=True, exist_ok=True)
            with sqlite3.connect(str(self.db_path)) as conn:
                conn.execute("""
                CREATE TABLE IF NOT EXISTS curated_news (
                    item_id TEXT PRIMARY KEY,
                    title TEXT NOT NULL,
                    summary TEXT NOT NULL,
                    url TEXT NOT NULL,
                    source TEXT NOT NULL,
                    category TEXT NOT NULL,
                    domain TEXT NOT NULL,
                    score REAL NOT NULL,
                    reason TEXT NOT NULL,
                    curated_at TEXT NOT NULL
                );
                """)
                conn.commit()
        except Exception as e:
            sys.stderr.write(f"Warning: Could not initialize curated news SQLite DB: {e}\n")

    def detect_domain(self, text: str) -> str:
        clean = text.lower()
        domain_scores = {d: 0 for d in DOMAIN_KEYWORDS}
        for domain, keywords in DOMAIN_KEYWORDS.items():
            for kw in keywords:
                if re.search(r"\b" + re.escape(kw) + r"\b", clean):
                    domain_scores[domain] += 1
        best_domain = max(domain_scores, key=domain_scores.get)
        if domain_scores[best_domain] > 0:
            return best_domain
        return "general_tech"

    def classify_item(self, item: NewsItem) -> CuratedItem:
        combined = f"{item.title} {item.summary}"
        domain = self.detect_domain(combined)

        # 1. Hype test
        hype_matches = [p for p in HYPE_TRIGGERS if re.search(p, combined, re.I)]
        # 2. Signal test
        signal_matches = [p for p in SIGNAL_TRIGGERS if re.search(p, combined, re.I)]

        if len(hype_matches) >= 2 or (len(hype_matches) >= 1 and domain == "crypto_web3"):
            category = "hype"
            base_score = 0.2
            reason = f"Detected hype triggers: {', '.join(hype_matches[:2])}"
        elif len(signal_matches) >= 1:
            category = "signal"
            base_score = 0.9 + min(0.1, len(signal_matches) * 0.05)
            reason = f"Technical depth & architecture signal triggers: {', '.join(signal_matches[:2])}"
        else:
            category = "facts"
            base_score = 0.6
            reason = "Standard informational or factual news update"

        # Apply weights from preference manager
        topic_weights = self.weights_mgr.weights.get("topics", DEFAULT_TOPIC_WEIGHTS)
        type_weights = self.weights_mgr.weights.get("content_types", DEFAULT_TYPE_WEIGHTS)

        t_weight = topic_weights.get(domain, 1.0)
        c_weight = type_weights.get(category, 1.0)
        final_score = round(base_score * t_weight * c_weight, 3)

        now_iso = datetime.now(timezone.utc).isoformat()
        return CuratedItem(
            item_id=item.item_id,
            title=item.title,
            summary=item.summary,
            url=item.url,
            source=item.source,
            category=category,
            domain=domain,
            score=final_score,
            reason=reason,
            curated_at=now_iso
        )

    def curate_and_store(self, items: List[NewsItem]) -> List[CuratedItem]:
        curated_list = [self.classify_item(item) for item in items]
        curated_list.sort(key=lambda x: x.score, reverse=True)

        try:
            with sqlite3.connect(str(self.db_path)) as conn:
                for c in curated_list:
                    conn.execute("""
                    INSERT INTO curated_news (item_id, title, summary, url, source, category, domain, score, reason, curated_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    ON CONFLICT(item_id) DO UPDATE SET score=excluded.score, category=excluded.category, reason=excluded.reason;
                    """, (c.item_id, c.title, c.summary, c.url, c.source, c.category, c.domain, c.score, c.reason, c.curated_at))
                conn.commit()
        except Exception:
            pass

        return curated_list

    def get_top_signals(self, limit: int = 10) -> List[Dict[str, Any]]:
        results = []
        try:
            with sqlite3.connect(str(self.db_path)) as conn:
                conn.row_factory = sqlite3.Row
                cur = conn.cursor()
                cur.execute("SELECT * FROM curated_news ORDER BY score DESC LIMIT ?", (limit,))
                for row in cur.fetchall():
                    results.append(dict(row))
        except Exception:
            pass
        return results

def self_test() -> int:
    print("==> Running News & Signal Curator Self-Test Suite...")
    test_weights = Path("/tmp/test_news_weights.json")
    test_db = Path("/tmp/test_curated_news.sqlite")
    if test_weights.exists():
        test_weights.unlink()
    if test_db.exists():
        test_db.unlink()

    curator = NewsCurator(weights_file=test_weights, db_path=test_db)

    # 1. Test weight seeding & dynamic intent shifting
    assert curator.weights_mgr.weights["topics"]["ai_infrastructure"] == 1.5
    res = curator.weights_mgr.adjust_via_intent("More AI infrastructure signal, less crypto hype")
    assert "+ai_infrastructure" in res["changes"]
    assert "-crypto_web3" in res["changes"]
    assert curator.weights_mgr.weights["topics"]["ai_infrastructure"] > 1.5
    assert curator.weights_mgr.weights["topics"]["crypto_web3"] < 0.2
    print("  [PASS] Preference weights initialized and dynamically shifted via voice intent")

    # 2. Test Triage Pipeline: Signal vs Hype vs Facts
    items = [
        NewsItem(
            item_id="item-001",
            title="Next-Gen NixOS Flake Kernel Benchmark: 40% Reduction in Boot Latency",
            summary="A deep dive into reproducible SIMD kernel optimizations and cgroup cache hierarchy.",
            url="https://cyberia.nfp/kernel-perf",
            source="nfp-feed",
            published_at="2026-10-29T12:00:00Z"
        ),
        NewsItem(
            item_id="item-002",
            title="INSANE 1000x MOONSHOT! You won't believe this new crypto token presale!",
            summary="A revolutionary generative wealth token guaranteed to skyrocket to the moon!!",
            url="https://hype.crypto/moon",
            source="shill-feed",
            published_at="2026-10-29T12:05:00Z"
        ),
        NewsItem(
            item_id="item-003",
            title="PostgreSQL 18.2 Released with Minor Bug Fixes",
            summary="Official announcement detailing scheduled quarterly maintenance release notes.",
            url="https://postgresql.org/news/18-2",
            source="postgres-feed",
            published_at="2026-10-29T12:10:00Z"
        )
    ]

    curated = curator.curate_and_store(items)
    assert len(curated) == 3

    # item-001 should be Signal
    sig_item = next(c for c in curated if c.item_id == "item-001")
    assert sig_item.category == "signal"
    assert sig_item.domain == "nix_linux"

    # item-002 should be Hype
    hype_item = next(c for c in curated if c.item_id == "item-002")
    assert hype_item.category == "hype"
    assert hype_item.domain == "crypto_web3"
    assert hype_item.score < sig_item.score

    # item-003 should be Facts
    facts_item = next(c for c in curated if c.item_id == "item-003")
    assert facts_item.category == "facts"

    print("  [PASS] Content triage correctly mapped Signal vs. Hype vs. Facts")

    # 3. Test SQLite persistence and ranking query
    top = curator.get_top_signals(5)
    assert len(top) == 3
    assert top[0]["item_id"] == "item-001"
    print("  [PASS] Curated news ranked and persisted in SQLite")

    if test_weights.exists():
        test_weights.unlink()
    if test_db.exists():
        test_db.unlink()

    print("==> All News Curator tests PASSED!")
    return 0

if __name__ == "__main__":
    if "--test" in sys.argv:
        sys.exit(self_test())
    elif "--adjust-weights" in sys.argv:
        idx = sys.argv.index("--adjust-weights")
        if idx + 1 < len(sys.argv):
            phrase = sys.argv[idx + 1]
            mgr = PreferenceWeightsManager()
            result = mgr.adjust_via_intent(phrase)
            print(json.dumps(result, indent=2))
        else:
            print("Error: --adjust-weights requires a phrase argument")
            sys.exit(1)
    elif "--top" in sys.argv:
        curator = NewsCurator()
        top_items = curator.get_top_signals(10)
        print(json.dumps(top_items, indent=2))
    else:
        print("Usage: news_curator.py [--test | --adjust-weights '<phrase>' | --top]")
