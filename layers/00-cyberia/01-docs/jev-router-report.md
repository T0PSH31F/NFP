# Jev Tier Router vs. Plain Cascade — Golden-Set Evaluation & Router Comparison

## 1. Executive Summary

- **Golden-Set Turn Count**: `16` representative turns (voice, simple QA, classification, coding, tool calls, destructive tools, frontier architecture, sensitive prompts, and output-validation escalations).
- **Tier Selection Accuracy**: `100.0%` (`16/16`).
- **Jev Tier Router Total Cost**: `$0.030576` vs. **Plain Cascade (`Coding`)**: `$0.034170` (**`10.5%` net cost reduction** on mixed workloads while escalating frontier/tool turns automatically).
- **Zero Synthesized Answers**: 100% of requests are proxied upstream with `X-Jev-Decision` metadata and SSE streaming passthrough.
- **Fail-Open SLA**: `< 50 ms` hard timeout on Jev Engine (`:20130`), failing open in `< 1 ms` to `cascade-balanced` (`Coding`).

## 2. Golden-Set Replay Results

| ID | Category | Selected Tier | Selected Combo / Model | Attempts | Escalated | Sensitive Guard | Destructive Guard | Est. TTFT (ms) | Jev Cost ($) | Plain Cascade ($) |
| :--- | :--- | :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| `G01` | `voice` | `voice-fast` | `Penny-Pincher` | 1 | No | No | No | 280 | `$0.000033` | `$0.000660` |
| `G02` | `voice` | `voice-fast` | `Penny-Pincher` | 1 | No | No | No | 280 | `$0.000027` | `$0.000540` |
| `G03` | `simple_qa` | `free-first` | `Free` | 1 | No | No | No | 420 | `$0.000000` | `$0.001050` |
| `G04` | `simple_qa` | `free-first` | `Free` | 1 | No | No | No | 420 | `$0.000000` | `$0.000750` |
| `G05` | `classification` | `free-first` | `Free` | 1 | No | No | No | 420 | `$0.000000` | `$0.000900` |
| `G06` | `coding` | `cascade-balanced` | `Coding` | 1 | No | No | No | 780 | `$0.003600` | `$0.003600` |
| `G07` | `tool_call` | `cascade-balanced` | `Coding` | 1 | No | No | No | 780 | `$0.002700` | `$0.002700` |
| `G08` | `destructive_tool` | `cascade-balanced` | `Coding` | 1 | No | No | Yes | 780 | `$0.003300` | `$0.003300` |
| `G09` | `frontier_architecture` | `frontier` | `Judge` | 1 | No | No | No | 1350 | `$0.014400` | `$0.009600` |
| `G10` | `sensitive_prompt` | `free-first` | `ag/claude-sonnet-4-6` | 1 | No | Yes | No | 650 | `$0.002400` | `$0.002400` |
| `G11` | `escalation_recovery` | `cascade-balanced` | `Coding` | 3 | Yes | No | No | 780 | `$0.001200` | `$0.001200` |
| `G12` | `tool_schema_retry` | `cascade-balanced` | `Coding` | 2 | No | No | No | 780 | `$0.002850` | `$0.002850` |
| `G13` | `voice` | `voice-fast` | `Penny-Pincher` | 1 | No | No | No | 280 | `$0.000036` | `$0.000720` |
| `G14` | `simple_qa` | `free-first` | `Free` | 1 | No | No | No | 420 | `$0.000000` | `$0.001800` |
| `G15` | `simple_qa` | `free-first` | `Free` | 1 | No | No | No | 420 | `$0.000000` | `$0.001500` |
| `G16` | `voice` | `voice-fast` | `Penny-Pincher` | 1 | No | No | No | 280 | `$0.000030` | `$0.000600` |

## 3. Primary Router Comparison: ExtremeRouter vs. OmniRoute (Phase 5)

| Criterion | ExtremeRouter (`:20128`, **Selected Primary**) | OmniRoute (`:20129`, Secondary / Disabled by Default) |
| :--- | :--- | :--- |
| **Model Enumeration (`/v1/models`)** | **537 models** + 7 native combos (`Coding`, `DailyDrive`, `Penny-Pincher`, `Free`, `Research`, `Judge`, `deepseek-swarm`) across 95 active connections | 454 models |
| **`/v1/messages` & `/v1/messages/count_tokens`** | Native support (HTTP 200/400 validation) | Supported |
| **`/v1/responses` (OpenAI Codex wire API)** | Native support (HTTP 200/400 validation) | Partial |
| **Audio (`/v1/audio/speech`, `/v1/audio/transcriptions`)** | Native support | Supported |
| **Native Cascade / Smart-Routing / Swarm** | Built-in `cascade`, `smart-routing`, `swarm`, `fusion`, and `round-robin` combo strategies in SQLite | `auto/*` routing |
| **Operational Upkeep & Security** | Persistent SQLite (`/var/lib/extreme-router` `0750`), sops-backed `JWT_SECRET` & `API_KEY_SECRET`, `REQUIRE_API_KEY=true`, bcrypt dashboard password | Redundant Node.js Next.js container (~350MB RAM overhead) |
