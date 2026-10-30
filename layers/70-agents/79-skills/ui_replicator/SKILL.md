---
name: ui-replicator
description: Iterative Visual UI Replicator & Design Hill-Climbing Engine for Autonomous Frontends
---

# UI Replicator & Design Hill-Climbing Skill

## 1. Overview

The **UI Replicator** skill provides autonomous pair programming agents with an iterative visual hill-climbing feedback loop:
1. **Target Ingestion**: Ingests UI screenshots, Figma mockups, or natural-language design specs.
2. **Layout Synthesis**: Synthesizes responsive layout code (HTML, Tailwind CSS, or React components).
3. **Headless Browser Rendering**: Renders the design in a headless Wayland/Chromium browser context (`camofox`, `donut-browser`, or Playwright).
4. **Visual Similarity Analysis**: Computes structural, color-histogram, and perceptual match percentages against the target.
5. **Iterative Hill-Climbing**: Loops until visual parity exceeds the configured target threshold (default `>= 90%`).

---

## 2. CLI Execution & Verification

Run the self-test verification suite:
```bash
python3 layers/70-agents/79-skills/ui_replicator/ui_replicator.py --test
```

Run a replication job:
```bash
python3 layers/70-agents/79-skills/ui_replicator/ui_replicator.py --replicate "Aperture Science Voice Chamber Dashboard"
```

---

## 3. Architecture & Output Directory

- **Engine Script**: `layers/70-agents/79-skills/ui_replicator/ui_replicator.py`
- **Output Artifacts**: `scratch/ui_replicator/iteration_{n}/`
  - `index.html`: Rendered HTML & Tailwind code
  - `render.png`: Captured screenshot
  - `replication_summary.json`: Multi-round hill-climbing score trajectory
