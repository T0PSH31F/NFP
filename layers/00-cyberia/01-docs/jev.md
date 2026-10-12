# Jev System-1 Decision Engine & E-Book Vault Pipeline

## Overview

**Jev** is NFP's System-1 discriminative classification engine. Rather than generating conversational text, Jev accepts a structured input `state` along with schema-defined `questions` and returns calibrated probability distributions and typed decisions in sub-10ms latency.

Within NFP's dendritic architecture, Jev serves as the zero-hallucination routing and triage backbone for:
- Pre-flight LLM routing and token pruning
- Automated Maildir/IMAP email classification
- Continuous filesystem triage and quarantine
- E-book library standardization, copyright year extraction, and PKB RAG ingestion
- Inbound lead qualification and ad-hook market intelligence

---

## 1. Architecture & Layer 70 Consolidation

All Jev core components are centralized under `layers/70-agents/jev/`:

| Component | File | Port / Path | Purpose |
| :--- | :--- | :--- | :--- |
| **Jev Core Engine** | `jev-engine.nix` / `py` | `http://127.0.0.1:20130` | System-1 `/v1/decide` inference server |
| **Router Pre-Flight Hook** | `jev-router-plugin.nix` / `py` | `http://127.0.0.1:20127` | Intercepts agent requests, prunes context, routes models |
| **Prometheus Exporter** | `jev-exporter.nix` / `py` | `http://127.0.0.1:20132` | Exports latency, decision counts, and routing metrics |
| **Email Triage Daemon** | `email-triage-daemon.nix` / `py` | Background service | Watches mailboxes, labels categories, flags urgent mail |
| **Filesystem Organizer** | `fs-organizer-daemon.nix` / `py` | Background service | Watches downloads, triages files, quarantines hazards |
| **Book Vault Purifier** | `book-vault-purifier.nix` / `py` | Systemd timer | Enforces `[YYYY]` format, extracts covers, stages RAG |
| **Jev CLI** | `nfp-jev.nix` / `py` | CLI binary `nfp-jev` | Command-line tool for decisions, benchmarks, testing |
| **Book Review TUI** | `nfp-book-tui.nix` / `py` | CLI binary `nfp-book-tui` | Interactive curses review for vault, covers, and RAG |

### External Layer Boundaries
- **Layer 22 (`20-services/22-ai/`):** Production business pipelines (`lead-triage-webhook.nix`, `ad-hook-miner.nix`).
- **Layer 75 (`70-agents/75-mcp/`):** MCP tool wrappers (`jev-mcp.nix`) for Hermes, OpenCode, and Antigravity.
- **Layer 79 (`70-agents/79-skills/`):** Declarative skill definitions (`book-purifier`, `jev-triage`, `lead-and-market-intel`).
- **Layer 73 (`70-agents/73-memory/`):** Brain-Service PKB on port `:8010` backed by pgvector.

---

## 2. E-Book Vault Purification Pipeline

### 2.1 File Naming Specification
Standardized format:
```text
/data/vault/library/[YYYY] Book Title - (Author Name).ext
```
*Example:* `[2026] Building Agentic Workflows - (Andrew Ng).epub`

- **Undated Fallback:** If publication year cannot be extracted from OPF metadata or copyright regex:
  `[0000] Book Title - (Author Name).ext` (highlighted in `nfp-book-tui` with `⚠️ [0000]` review badge).

### 2.2 Directory Layout
- **Canonical Library:** `/data/vault/library/[YYYY] Book Title - (Author Name).ext`
- **Companion Cover Art:** `/data/vault/library/[YYYY] Book Title - (Author Name).cover.jpg`
- **Companion Metadata Receipt:** `/data/vault/library/[YYYY] Book Title - (Author Name).metadata.json`
- **Non-Book Quarantine:** `/data/vault/quarantine/non-books/`
- **RAG Staging Inbox:** `/var/lib/brain-service/inbox/` (mirrored to `~/Notes/inbox/` when present)
- **Taxonomy Symlinks:**
  - AI & Machine Learning: `/data/vault/by-topic/AI-Agents/`
  - Passive Income & Business: `/data/vault/by-topic/Passive-Income/`
  - Software & Programming: `/data/vault/by-topic/Programming/`

### 2.3 Extraction Pipeline
1. **Magic Signature Verification:** Validates `.epub`, `.pdf`, `.mobi`, `.azw3`, `.cbz` file headers. Non-books moved to quarantine with JSON incident reports.
2. **Metadata & Date Extraction:**
   - Calibre `ebook-meta` CLI (when present)
   - Native OPF XML parser for EPUB (`dc:date`, `dc:title`, `dc:creator`, `calibre:series`)
   - Native PDF dictionary header extraction (`/Title`, `/Author`, `/CreationDate`)
   - Copyright page regex scanner across first document chapters: `(?:©|\bCopyright\b)\s*(\d{4})`
3. **Companion Cover Art:**
   - Extracted to companion `[YYYY] Title - (Author).cover.jpg` alongside the document.
4. **Jev Semantic Triage & Brain-Service Ingestion:**
   - Evaluates domain: `ai_agent_architecture`, `machine_learning_llm`, `passive_income_business`, `technical_programming`, `general_fiction`, `general_nonfiction`.
   - AI and Passive Income books trigger immediate RAG staging and API call to `http://luffy.nfp.nix:8010/ingest/file`.
   - Creates topic taxonomy symlinks.

---

## 3. Usage & CLI Tools

### 3.1 Jev CLI (`nfp-jev`)
Evaluate decisions via CLI:
```bash
# Ad-hoc boolean question
nfp-jev decide --state "Subject: Wire Transfer Confirmation" --question is_financial_wire=boolean

# Full JSON schema query
nfp-jev decide --state "Invoice from Cloudflare $40.00" --questions layers/70-agents/79-skills/jev-triage/schemas/email_triage.json

# Check Jev Engine status and metrics
nfp-jev status
```

### 3.2 Book Vault Review Screen (`nfp-book-tui`)
Interactive curses terminal review:
```bash
nfp-book-tui
```
- **Tabs:**
  - `[1: Library]`: View purified books, companion cover status, domain taxonomy, and year. Highlights `[0000]` undated books.
  - `[2: Quarantine]`: Inspect quarantined corrupted or non-book files and quarantine reasons.
  - `[3: RAG Ingest Inbox]`: Review documents staged for Brain-Service vector indexing.
- **Controls:** `j`/`k` (navigate list), `Tab` (switch tabs), `r` (trigger manual RAG ingest), `q` (quit).

### 3.3 Running Book Vault Purifier Manually
```bash
# Dry run inspection
book-vault-purifier --source /data/vault/raw-inbox --dry-run

# Run single purification pass
book-vault-purifier --source /data/vault/raw-inbox --once
```

### 3.4 Monitoring & Observability
- **Prometheus Metrics:** `http://127.0.0.1:20132/metrics`
- **Grafana Dashboard:** `jev-operations.json` in Grafana dashboards (under AI & Fleet Monitoring).
- **Brain-Service API:** `http://127.0.0.1:8010/docs`
