#!/usr/bin/env python3
"""
NFP Automated Website Reverse-Engineering Tooling
=================================================
Reverse-engineers external web applications for architectural analysis:
  - Inspects frontend tech stacks (Next.js, React, Vue, Svelte, WebGL).
  - Detects 3D libraries & scroll animation engines (Three.js, GSAP, Lenis, Spline).
  - Maps discovered REST, GraphQL, and WebSocket API endpoints.
  - Extracts and inventories static assets (SVGs, fonts, scripts, stylesheets).
  - Exports structured analysis reports to scratch directory for local inspection.

Part of dendritic layer: layers/70-agents/79-skills/reverse_engineer/
"""

import sys
import os
import re
import json
import urllib.request
import urllib.parse
from dataclasses import dataclass, asdict
from datetime import datetime, timezone
from pathlib import Path
from typing import List, Dict, Any, Optional, Set

REPO_ROOT = Path(__file__).resolve().parents[4]
OUTPUT_DIR = REPO_ROOT / "scratch/reverse_engineer"

TECH_SIGNATURES = {
    "react": [r"react(?:\.production|\.development)?\.js", r"__reactFiber", r"react-dom"],
    "nextjs": [r"/_next/static/", r"__NEXT_DATA__", r"next/head"],
    "vue": [r"vue(?:\.runtime)?(?:\.global)?\.js", r"v-bind", r"__VUE__"],
    "svelte": [r"svelte-[a-z0-9]+", r"svelte/internal"],
    "tailwind": [r"tailwindcss", r"(?:flex|grid|p-[0-9]|m-[0-9]|bg-[a-z0-9\-]+|text-[a-z0-9\-]+)"],
    "threejs": [r"three(?:\.min)?\.js", r"\bTHREE\.[A-Z]", r"webgl", r"meshBasicMaterial"],
    "gsap": [r"gsap(?:\.min)?\.js", r"ScrollTrigger", r"TweenMax", r"TimelineMax"],
    "lenis": [r"@studio-freight/lenis", r"lenis(?:\.min)?\.js", r"data-lenis-prevent"],
    "framer_motion": [r"framer-motion", r"motion\.[a-z0-9]+"],
    "spline": [r"@splinetool/runtime", r"\.splinecode"],
}

@dataclass
class ReverseEngineeringReport:
    target_url: str
    analyzed_at: str
    detected_frameworks: List[str]
    animation_engines: List[str]
    api_endpoints: List[str]
    asset_inventory: Dict[str, List[str]]
    metadata: Dict[str, Any]

class WebReverseEngineer:
    def __init__(self, output_dir: Path = OUTPUT_DIR):
        self.output_dir = output_dir
        self.output_dir.mkdir(parents=True, exist_ok=True)

    def analyze_source(self, html_content: str, base_url: str = "https://example.com") -> ReverseEngineeringReport:
        """Parses HTML and scripts to extract tech stack, animation engines, and endpoints."""
        now_iso = datetime.now(timezone.utc).isoformat()
        detected_frameworks: List[str] = []
        animation_engines: List[str] = []
        api_endpoints: Set[str] = set()

        # 1. Tech stack detection
        for tech, patterns in TECH_SIGNATURES.items():
            for pat in patterns:
                if re.search(pat, html_content, re.I):
                    if tech in ("threejs", "gsap", "lenis", "framer_motion", "spline"):
                        if tech not in animation_engines:
                            animation_engines.append(tech)
                    else:
                        if tech not in detected_frameworks:
                            detected_frameworks.append(tech)
                    break

        # 2. API Endpoint extraction
        endpoint_patterns = [
            r'["\'](/api/[a-zA-Z0-9_\-\/\?&=%\.]+)["\']',
            r'["\'](https?://[a-zA-Z0-9_\-\.]+(?::[0-9]+)?/[a-zA-Z0-9_\-\/\?&=%\.]+)["\']',
            r'["\'](wss?://[a-zA-Z0-9_\-\.]+(?::[0-9]+)?/[a-zA-Z0-9_\-\/\?&=%\.]+)["\']',
            r'["\'](/v[1-9]/[a-zA-Z0-9_\-\/\?&=%\.]+)["\']',
            r'["\'](/graphql[a-zA-Z0-9_\-\/\?&=%\.]*)["\']',
        ]
        for pat in endpoint_patterns:
            matches = re.findall(pat, html_content)
            for m in matches:
                api_endpoints.add(m)

        # 3. Static Asset extraction
        assets: Dict[str, List[str]] = {
            "scripts": [],
            "stylesheets": [],
            "images": [],
            "fonts": []
        }

        # Extract <script src="...">
        for s in re.findall(r'<script[^>]+src=["\']([^"\']+)["\']', html_content, re.I):
            assets["scripts"].append(s)

        # Extract <link rel="stylesheet" href="...">
        for c in re.findall(r'<link[^>]+href=["\']([^"\']+\.css[^"\']*)["\']', html_content, re.I):
            assets["stylesheets"].append(c)

        # Extract <img src="...">
        for img in re.findall(r'<img[^>]+src=["\']([^"\']+)["\']', html_content, re.I):
            assets["images"].append(img)

        # Extract font files
        for fnt in re.findall(r'["\']([^"\']+\.(?:woff2?|ttf|otf)[^"\']*)["\']', html_content, re.I):
            assets["fonts"].append(fnt)

        report = ReverseEngineeringReport(
            target_url=base_url,
            analyzed_at=now_iso,
            detected_frameworks=detected_frameworks,
            animation_engines=animation_engines,
            api_endpoints=sorted(list(api_endpoints)),
            asset_inventory=assets,
            metadata={
                "html_length_bytes": len(html_content),
                "script_count": len(assets["scripts"]),
                "stylesheet_count": len(assets["stylesheets"]),
                "image_count": len(assets["images"]),
                "api_endpoint_count": len(api_endpoints)
            }
        )
        return report

    def save_report(self, report: ReverseEngineeringReport, domain_tag: str = "target") -> Path:
        """Saves JSON report to output directory."""
        target_dir = self.output_dir / domain_tag
        target_dir.mkdir(parents=True, exist_ok=True)
        report_file = target_dir / "report.json"
        report_file.write_text(json.dumps(asdict(report), indent=2), encoding="utf-8")
        return report_file

def self_test() -> int:
    print("==> Running Automated Web Reverse-Engineering Self-Test Suite...")
    test_out = Path("/tmp/test_reverse_engineer")
    test_out.mkdir(parents=True, exist_ok=True)

    engineer = WebReverseEngineer(output_dir=test_out)

    sample_html = """<!DOCTYPE html>
<html>
<head>
  <link rel="stylesheet" href="/_next/static/css/styles.css">
  <link rel="preload" href="/fonts/outfit.woff2" as="font">
  <script src="/_next/static/chunks/main.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.2/ScrollTrigger.min.js"></script>
</head>
<body class="bg-gray-900 text-white flex p-4">
  <img src="/assets/hero-mockup.svg" alt="Mockup">
  <div id="__NEXT_DATA__">{"props":{}}</div>
  <script>
    fetch('/api/v1/telemetry/nodes').then(r => r.json());
    const socket = new WebSocket('wss://stream.cyberia.internal/ws');
  </script>
</body>
</html>"""

    report = engineer.analyze_source(sample_html, base_url="https://cyberia.internal")

    # 1. Verify tech stack detection
    assert "nextjs" in report.detected_frameworks
    assert "tailwind" in report.detected_frameworks
    print(f"  [PASS] Tech stack identified: {report.detected_frameworks}")

    # 2. Verify 3D & scroll animation engine detection
    assert "threejs" in report.animation_engines
    assert "gsap" in report.animation_engines
    print(f"  [PASS] 3D scroll animations identified: {report.animation_engines}")

    # 3. Verify API endpoint mapping
    assert "/api/v1/telemetry/nodes" in report.api_endpoints
    assert "wss://stream.cyberia.internal/ws" in report.api_endpoints
    print(f"  [PASS] API endpoints mapped: {report.api_endpoints}")

    # 4. Verify static asset inventory
    assert "/_next/static/chunks/main.js" in report.asset_inventory["scripts"]
    assert "/assets/hero-mockup.svg" in report.asset_inventory["images"]
    assert "/fonts/outfit.woff2" in report.asset_inventory["fonts"]
    print(f"  [PASS] Asset inventory extracted ({report.metadata['script_count']} scripts, {report.metadata['image_count']} images)")

    # 5. Verify file output
    saved_path = engineer.save_report(report, domain_tag="test_site")
    assert saved_path.exists()
    print("  [PASS] Reverse-engineering JSON report persisted to scratch directory")

    print("==> All Web Reverse-Engineering tests PASSED!")
    return 0

if __name__ == "__main__":
    if "--test" in sys.argv:
        sys.exit(self_test())
    elif "--inspect" in sys.argv:
        idx = sys.argv.index("--inspect")
        if idx + 1 < len(sys.argv):
            target = sys.argv[idx + 1]
            engineer = WebReverseEngineer()
            try:
                if target.startswith("http://") or target.startswith("https://"):
                    req = urllib.request.Request(target, headers={"User-Agent": "Mozilla/5.0 (NFP ReverseEngineer)"})
                    with urllib.request.urlopen(req, timeout=10) as resp:
                        content = resp.read().decode("utf-8", errors="ignore")
                else:
                    content = Path(target).read_text(encoding="utf-8")
                rep = engineer.analyze_source(content, base_url=target)
                out = engineer.save_report(rep, domain_tag="inspected")
                print(f"Audit completed. Report saved to: {out}")
            except Exception as e:
                print(f"Inspection error: {e}")
                sys.exit(1)
        else:
            print("Error: --inspect requires a URL or file path")
            sys.exit(1)
    else:
        print("Usage: reverse_engineer.py [--test | --inspect <url_or_filepath>]")
