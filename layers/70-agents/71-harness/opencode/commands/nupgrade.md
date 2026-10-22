# /nupgrade — Architectural Evolution, Self-Reflection & Portfolio Showcase

Strategic codebase evolution, deep self-reflection, and documentation polish. Evaluates opportunities across the entire architecture, presents 15–20 high-value proposals (simplification, optimization, new modules/tools) with trade-off analysis, and upgrades documentation into a GitHub portfolio showcase.

Usage: `/nupgrade [category]` (e.g., `/nupgrade all`, `/nupgrade docs`, `/nupgrade agents`)

---

## Phase 1: Architectural Deep Scan & Self-Reflection
Analyze the full repository across all tiers:
1. **Dendritic Architecture**: Review `layers/` (00-cyberia to 90-profiles) for modularity bottlenecks, missing abstractions, or excessive complexity.
2. **Simplification & Subtractions**: Find features or layers that can be done more simply, removed, or consolidated without loss of capability.
3. **Agent & Harness Stack**: Audit `70-agents` (harnesses, memory, MCP, routers, skills) for modern models, token efficiency, and protocol improvements.
4. **Hardware & Fleet Synergy**: Review machine configurations (`z0r0`, `luffy`, `sanji`) for optimal service distribution and resource allocation.

---

## Phase 2: Formulate 15–20 Concrete Proposals
Present a numbered catalog of 15 to 20 actionable proposals. Every proposal MUST follow this structured format:

```markdown
### [N]. [Title] ([Category: Optimization | Simplification | Feature | Security | Portfolio])
- **What it does**: Direct description of the proposed change.
- **Problem solved / Opportunity**: What this fixes, improves, or prevents.
- **Why this approach**: Architectural rationale and trade-offs.
- **Action items**: Concrete files to modify or create.
- **User decision**: [Proceed | Skip | Modify]
```

*Rule: Do NOT apply code changes in this phase. Await explicit user selection/approval.*

---

## Phase 3: Documentation & Portfolio Polish
Review and transform repository documentation into an attractive, production-grade portfolio showcase:
1. **Visual Architecture**:
   - Create or update GitHub-flavored Mermaid diagrams (flowcharts, sequence diagrams, topology maps).
   - Add clear hardware fleet matrix (`z0r0`, `luffy`, `sanji`, specs, offload topology).
2. **README Frontpage**:
   - Modern, high-contrast, structured layout with badges, architecture overview, and quickstarts.
3. **In-Depth Subsystem Docs**:
   - Review layer documentation (`00-cyberia/01-docs/`, `70-agents/`, etc.).
   - Ensure intricate features (Kong gateway routing, FreeLLM pooling, impermanence, Btrfs subvolumes, sops-nix age secrets) have clear, browsable guides.
   - Option to generate or link a static HTML documentation book (e.g. mdBook or Astro/Starlight).

---

## Phase 4: Execution on User Approval
Once the user reviews and selects which of the 15–20 proposals to implement:
1. Apply the approved proposals in isolated, verifiable commits.
2. Run `nix flake check --no-build` after each change.
3. Update relevant documentation and diagrams in lockstep.
