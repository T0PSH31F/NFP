# Post-Rebuild Setup & Health Verification Guide

> Fleet hosts: `z0r0` (thin client daily driver), `luffy` (homelab / PKB / memory), `nami` (cloud 16GB VPS control plane)

---

## 1. ExtremeRouter Setup (nami / z0r0)

ExtremeRouter provides LLM routing, token compression, and fallback management.

### First-Time Setup
1. **Open dashboard**: `http://nami.nfp.nix:20128` (or `http://z0r0:20128`)
2. **Connect providers** (Dashboard → Providers):
   - **OpenRouter**: API key managed via `sops-nix` (`openrouter_api_key`)
   - **Kiro AI**: Builder ID / Google OAuth
   - **OpenCode Free**: Auto-discovers models without auth
3. **Enable Token Savers** (Dashboard → Endpoint settings):
   - **RTK Token Saver**: ON (reduces prompt token overhead)
   - **Caveman Mode**: Toggle ON for ultra-terse response generation
   - **Ponytail**: Toggle ON for YAGNI-first code generation

---

## 2. Kong Gateway Verification (nami)

Kong Gateway operates as the primary fleet ingress for LLM traffic (`layers/70-agents/78-llm-routers/kong-gateway.nix`).

```bash
# Check Kong proxy status
curl -s http://nami.nfp.nix:8090/health

# Enumerate routed models
curl -s http://nami.nfp.nix:8090/v1/models | jq .

# Test coding route to ExtremeRouter
curl -s -X POST http://nami.nfp.nix:8090/llm/coding/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"auto","messages":[{"role":"user","content":"ping"}]}'
```

---

## 3. Hermes Agent Verification (z0r0 / luffy)

Hermes operates from `layers/70-agents/71-harness/hermes/hermes.nix`.

```bash
# Check service status
systemctl status hermes-agent hermes-dashboard hermes-workspace

# Check Hermes dashboard API
curl -s http://localhost:9119/api/health

# Verify A2A agent-to-agent communication
hermes status
```

---

## 4. OpenCode Agent Verification (z0r0)

OpenCode operates from `layers/70-agents/71-harness/opencode.nix`.

```bash
# Verify binary availability
opencode --version

# Verify provider configuration
jq '.provider | keys' ~/.config/opencode/opencode.json

# Check oh-my-opencode-slim configuration
jq '.preset' ~/.config/opencode/oh-my-opencode-slim.json
```

---

## 5. Brain Service PKB Verification (luffy)

Brain Service RAG & PKB engine operates from `layers/70-agents/73-memory/brain-service.nix`.

```bash
# Check API endpoint status on luffy
curl -s http://192.168.1.54:8010/health

# Query ingested notes manifest
curl -s http://192.168.1.54:8010/manifest | jq '.files | length'

# Test vector search query
curl -s -X POST http://192.168.1.54:8010/query \
  -H "Content-Type: application/json" \
  -d '{"question": "How do I configure impermanence with BTRFS?"}'
```

---

## 6. Multi-Machine Fleet Validation

Run the automated service and Homepage Dashboard link validator script:

```bash
# Run fleet-wide fast service probes
./layers/00-cyberia/06-scripts/validate-services-and-homepage.sh --ci
```

---

## 7. Quick Reference Port Table

| Service | Host | Port | Endpoint URL |
|---------|------|------|--------------|
| Kong Gateway (Proxy) | `nami` | 8090 | `http://nami.nfp.nix:8090` |
| ExtremeRouter | `nami` / `z0r0` | 20128 | `http://nami.nfp.nix:20128` |
| Hermes Workspace | `z0r0` | 3000 | `http://z0r0:3000` |
| Hermes Dashboard | `z0r0` | 9119 | `http://z0r0:9119` |
| Brain Service PKB | `luffy` | 8010 | `http://luffy.nfp.nix:8010` |
| Open WebUI | `luffy` | 8088 | `http://luffy.nfp.nix:8088` |
| Ollama LLM | `luffy` | 11434 | `http://luffy.nfp.nix:11434` |
| Grafana | `z0r0` / `luffy` | 3008 | `http://z0r0:3008` |
| Prometheus | `z0r0` | 9090 | `http://z0r0:9090` |
| Headscale Control | `luffy` | 8086 | `http://luffy.nfp.nix:8086` |
