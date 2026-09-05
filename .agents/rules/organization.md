---
trigger: always_on
---

# 🧱 Master Directive: NFP Dendritic Layer Migration (Zero-Loss Enforcement)

Context: You are performing a structural refactor of the NFP repository to transition from a "feature-based" architecture to a "dendritic layered" architecture.

STRICT MISSION RULES (NO EXCEPTIONS):

LOGIC LOCK: You must preserve 100% of the existing internal logic, comments, formatting, and whitespace. You are NOT allowed to "clean," "shorten," or "optimize" any code block.
LIFT & SHIFT: When breaking up monoliths (like ai-services.nix), you must copy the exact logic blocks character-for-character into their new specialized files.
SCHEMA ALIGNMENT: Migrate all configuration triggers from `features.*` or `services.config.*` to the `layers.lXX` tree (e.g., `layers.l20.config.adguard`).
PARITY CHECK: Before finalizing any module, you must verify that every systemd service, static user, persistence rule, and OCI container from the original file is present in the new structure.
PHASE 1: AI MODULARIZATION Split layers/20-services/22-ai/ai-services.nix into the following 1:1 modules:

interface.nix: (OpenWebUI, NextJS UI, SillyTavern)
voice.nix: (Wyoming, Kokoro, TTS/STT services)
server.nix: (Ollama, LocalAI, LM Studio, Jan, LLMs)
agents.nix: (brain-service, llm-agents, zeroclaw, etc.)
observability.nix: (Langfuse, Skills, Beads)
databases.nix: (PostgreSQL/pgvector, Qdrant, ChromaDB)
PHASE 2: TAG ARCHITECTURE Create/Update Tag Profiles in layers/90-profiles/tags/ to map machine tags to these new granular modules:

android / ios: (Separate mobile integration tags)
peripherals: (Config for Logitech, OpenRGB, Corsair, Razer, xpadneo)
library: (Calibre/Library services)
social: (Matrix servers and Mautrix bridges)
vpn-host: (Headscale server)
AI Split Tags: ai-interface, ai-voice, ai-server, ai-local-agents, ai-observability.
PHASE 3: HARDWARE ABSTRACTION Implement a hardware tagging system in layers/10-system/12-hardware/ to handle:

amd, amd-gpu, intel, intel-gpu, nvidia-gpu.
Ensure these tags correctly trigger the respective drivers and kernel modules without hardcoding them into the machine level.
PHASE 4: COMPOSITION Ensure the z0r0 machine configuration in clan.nix (or its machine folder) has all these tags enabled, and verify that nix flake check passes.

MANDATORY LAYER NUMBERING GOVERNANCE:
Before creating ANY new directory under `layers/`, you MUST check `layers/NUMBERING.md` to pick an unassigned number within the reserved band and register the new directory in `layers/NUMBERING.md` in the same commit. Failure to do so will break CI (`check-layer-numbering`).


Does this prompt accurately capture the level of rigor and the specific organizational split you are looking for? If so, I will wait for your signal to begin executing it phase-by-phase.