---
name: reverse-engineer
description: Automated Website Reverse-Engineering Tooling for Frontend Tech Stacks, 3D Scroll Animations, & API Extraction
---

# Automated Website Reverse-Engineering Skill

## 1. Overview

The **reverse-engineer** skill allows autonomous agents to perform forensic inspection of web applications:
1. **Frontend Tech Stack**: Identifies Next.js, React, Vue, Svelte, Tailwind CSS, and WebGL architectures.
2. **3D & Scroll Animation Engines**: Detects Three.js, GSAP ScrollTrigger, Lenis smooth scrolling, Framer Motion, and Spline 3D runtimes.
3. **API & Endpoint Mapping**: Extracts REST endpoints (`/api/*`, `/v1/*`), GraphQL queries, and WebSockets (`wss://*`).
4. **Asset Extraction**: Inventories static stylesheets, bundle chunks, custom web fonts, and vector/raster graphics.
5. **Local Reporting**: Exports structured JSON forensic audits to `scratch/reverse_engineer/<domain>/report.json`.

---

## 2. CLI Execution & Verification

Run the verification test suite:
```bash
python3 layers/70-agents/79-skills/reverse_engineer/reverse_engineer.py --test
```

Inspect an external URL or local HTML file:
```bash
python3 layers/70-agents/79-skills/reverse_engineer/reverse_engineer.py --inspect "https://example.com"
```

---

## 3. Architecture & Location

- **Inspection Engine**: `layers/70-agents/79-skills/reverse_engineer/reverse_engineer.py`
- **Output Reports**: `scratch/reverse_engineer/<target>/report.json`
