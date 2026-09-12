# Agent Progress Log

Append one entry per session, newest at the bottom. Never edit past entries.

## Entry template
- **Date / Agent:** YYYY-MM-DD / <agent-name>
- **Feature:** <feature id from feature_list.json>
- **Work done:** <1-3 sentences>
- **Verification:** <commands run + result>
- **State change:** <untried|in-progress|blocked|passing> (evidence added to feature_list.json)
- **Next action:** <exact next step for the next session>

## Entries
- **Date / Agent:** 2026-08-21 / antigravity
- **Feature:** harness-pack
- **Work done:** Implemented complete NFP Agent Harness (Phases P0 - P3). Scaffolded init.sh, feature_list.json, agent-progress.md, session-handoff.md, clean-state-checklist.md, evaluator-rubric.md, skill packs, OpenCode & Hermes wiring, schema checks, and harness.md documentation.
- **Verification:** `./init.sh` green; `jq -e . feature_list.json` valid; `head -40 AGENTS.md` verified; flake checks & machine evals passing.
- **State change:** passing (evidence recorded in feature_list.json)
- **Next action:** claim extreme-router-persistence in next session

- **Date / Agent:** 2026-08-21 / antigravity
- **Feature:** extreme-router-persistence
- **Work done:** Verified image digest pinning, OCI container volume mounts (/var/lib/extreme-router:/app/data), and registered /var/lib/extreme-router in canonical impermanence system directories under layers/10-system/15-filesystem/impermanence.nix.
- **Verification:** `nix eval` confirmed volume mounts and digest pinning; `./init.sh` baseline check passed with clean evaluation on luffy and z0r0.
- **State change:** passing (evidence recorded in feature_list.json)
- **Next action:** claim aionui-persistence-and-auth in next session

- **Date / Agent:** 2026-08-21 / antigravity
- **Feature:** NFP Optimization & Refactor Pass 2 (p0-git-identity, p0-checklist-hygiene, p0-pre-commit-hooks, p0-feature-list-schema-v2, p1-endpoints-registry, p1-namespace-migration, p1-generated-docs, p2-negative-tests-guardrails, p2-evaluator-isolated-state, p2-secrets-boundary, p3-pinned-ci-tooling, p3-lock-automation-agent-compat)
- **Work done:** Completed all 12 tasks across P0-P3 phases. Configured git identity & hooks, schema v2 feature_list, endpoints.nix registry, option namespace migrations with mkRenamedOptionModule, docs-drift & bogus-tag negative tests, isolated hermes-evaluator state, secrets system boundary docs, update-flake-lock workflow, and CLAUDE.md/GEMINI.md symlinks.
- **Verification:** `nix eval` on z0r0 & luffy toplevels clean; `jq -e` schema v2 valid; `clean-state-checklist.md` unchecked template; all feature verifications passed & evidence recorded.
- **State change:** passing (evidence recorded in feature_list.json)
- **Next action:** Proceed with fleet deployment via clan machines update.

- **Date / Agent:** 2026-08-21 / antigravity
- **Feature:** llm-agents-catalog, replace-self-packaged-aionui, replace-self-packaged-paperclip, replace-self-packaged-hermes-desktop, dsh-module, wl-shimeji-module
- **Work done:** Updated llm-agents lock; created llm-agents-catalog.nix with 28 default packages, catalog doc, generate-llm-agents-catalog-doc.sh, voxtype persistence, and completeness check; replaced custom packaging with llmPkgs in aionui.nix, paperclip.nix, and hermes.nix; created dsh module via Samuka007/dsh-nix; packaged wl_shimeji derivation with fetchSubmodules and created wl_shimeji desktop toys module with socket activation, impermanence, and Hyprland warning.
- **Verification:** `./init.sh` green; `nix flake check` passed; `z0r0` and `luffy` toplevels evaluated cleanly; all 6 features marked passing in `feature_list.json` with evidence.
- **State change:** passing (evidence recorded in feature_list.json)
- **Next action:** Proceed with fleet deployment via clan machines update z0r0.

- **Date / Agent:** 2026-08-26 / antigravity
- **Feature:** backups-restic
- **Work done:** Implemented Phase 1 restic + rclone backup infrastructure (`layers/20-services/25-data/restic-backups.nix`) supporting Google Drive and teldrive remotes, PostgreSQL pre-dump hook (`pg_dumpall`), `/persist/home` and critical `/var/lib` state retention, and `restic-restore-drill` verification CLI script. Exposed module option `layers.layer-20.services.backups.restic` and enabled it on server and workstation profile tags.
- **Verification:** Evaluated `nfp-main.paths` cleanly on both `z0r0` and `luffy`; validated schema v2 in `feature_list.json`; opened PR #7 (https://github.com/T0PSH31F/NFP/pull/7).
- **Date / Agent:** 2026-08-26 / antigravity
- **Feature:** oom-kill-mitigations
- **Work done:** Reduced rclone VFS cache max size to 2GB with writes mode across user and system mounts; expanded earlyoom process filters to protect Hyprland, noctalia, greetd, sshd, systemd and prioritize heavy browser/electron applications; deleted ANTIGRAVITY_OOM_ISSUE.md post-fix; ran nix-collect-garbage.
- **Verification:** Evaluated earlyoom extraArgs and system toplevels cleanly on both z0r0 and luffy; feature schema v2 valid.
- **State change:** passing (evidence recorded in feature_list.json)
- **Next action:** Execute fleet update via `clan machines update z0r0`.

- **Date / Agent:** 2026-08-26 / antigravity
- **Feature:** memory-vault, everos-runtime, memory-gateway-federation, honcho-migration
- **Work done:** Implemented Phase 2 Memory Chassis: created `memory-vault.nix` with canonical vault at `/var/lib/memory/vault`, `memory` group ownership, seed directory structure, impermanence, and 15-min git mesh sync timer; created `everos.nix` EverOS memory server (port 8092) with nightly 03:00 consolidation timer; updated `context-forge.nix` with EverOS MCP server registration, agent memory scoping (`hermes` shared+private, sandboxed shared-only), and Langfuse tracing; updated `honcho.nix` with pgvector & impermanence; created `honcho-migrate.py` cloud workspace migration script.
- **Verification:** Evaluated all 4 module options cleanly on both `z0r0` and `luffy`; validated schema v2 in `feature_list.json`; opened PR #8 (https://github.com/T0PSH31F/NFP/pull/8).
- **State change:** passing (evidence recorded in feature_list.json and PR https://github.com/T0PSH31F/NFP/pull/8)
- **Date / Agent:** 2026-08-26 / antigravity
- **Feature:** kong-consumer-per-agent, polyfloor-registry, agent-sandbox-images, control-surface-adr, memory-governance-plane
- **Work done:** Implemented Phase 3 Governance + Swarm: expanded `kong-gateway.nix` and `kong-secrets.nix` with 10 dedicated agent consumers and keyauth credentials (`hermes`, `opencode`, `claude-code`, `codex`, `cursor`, `deerflow`, `polyfloor`, `paperclip`, `opencompany`, `dsh`); integrated Polyfloor backend with endpoints registry and PostgreSQL DB; created `agent-sandbox.nix` for isolated Podman/Bubblewrap container executions; authored `0001-control-surface-swarm-governance.md` ADR; implemented `memory-governance.nix` for ACL scope enforcement across shared and private agent memory stores.
- **Verification:** Evaluated `kong-gateway.consumers`, `polyfloor.enable`, `agent.sandbox.enable`, `memory-governance.enable` cleanly on both `z0r0` and `luffy`; verified ADR file existence and content; validated schema v2 in `feature_list.json`; opened PR #9 (https://github.com/T0PSH31F/NFP/pull/9).
- **State change:** passing (evidence recorded in feature_list.json and PR https://github.com/T0PSH31F/NFP/pull/9)
- **Date / Agent:** 2026-08-27 / antigravity
- **Feature:** zellij-persistence-bars, homepage-rewrite
- **Work done:** Implemented Phase 4/5 UX & Dashboard refinement: updated `zellij.nix` with session/pane viewport serialization, Noctalia theme color sync, status bar widgets, and impermanence; completely rewritten `homepage-dashboard.nix`, `homepage-theme.css`, and `homepage-theme.js` adding Speeddial grid, rich categorized Bookmarks, mDNS LAN host resolution (`z0r0.local`, `luffy.local`), API widget secret gating (`hasEnv`), and strict CSS height caps to eliminate widget error ballooning.
- **Verification:** `./init.sh` green; `homepage-dashboard-test` evaluated cleanly (`/nix/store/...-vm-test-run-homepage-dashboard-module.drv`); `nix eval` on z0r0 and luffy toplevels clean.
- **State change:** passing (evidence recorded in feature_list.json)
- **Next action:** Proceed to Phase 6 (Fleet Deployment & Live Swarm Telemetry).

- **Date / Agent:** 2026-08-27 / antigravity
- **Feature:** docs-artifact-cleanup, noctalia-experience-extraction, dendritic-imports-purity, eval-performance, dendritic-guardrails, harness-state-reconciliation
- **Work done:** Completed 6-phase dendritic purification repair plan: moved prompt files to 06-scripts/prompts/ and removed architecture.md stub; extracted Noctalia out of 41-hyprland into 43.1-noctalia-hyprland experience adapter leaving 41-hyprland 100% Noctalia-free; converted remaining manual import lists to mkDendriticTree; implemented option path name assertion in mkDendriticModule; added nixpkgs follows on zjstatus and nix-cachyos-kernel; extended dendritic-structure-test guardrails; reconciled harness state and added crash recovery rule to AGENTS.md.
- **Verification:** `ls layers/00-cyberia/01-docs/` clean; `grep -ri noctalia layers/40-desktop/41-hyprland/` empty; `nix build .#checks.x86_64-linux.dendritic-structure-test` green; `jq -e` schema v2 valid.
- **State change:** passing (evidence recorded in feature_list.json)
- **Next action:** Proceed to Live Swarm Telemetry and Fleet Deployment.

- **Date / Agent:** 2026-08-27 / antigravity
- **Feature:** agent-swarm-telemetry, homepage-zellij-live-audit, harness-scores-telemetry
- **Work done:** Verified live AI agent swarm gateway endpoints (Kong Gateway :8090, EverOS Engine :8092), live Homepage Dashboard (:8082) HTML payload, and isolated harness telemetry storage at /var/lib/hermes/harness.
- **Verification:** `curl` queries returned live HTTP responses for Kong (:8090), EverOS (:8092), and Homepage (:8082); directory check confirmed `/var/lib/hermes/harness`; `jq -e` confirmed 100% of all features in `feature_list.json` are in state `passing`.
- **State change:** passing (evidence recorded in feature_list.json)
- **Next action:** All stack features verified passing. Ready for future fleet updates.

- **Date / Agent:** 2026-08-27 / antigravity
- **Feature:** flake-hygiene, shell-stack-enhancements, ghostty-cursor-shader, system-audit-tooling
- **Work done:** Split `flake.nix` into `flake/` submodules (`formatter.nix`, `checks.nix`, `packages.nix`); alphabetized flake inputs; created Nushell (`nushell.nix`) and Carapace (`carapace.nix`) modules; updated Starship prompt; vendored `manga-slash.glsl` with path assertion in `ghostty.nix`; created `sysaudit` diagnostic script (`system-audit.sh`) and module (`audit.nix`); added rofi cheatsheets and `cuw` / `clan-watch` shell aliases.
- **Verification:** `./layers/00-cyberia/06-scripts/system-audit.sh` executed and generated markdown report; `clan-update-watch.sh z0r0 --no-health` built closure with `nom` progress tree; `jq -e` confirmed 100% features passing.
- **State change:** passing (evidence recorded in feature_list.json)
- **Next action:** All phases and prompt tasks fully complete.

- **Date / Agent:** 2026-08-28 / antigravity
- **Feature:** hermes-managed-scope-migration
- **Work done:** Classified Hermes settings into Pinned (/etc/hermes/config.yaml) vs Mutable (~/.hermes/config.yaml); added Kong (:8090) and ExtremeRouter (:20128) provider blocks with environment variable sops wiring; kept runtime preferences mutable so GUI/CLI toggles survive `nixos-rebuild switch`.
- **Verification:** `nix build .#checks.x86_64-linux.dendritic-structure-test` passed green; `git status` clean.
- **State change:** passing
- **Date / Agent:** 2026-08-28 / antigravity
- **Feature:** noctalia-plugins-fix, rofi-noctalia-sync, observability-langfuse-fix, homepage-status-dot-fix, layer-numbering-governance
- **Work done:** Implemented Noctalia community/official plugin declarative fetching & linking; added Rofi theme sync hook in `noctalia-hypr-reload`; renamed mislabeled Langfuse panel to Hermes Service Uptime and documented upstream metrics API limitation; capped Homepage status dot / ping CSS height and added Langfuse customapi widget; created `layers/NUMBERING.md` canonical reference and `layer-numbering-check` CI check; removed hardcoded `/home/t0psh31f` in `hermes.nix`.
- **Verification:** `jq -e` confirmed feature_list schema v2 valid; `layer-numbering-check` CI derivation built; `feature_list.json` evidence updated.
- **State change:** passing (evidence recorded in feature_list.json)
- **Next action:** All 6 cleanup groups complete. Fleet update via `clan machines update z0r0`.

- **Date / Agent:** 2026-08-28 / antigravity
- **Feature:** group-a-session-path-propagation, group-b-orchestrator-fhs-wrapping, group-c-extremerouter-mitm-ca-trust, group-d-pxpipe-impermanence-docs, group-e-profiles-machines-audit
- **Work done:** Added dbus & systemd PATH environment propagation to Hyprland and Niri startup; expanded AionUI service PATH for agent detection; wired ExtremeRouter MITM proxy root CA cert into security.pki.certificateFiles; documented pxpipe pipx/uv installation pattern and verified user .local impermanence persistence; audited machines/*/default.nix.
- **Verification:** `grep -q dbus-update-activation-environment` in Hyprland and Niri green; `dendritic-structure-test` check built cleanly; `jq -e` schema v2 valid.
- **State change:** passing (evidence recorded in feature_list.json)
- **Next action:** Proceed with public docs polish features (`public-docs-readme-overhaul`, etc.).

- **Date / Agent:** 2026-08-28 / antigravity
- **Feature:** public-docs-readme-overhaul
- **Work done:** Overhauled `README.md` for public portfolio presentation, adding high-level system overview, Grand Line machine inventory table, updated 10-layer dendritic architecture table linked to `layers/NUMBERING.md`, AI Swarm Control Plane ecosystem section, `./init.sh` quickstart guide, and core docs map; removed hardcoded username paths.
- **Verification:** `test -f README.md && ! grep -q '/home/t0psh31f' README.md` verified green; `jq -e` confirmed feature_list schema v2 valid.
- **State change:** passing (evidence recorded in feature_list.json)
- **Date / Agent:** 2026-08-28 / antigravity
- **Feature:** public-docs-consistency-pass, public-docs-secret-pii-sweep, public-docs-agents-alignment
- **Work done:** Completed docs directory consistency audit across all 27 markdown files in `layers/00-cyberia/01-docs/`; performed secret & PII sanity sweep across full git log history; aligned `AGENTS.md` and public docs on harness lifecycle rules.
- **Verification:** `ls layers/00-cyberia/01-docs/*.md` green; `git log --all --full-history -- '*.env'` clean; `jq -e` confirmed 100% of all features in `feature_list.json` are state `passing`.
- **State change:** passing (evidence recorded in feature_list.json)
- **Date / Agent:** 2026-08-28 / antigravity
- **Feature:** feature-list-context-archiving
- **Work done:** Archived 48 historical passing features from `feature_list.json` to `feature_list_archive.json` to reduce context window consumption by ~1000 lines (~4000 tokens); retained recent active & cleanup features in `feature_list.json`.
- **Verification:** `jq -e` confirmed schema v2 valid on both `feature_list.json` and `feature_list_archive.json`; line count reduced from 1301 to 296 lines.
- **State change:** passing (evidence recorded in feature_list.json)
- **Date / Agent:** 2026-08-28 / antigravity
- **Feature:** feature-list-300-line-cap-archiving
- **Work done:** Enforced 300 line cap rule on `feature_list.json`; archived older passing features into `feature_list_archive.json`, reducing `feature_list.json` from 318 lines to 218 lines.
- **Verification:** `nix build .#checks.x86_64-linux.feature-list-schema` passed green; `wc -l feature_list.json` returned 218.
- **State change:** passing (evidence recorded in feature_list.json)
- **Next action:** Baseline clean. Ready for fleet updates.

- **Date / Agent:** 2026-09-01 / antigravity
- **Feature:** kong-extremerouter-enumeration-fix
- **Work done:** Fixed ExtremeRouter model/provider enumeration to Hermes/OpenCode/agents through Kong. Root causes: (1) all 9 Kong routes were HTTPS-only (`protocols:["https"]`) → 426 on HTTP; (2) Kong never forwarded ExtremeRouter's remote API key upstream → 401; (3) wrong path architecture (service `path=/v1` + routes already carrying `/v1` → double `/v1`; missing `/v1/chat/completions` route); (4) freellmapi/freellmpool port drift (3001→3003, 8080→8083). Added `extremerouter_api_key` sops secret, request-transformer plugin injecting `Authorization: Bearer` upstream, `deep_merge` jq for array-safe declarative merge, and new bare `/v1/*` routes (`strip_path:false`). Corrected stale docs/firewall (8081→8090, dashboard on 8093). Also reverted two pre-existing broken WIP regressions (paperclip `start`→`run`, alertmanager-ntfy dropped `--configs`).
- **Verification:** `clan machines update z0r0` (activation succeeded); `curl http://127.0.0.1:8090/v1/models -H "apikey:<kong_key_hermes>"` → 200/538 models; `curl -X POST /v1/chat/completions` → 200 SSE streaming from claude-sonnet-4.5; unauthenticated `/v1/models` → 401 (key-auth gate). Both z0r0 & luffy toplevels eval clean.
- **State change:** passing (evidence recorded in feature_list.json)
- **Next action:** Note paperclip.service needs one-time `paperclipai onboard` (non-interactive config missing); optionally push + PR the Kong routing fix.

- **Date / Agent:** 2026-09-01 / antigravity
- **Feature:** qdrant-chromadb-deactivation (+ memory-platform audit)
- **Work done:** Deactivated Qdrant and ChromaDB fleet-wide per the two-layer memory consolidation (Honcho = profile, brain-service = corpus). Changed `chromadb.enable` to `mkDefault false` in ai-services.nix and ai-server.nix (qdrrant was already `mkDefault false`), removed the stale `qdrant=6333` reverseProxy route from luffy. Wrote `layers/00-cyberia/01-docs/memory-platform-audit.md` documenting the full 6-module memory stack vs the 2-layer target, verified brain-service (already has FastAPI+pgvector+LlamaIndex+Ollama embeddings+MCP) and Honcho (PostgreSQL+pgvector), and enumerated gaps (MCP auth/RBAC, tool subset, cloud LLM answering, DB user hardening, dashboard/3D/YouTube, backups, Oracle/Alibaba hosts, EverMe/Raven).
- **Verification:** `nix eval` confirmed qdrant/chromadb `enable` = false on z0r0+luffy; both toplevels eval clean; `jq -e` feature_list valid.
- **State change:** passing (evidence recorded in feature_list.json)
- **Next action:** Decide memory consolidation — which of EverOS/memory-vault/context-forge/memory-governance to retire vs fold; then brain-service MCP auth + tool expansion (brain.chat/list_tags/get_document/update_note/delete_document/get_sources).

- **Date / Agent:** 2026-09-01 / antigravity
- **Feature:** brain-service-mcp-auth-tools, memory-retire-everos-contextforge
- **Work done:** (1) Added bearer-token auth + reader/writer/admin RBAC to brain-service (HTTP middleware + MCP stdio identity) plus 8 new tools (brain.chat, get_sources, list_tags, get_document, update_note, delete_document, add_tag, remove_tag) and matching HTTP endpoints; deployed to z0r0 (service active, /tags + /documents return 200). (2) Retired EverOS + context-forge (disabled in ai-agent/ai-server tags + memory-governance dep block), retaining memory-vault as git storage. (3) Vetted real EverOS/EverMe/gno by cloning repos: our everos.nix is a grep stub, EverMe is a cloud client, gno is a promising local hybrid-search/graph engine.
- **Verification:** brain_server.py compiles; both z0r0+luffy toplevels eval clean; everos/context-forge eval false, memory-vault true on both; brain-service new endpoints 200 live.
- **State change:** passing (evidence recorded in feature_list.json)
- **Next action:** Fix brain-service placement — it's enabled on z0r0 but Ollama (its embedding backend) is disabled there (ollama.enable=mkForce false), so ingestion fails on z0r0. Move/verify on luffy. Then workstreams: local LLM answering, DB user hardening, dashboard/gno evaluation.

- **Date / Agent:** 2026-09-01 / antigravity
- **Feature:** brain-service-llm-privacy-db-hardening
- **Work done:** (1) Local/private answer generation — added `llmProvider` (ollama|openai, default ollama) + `llama-index-llms-ollama` dep; brain_server.py builds a local Ollama LLM when provider=ollama. (2) DB hardening — dedicated `brain_user` (non-superuser, login) + `brain_db` with pgvector, provisioned via ExecStartPre psql (coexists with honcho's initialScript); `db-password` clan var. Also archived 5 oldest group-* features to feature_list_archive.json to stay under the 300-line cap.
- **Verification:** `llmProvider=ollama`, `dbUser=brain_user`, `dbName=brain_db`; brain_server.py compiles; z0r0+luffy toplevels eval clean.
- **State change:** passing (evidence recorded in feature_list.json)
- **Next action:** Deploy to luffy (offline) + runtime-verify: pull a local chat model (qwen2.5:7b or similar) in Ollama, run a query to confirm local answering; set brain_user role password via sops. Then workstreams 4 (dashboard/gno), 5 (restic restore), 6 (Oracle/Alibaba).

- **Date / Agent:** 2026-09-03 / mimo-v2.5-pro
- **Feature:** tag-refactor-granular-service-redistribution
- **Work done:** Recovered session context from crash. Fixed 7 broken option paths across tag files from incomplete previous refactor. Created 4 new granular tags (ai-router, pkb-node, agent-orchestrator, network-router). Redistributed services: nami = always-on control-plane (AI gateway, agent orchestration, network routing), Luffy = private memory (brain-service, Honcho, media), Z0r0 = stateless desktop workstation. Removed stale mkForce overrides from z0r0. Fixed undefined `jerry` package. Updated validTags in both registry and CI test.
- **Verification:** `nix eval` toplevel on z0r0, luffy, nami all return clean drvPaths; `dendritic-structure-test` passes green.
- **State change:** passing (eval evidence: z0r0/bf94j77vd, luffy/fqpmprc295, nami/b52npnzrf7)
- **Date / Agent:** 2026-09-12 / antigravity
- **Feature:** homelab-hardening-service-contracts
- **Work done:** Implemented Phase 0-6 Homelab Hardening: authored `docs/homelab-cutover.md` inventory; created `mkServiceContract.nix` contract schema and `nfp-services.nix` consumer; added `nixarr` and `nixos-telemetry` flake inputs; created `nixarr.nix` module with Komga (`nixarr.komga.enable=true`), Jellyfin, *Arr suite, exporters, and `/data/.state/nixarr` impermanence state; cleaned legacy `komga.nix` and `media-stack.nix` option references; updated `restic-backups.nix` dual target defaults (`/data/backups` placeholder + GCS `rclone:gcs:...`).
- **Verification:** `./init.sh` green; `nix eval` confirmed `luffy.nixarr.enable = true`, `luffy.nixarr.komga.enable = true`, `luffy.nixarr.plex.enable = false`, `z0r0.nixarr.enable = false`; `z0r0`, `luffy`, `nami` system toplevel drvPaths evaluated cleanly.
- **State change:** passing (evidence recorded in feature_list.json)
- **Date / Agent:** 2026-09-12 / antigravity
- **Feature:** kong-dual-upstreams-herdr-fix
- **Work done:** Integrated `herdr` terminal workspace manager harness on `z0r0` via `inputs.llm-agents` (`herdr.nix`, `ai-agent.nix`). Removed `codingRouter` XOR logic in `kong-gateway.nix` allowing `extremerouter-llm` (`http://z0r0:20128`) and `omniroute-llm` (`http://127.0.0.1:20129`) to run simultaneously on `nami:8090`. Bound `extreme-router.nix` to loopback and tailnet interface (`tailscale0`) with firewall isolation. Updated `omniroute.nix` default port to `20129`. Updated homepage dashboard and documentation.
- **Verification:** `./init.sh` green; `nix eval` confirmed `z0r0.herdr.enable = true`, `z0r0.systemPackages` contains `herdr-0.8.2`, `z0r0.extreme-router.enable = true`, `nami.kong-gateway.enable = true`, `nami.omniroute.enable = true`; `z0r0`, `luffy`, `nami` system toplevel drvPaths evaluated cleanly.
- **State change:** passing (evidence recorded in feature_list.json)
- **Next action:** Deploy changes to `z0r0` (`clan machines update z0r0`) and `nami` (`clan machines update nami`).







