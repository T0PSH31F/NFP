# Machine × Tag Matrix (`tag-matrix.md`)

## Matrix Table

The table below maps active machines (`z0r0`, `luffy`, `sanji`, `T14`) against all valid tags in `layers/90-profiles/tags/default.nix`. `nami` is archived/decommissioned.

`[X]` indicates the tag is enabled for the machine; `[ ]` indicates it is omitted.

| Tag | `z0r0` | `luffy` | `sanji` | `T14` | Assignment Rationale |
| :--- | :---: | :---: | :---: | :---: | :--- |
| `ai-agent` | `[X]` | `[X]` | `[X]` | `[X]` | Enabled on client interactive nodes (z0r0, sanji, T14) and worker nodes (luffy) for OpenCode/Hermes agent execution. |
| `ai-router` | `[ ]` | `[ ]` | `[X]` | `[ ]` | Enabled on sanji as AI API routing gateway (Kong, OmniRoute, FreeLLMAPI, FreeLLMPool). |
| `ai-server` | `[ ]` | `[X]` | `[ ]` | `[ ]` | Enabled on luffy as local memory and PKB host (Brain-service). |
| `ai-inference` | `[ ]` | `[X]` | `[X]` | `[ ]` | Hardware-accelerated local model execution (Ollama, vLLM, RTX Ada on sanji). |
| `agent-orchestrator` | `[ ]` | `[ ]` | `[X]` | `[ ]` | Enabled on sanji as swarm orchestrator (Polyfloor, Jev Engine). |
| `cache-server` | `[ ]` | `[X]` | `[ ]` | `[ ]` | Enabled on luffy to host Harmonia Nix binary cache server for local network. |
| `desktop` | `[X]` | `[X]` | `[X]` | `[X]` | Wayland (Hyprland/Niri), PipeWire audio, GUI apps. |
| `development` | `[X]` | `[ ]` | `[X]` | `[X]` | Enabled on workstation clients for developer CLI tools, compilers, IDEs, SDKs. |
| `gaming` | `[X]` | `[ ]` | `[ ]` | `[ ]` | Enabled exclusively on z0r0 for Steam, GameMode, Lutris. |
| `gpu-compute` | `[ ]` | `[X]` | `[X]` | `[ ]` | GPU compute workloads (RTX Ada on sanji, Intel/Nvidia on luffy). |
| `homelab` | `[ ]` | `[X]` | `[ ]` | `[ ]` | Enabled on luffy to run containerized services and storage. |
| `intel-12th-gen` | `[X]` | `[ ]` | `[ ]` | `[X]` | Enabled on 12th/13th gen Intel mobile processors (z0r0, T14). |
| `intel-9th-gen` | `[ ]` | `[X]` | `[ ]` | `[ ]` | Enabled on luffy for 9th gen Intel CPU microcode tuning. |
| `laptop` | `[X]` | `[ ]` | `[X]` | `[X]` | Enabled on portable battery-powered machines (z0r0, sanji, T14) for power profiles. |
| `media` | `[ ]` | `[X]` | `[ ]` | `[ ]` | Enabled on luffy for media services (Jellyfin, *arr stack, Kavita, n8n). |
| `network-router` | `[ ]` | `[X]` | `[ ]` | `[ ]` | Enabled on luffy for Headscale mesh VPN coordination. |
| `pkb-node` | `[ ]` | `[X]` | `[ ]` | `[ ]` | Encrypted PKB vault and RAG vector storage on luffy. |
| `server` | `[ ]` | `[X]` | `[ ]` | `[ ]` | Enabled on headless server hosts (luffy) for server defaults. |
| `workstation` | `[X]` | `[ ]` | `[X]` | `[X]` | Primary workstation machines (z0r0, sanji, T14) for developer desktop tooling. |

---

## Key Design Rationale

### Why `z0r0` has NO `pkb-node` or `ai-server`:
`z0r0` is a 16 GB RAM LG Gram daily driver. Running heavy vector databases, RAG embedding models, and memory servers locally cause RAM thrashing. Offloading PKB and heavy memory to `luffy` converts `z0r0` into crisp, responsive thin-client harness.

### Why `sanji` is `ai-router` + `agent-orchestrator`:
`sanji` is Dell Precision 7680 (i7-13850HX, 64 GB RAM, RTX 1000 Ada). Has compute capacity for high-throughput AI API routing (Kong, OmniRoute, FreeLLMAPI) and orchestrator workloads (Polyfloor, Jev Engine, Langfuse).

### Decommission of `nami`:
`nami` (Alibaba ECS cloud VPS) decommissioned 2026-10-14. All cloud orchestration and router functions migrated locally to `sanji` and `luffy`.
