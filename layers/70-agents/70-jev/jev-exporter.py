#!/usr/bin/env python3
"""
Jev System-1 Prometheus Metrics Exporter
Exposes real-time decision throughput, latency histograms, confidence distribution,
and estimated token cost savings on port 20132 for Prometheus scraping.
"""

import json
import os
import sys
import time
import urllib.error
import urllib.request
from http.server import HTTPServer, BaseHTTPRequestHandler
from socketserver import ThreadingMixIn

HOST = os.environ.get("JEV_EXPORTER_HOST", "0.0.0.0")
PORT = int(os.environ.get("JEV_EXPORTER_PORT", "20132"))
JEV_ENGINE_URL = os.environ.get("JEV_ENGINE_URL", "http://127.0.0.1:20130")
METRICS_DIR = os.environ.get("JEV_DATA_DIR", "/var/lib/jev-engine")
METRICS_FILE = os.path.join(METRICS_DIR, "metrics.json")


def fetch_engine_metrics():
    """Attempt to scrape metrics from upstream jev-engine."""
    url = f"{JEV_ENGINE_URL.rstrip('/')}/metrics"
    try:
        req = urllib.request.Request(url, method="GET")
        with urllib.request.urlopen(req, timeout=1.5) as resp:
            if resp.status == 200:
                return resp.read().decode("utf-8"), True
    except Exception:
        pass
    return None, False


def load_file_metrics():
    """Load cached metrics from disk if engine is offline or asynchronous."""
    for path in [METRICS_FILE, "/tmp/jev-metrics.json"]:
        if os.path.exists(path):
            try:
                with open(path, "r", encoding="utf-8") as f:
                    return json.load(f)
            except Exception:
                pass
    return None


def format_prometheus_metrics(state, engine_up):
    """Format metrics dictionary into standard Prometheus exposition format."""
    lines = [
        "# HELP jev_exporter_up Whether the Jev metrics exporter is functioning",
        "# TYPE jev_exporter_up gauge",
        "jev_exporter_up 1",
        "# HELP jev_engine_up Whether the Jev decision engine daemon is reachable",
        "# TYPE jev_engine_up gauge",
        f"jev_engine_up {1 if engine_up else 0}",
    ]

    decisions = state.get("decisions_total", {})
    lines.extend([
        "# HELP jev_decisions_total Total number of Jev System-1 decisions evaluated",
        "# TYPE jev_decisions_total counter"
    ])
    for wf, count in decisions.items():
        lines.append(f'jev_decisions_total{{workflow="{wf}"}} {count}')

    lines.extend([
        "# HELP jev_decision_duration_seconds Histogram of decision durations in seconds",
        "# TYPE jev_decision_duration_seconds histogram"
    ])
    buckets = state.get("duration_buckets", {})
    for b in ["0.005", "0.010", "0.025", "0.050", "0.100", "+Inf"]:
        cnt = buckets.get(b, 0)
        lines.append(f'jev_decision_duration_seconds_bucket{{le="{b}"}} {cnt}')
    lines.append(f'jev_decision_duration_seconds_sum {state.get("duration_sum", 0.0):.6f}')
    lines.append(f'jev_decision_duration_seconds_count {state.get("duration_count", 0)}')

    conf = state.get("confidence_scores", {})
    lines.extend([
        "# HELP jev_decision_confidence_score Recent decision confidence score by workflow",
        "# TYPE jev_decision_confidence_score gauge"
    ])
    for wf, score in conf.items():
        lines.append(f'jev_decision_confidence_score{{workflow="{wf}"}} {score:.4f}')

    cost = state.get("cost_saved_usd_total", 0.0)
    lines.extend([
        "# HELP jev_cost_saved_usd_total Estimated USD saved by avoiding frontier LLM calls",
        "# TYPE jev_cost_saved_usd_total counter",
        f'jev_cost_saved_usd_total {cost:.4f}',
        ""
    ])
    return "\n".join(lines)


def get_metrics_payload():
    engine_text, engine_up = fetch_engine_metrics()
    if engine_text and engine_up:
        # Prepend exporter up gauge
        prefix = f"# HELP jev_engine_up Whether Jev engine is reachable\n# TYPE jev_engine_up gauge\njev_engine_up 1\n"
        return prefix + engine_text

    file_state = load_file_metrics()
    if not file_state:
        file_state = {
            "decisions_total": {
                "router": 0,
                "email_triage": 0,
                "fs_organizer": 0,
                "lead_triage": 0,
                "ad_miner": 0
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
                "router": 0.90,
                "email_triage": 0.88,
                "fs_organizer": 0.90,
                "lead_triage": 0.92,
                "ad_miner": 0.87
            },
            "cost_saved_usd_total": 0.0
        }
    return format_prometheus_metrics(file_state, engine_up)


class ThreadedHTTPServer(ThreadingMixIn, HTTPServer):
    daemon_threads = True


class MetricsHandler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        # Keep exporter quiet on normal scrapes
        pass

    def do_GET(self):
        if self.path in ("/metrics", "/"):
            payload = get_metrics_payload().encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; version=0.0.4; charset=utf-8")
            self.send_header("Content-Length", str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)
        elif self.path in ("/health", "/healthz"):
            body = json.dumps({"status": "ok", "service": "jev-exporter", "port": PORT}).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        else:
            self.send_response(404)
            self.end_headers()


def run():
    server = ThreadedHTTPServer((HOST, PORT), MetricsHandler)
    sys.stderr.write(f"Jev Prometheus Exporter running on {HOST}:{PORT}\n")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    run()
