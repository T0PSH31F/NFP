---
name: telemetry
description: OpenTelemetry fleet observability, tracing, metrics, and logs pipeline.
---

# OpenTelemetry Fleet Telemetry Skill

Unified interface for interacting with the NFP OpenTelemetry collector pipeline.

## Capabilities

1. **Emit Spans & Traces**: Send distributed tracing spans for AI workflows, HTTP requests, and background jobs to the local/fleet collector (`:4317` gRPC / `:4318` HTTP).
2. **Push Metrics**: Send custom counters, histograms, and gauges to Prometheus via OTel exporter.
3. **Structured Logs**: Send JSON-formatted application logs directly to Loki via OTel log pipelines.
4. **Inspect Pipeline**: Check collector health at `http://localhost:8888/metrics` and trace flow.

## Architecture

```
[ AI Agent / Service ]
        │
        ▼ (OTLP HTTP/gRPC :4318 / :4317)
[ OpenTelemetry Collector Daemon ]
   ├── Metrics  ──► Prometheus (:9090)
   ├── Logs     ──► Loki (:3100)
   └── Traces   ──► Grafana Alloy / Langfuse (:3000)
```

## Python Helper Usage

```python
from telemetry_client import TelemetryClient

client = TelemetryClient(service_name="antigravity-agent")

# Record a traced operation
with client.trace("synthesize_plan") as span:
    span.set_attribute("agent.model", "gemini-3.8-flash")
    span.set_attribute("task.id", "multi-desktop-matrix")
    # Execute operation...
    span.add_event("step_completed", {"step": 1})

# Record a metric
client.record_metric("agent_invocations_total", 1, {"status": "success"})
```
