---
name: book-purifier
description: E-Book and Document Vault Purification, Metadata/Cover Recovery, and Brain-Service AI/Income RAG Ingestion Pipeline.
---

# E-Book & Document Vault Purification Pipeline

Automated pipeline for purifying the e-book vault, standardizing Calibre metadata and cover art, and triaging AI & passive income literature for Brain-Service RAG ingestion.

## Core Capabilities

1. **File Format Gatekeeper**:
   - Validates magic bytes and signatures for `.epub`, `.pdf`, `.mobi`, `.azw3`, and `.cbz`.
   - Purges pollutants (executables, archives, temp artifacts, random code) to `/data/vault/quarantine/non-books/`.

2. **Metadata & Cover Recovery**:
   - Reads internal EPUB OPF, PDF Info, MOBI headers via Calibre `ebook-meta` and native python fallbacks.
   - Extracts embedded cover or generates page 1 thumbnail to `cover.jpg`.
   - Renames files into canonical format: `Author Name - Book Title [Series Name #01] (Year).ext`.
   - Normalizes Calibre library structure: `/data/vault/library/{Author}/{Title}/`.

3. **Jev Semantic Triage**:
   - Classifies domain (`ai_agent_architecture`, `machine_learning_llm`, `passive_income_business`, `software_engineering`, `general_fiction`, `other_non_fiction`).
   - Flags `is_ai_or_passive_income` boolean.
   - Assigns `brain_service_ingest_priority` (`p0_immediate_rag_ingest`, `p1_standard_rag_ingest`, `skip_general_library_only`).

4. **Brain-Service RAG Ingestion Bridge**:
   - Copies or hardlinks high-priority books into `/var/lib/brain-service/inbox/`.
   - Dispatches ingestion request to `http://127.0.0.1:8010/ingest/path`.
   - Links into topic taxonomies (`/data/vault/library/by-topic/AI-Agents/`, `by-topic/Passive-Income/`).

5. **Btrfs Snapshot Safeguards**:
   - Automatically snapshots raw/vault subvolume before executing moves or writes.
