---
name: jev-triage
description: System-1 Decision Model (Jev / JEPA) for Fleet Email & Filesystem Triage
---

# Jev System-1 Triage & Routing Skill

## 1. Overview & Architecture

**Jev** is NFP's high-speed, zero-hallucination System-1 discriminative decision engine. Unlike generative autoregressive LLMs, Jev evaluates an input `state` against typed `questions` with strict schema choices (enums and booleans), returning calibrated probability distributions and confidence scores in sub-10ms latency.

- **Zero Hallucination:** Constrained to deterministic enum options and boolean states.
- **Cost & Speed:** Sub-cent, high-throughput routing before invoking heavy System-2 models (Claude Sonnet, Hermes, GPT-4o).
- **Fleet Interfacing:** Exposes an MCP server (`jev-decision`) across `z0r0`, `luffy`, and `nami`.
- **Core Engine:** Bound to Tailnet on `luffy.nfp.nix:20130`.

---

## 2. Decision Schemas

### 2.1 Email Triage (`email_triage.json`)
State: MIME headers (`From`, `Subject`, `Date`) + body preview.
- **category** (enum):
  - `invoice_financial`: Invoices, receipts, billing statements.
  - `security_auth`: 2FA codes, login alerts, password resets.
  - `personal`: Human-to-human correspondence.
  - `newsletter`: Subscriptions, digests, marketing.
  - `automated_alert`: CI/CD alerts, server monitoring, cron notifications.
  - `spam`: Unsolicited bulk marketing, phishing attempts.
- **action_required** (boolean): `true` if manual action/reply/payment needed; `false` otherwise.
- **target_agent** (enum):
  - `hermes_billing`: Financial ingestion and payment tracking.
  - `paperclip_ops`: Infrastructure and alert remediation.
  - `archive_silent`: Mark as processed without interrupting human.

### 2.2 Filesystem Organizer (`fs_organize.json`)
State: Path, file size, MIME type, header/snippet.
- **target_vault** (enum):
  - `financial_records`: Tax forms, receipts, bank statements.
  - `code_projects`: Repositories, patches, scripts.
  - `media_audiobooks`: Audiobooks, audio, video files.
  - `personal_documents`: Personal notes, scans, letters.
  - `ephemeral_trash`: Temp files, installer logs, build junk.
- **suggested_filename_pattern** (enum):
  - `YYYY-MM-DD_vendor_receipt`: Dated standardized format.
  - `project_artifact`: Project-prefixed format.
  - `keep_original`: Retain current basename.

---

## 3. Invoking Jev via MCP (`jev-decision`)

Agents can interact with Jev using the tools exposed by `jev-decision`:

### 3.1 `evaluate_decision` / `jev_decide`
Evaluate arbitrary state and typed questions:
```json
{
  "state": "From: billing@hetzner.com\nSubject: Invoice #1029481\nBody: Your monthly invoice for 2026-10...",
  "questions": [
    {
      "id": "category",
      "type": "enum",
      "options": ["invoice_financial", "security_auth", "personal", "newsletter", "automated_alert", "spam"]
    },
    {
      "id": "action_required",
      "type": "boolean"
    },
    {
      "id": "target_agent",
      "type": "enum",
      "options": ["hermes_billing", "paperclip_ops", "archive_silent"]
    }
  ]
}
```

Response format:
```json
{
  "engine": "jev-system1",
  "latency_ms": 4.2,
  "aggregate_confidence": 0.965,
  "decisions": {
    "category": {
      "value": "invoice_financial",
      "confidence": 0.98,
      "probabilities": { "invoice_financial": 0.98, "automated_alert": 0.015, "spam": 0.005 }
    },
    "action_required": {
      "value": true,
      "confidence": 0.95
    },
    "target_agent": {
      "value": "hermes_billing",
      "confidence": 0.965,
      "probabilities": { "hermes_billing": 0.965, "paperclip_ops": 0.02, "archive_silent": 0.015 }
    }
  }
}
```

### 3.2 `triage_email_batch`
Pass a list of email message paths or raw MIME snippets:
```json
{
  "mail_ids": [
    "/home/t0psh31f/.local/share/mail/INBOX/cur/1728700000.1234_1.host:2,S"
  ]
}
```

### 3.3 `classify_file_batch`
Pass a list of paths from staging directories (`~/Downloads`, `~/Inbox`, `~/Scans`):
```json
{
  "file_paths": [
    "/home/t0psh31f/Downloads/Hetzner_Invoice_1029481.pdf"
  ]
}
```

---

## 4. Confidence Threshold & Escalation Protocol

Agents MUST inspect `aggregate_confidence` or individual question confidence:

1. **High Confidence ($\ge 0.80$):**
   - Execute deterministic action directly.
   - For email: apply Maildir flags / IMAP labels (`Jev/Processed`, `Jev/ActionRequired`).
   - For filesystem: move or hardlink to target vault folder (`~/Vault/<target_vault>/`).

2. **Low Confidence ($< 0.80$):**
   - **DO NOT** execute automated move or archive.
   - Escalate to System-2 model (Hermes, Claude Sonnet) or flag for user review (`Jev/Escalate`).
   - Prompt user or generative agent with ambiguous fields.

---

## 5. Safety & Idempotency Rules

- **Zero Data Loss:** Never delete emails from IMAP/Maildir.
- **Trash Staging:** Files categorized as `ephemeral_trash` must be moved to `~/.local/share/Trash`, NEVER unrecoverably unlinked (`rm -rf`).
- **Proposal Logging:** Filesystem operations must generate proposals to `/home/t0psh31f/.local/share/jev/fs-proposals.json` before batch relocation.
- **Collision Protection:** When moving files, append timestamp or hash if target exists to prevent overwrite.
