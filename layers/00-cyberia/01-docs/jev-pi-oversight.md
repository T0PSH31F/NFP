# 👁️ Jev Oversight via Pi Durable Agents

Architecture and operational manual for tracking, monitoring, and delegating work between the **Jev System-1 Deterministic Decision Engine** and **Pi Durable Coding Agents**.

---

## 🎯 Architectural Overview

Jev processes decisions (email classification, inbox triage, file routing) at sub-millisecond speeds with zero token cost. However, long-running execution, ambiguous escalation, and anomaly correction require autonomous oversight. Pi durable coding agents (`earendil-works/Pi`) provide this oversight layer.

```mermaid
graph TD
    subgraph Ingress [Input Sources]
        Mail[IMAP Inboxes: wrighterik77, lovelainautomations]
        FS[Filesystem Watchers / Downloads]
        UserReq[User Direct Dispatch]
    end

    subgraph JevCore [Jev System-1 Engine (:20130)]
        JevEngine[Deterministic Decision Matrix<br/>1-5ms Classification]
        Preflight[Zero-Token Pre-Flight Proxy :20127]
        TriageQueue[(Triage Queue / SQLite)]
    end

    subgraph Oversight [Pi Durable Agent Oversight]
        PiAgent[Pi Coding Agent<br/>Session: jev-oversight]
        JevMCP[jev-decision MCP Tool]
        HerdrSession[Herdr Persistent Workspace]
    end

    subgraph Telemetry [Observability Stack]
        Langfuse[Langfuse :3005<br/>Decision Traces & Cost Savings]
        Prometheus[Jev Exporter :9586<br/>Decision Count & Latency Metrics]
        QSBar[Quickshell Rise Live Status]
    end

    Mail --> JevEngine
    FS --> JevEngine
    UserReq --> Preflight
    Preflight --> JevEngine

    JevEngine --> TriageQueue
    JevEngine --> Langfuse
    JevEngine --> Prometheus

    PiAgent -->|MCP Tools: get_triage_queue, classify_text| JevMCP
    JevMCP --> JevEngine
    PiAgent -.->|Runs within| HerdrSession
    PiAgent -->|Broadcasts status| QSBar
```

---

## 🔍 Four Pillars of Jev Oversight

### 1. Native Model Context Protocol (MCP) Tool Harness
Pi durable agents are equipped with the native `jev-decision` MCP tool declared in `layers/70-agents/71-harness/pi-coding-agent.nix`:

```json
{
  "mcpServers": {
    "jev-decision": {
      "command": "python3",
      "args": ["layers/70-agents/75-mcp/jev-mcp.py"],
      "description": "Jev System-1 Decision Engine, Telemetry & Triage Oversight"
    }
  }
}
```

Pi agents can query and invoke Jev functions during any task:
- `classify_text`: Benchmark or verify text categorization.
- `triage_email`: Inspect pending inbox items and review action flags.
- `route_file`: Validate file distribution across decentralized vaults.
- `inspect_jev_health`: Verify daemon latency, operational status, and pre-flight cache hit rates.

### 2. Autonomous Herdr Persistent Workspaces
Pi durable agents run continuous oversight loops inside detached Herdr persistent sessions:

```bash
# Launch persistent Jev oversight session in Herdr
herdr --session jev-oversight

# Within the session, run autonomous triage and watchdog
nfp-jev triage-email
```

Because Herdr sessions persist across reboots, network disconnects, and compositor switches, the Pi agent maintains unbroken oversight over Jev's background queues.

### 3. Langfuse Live Telemetry & OpenTelemetry Tracing
Every single decision made by Jev is instrumented and pushed to Langfuse (`http://127.0.0.1:3005`):
- **Zero-Token Tracking**: Measures prompt tokens saved by Jev pre-flight interception before hitting LLMs.
- **Latency Histograms**: Tracks classification response times (target: < 20ms).
- **Cost Avoidance**: Computes exact dollar amounts preserved in the Aperture token budget.

### 4. Desktop Visual Feedback Loop
When Jev encounters an item with `action_required: true` (e.g. urgent server bills, downtime alerts, security disclosures), the triage daemon or Pi agent triggers an immediate alert via:
- Desktop notifications (`makoctl` / `qs ipc`)
- High-priority voice lines through the GLaDOS TTS engine (`glados-speak`)
- Visual live-wire pulsing on the Quickshell Rise status bar
