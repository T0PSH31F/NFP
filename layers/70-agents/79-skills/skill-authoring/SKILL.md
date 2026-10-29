---
name: skill-authoring
description: On-the-fly dynamic skill creation, evolution, and registration protocol for AI agents
category: meta
triggers:
  - skill-authoring
  - new-skill
  - skill-evolution
  - author-skill
---

# Dynamic Skill Authoring & Evolution Protocol

## 1. Overview & Operational Intent
Enables autonomous AI agents (Pi, OpenCode, Hermes, Antigravity) to synthesize, validate, and register new modular skills directly into `layers/70-agents/79-skills/` on the fly when discovering recurring patterns, novel workflows, or specialized troubleshooting procedures.

- **Storage Location**: `layers/70-agents/79-skills/<skill-slug>/SKILL.md`
- **Harness Integration**: Auto-symlinks into `layers/70-agents/71-harness/opencode/skills/<skill-slug>`
- **Tool Access**: Available via CLI (`nfp-skill-author`) and stdio MCP tool (`author_skill`)

---

## 2. When to Use & Trigger Conditions
Invoke this protocol whenever:
- A multi-step workflow was executed successfully and should be codified as a repeatable skill.
- The user asks to teach or give the agent a new capability (e.g., "Learn how to triage Postgres locks").
- Recurring weaknesses are discovered during the nightly Dream Cycle that require explicit execution playbooks.

---

## 3. Step-by-Step Instructions & Execution Protocol

### Step 3.1: Choose a Descriptive Slug
The skill name must be a clean, hyphenated lowercase slug (e.g. `zfs-scrub-monitor`, `pg-slow-query-analyzer`).

### Step 3.2: Structure the Skill Content
Every `SKILL.md` must include:
1. Valid YAML frontmatter (`name`, `description`, `category`, `triggers`).
2. Overview & Operational Intent.
3. Trigger Conditions.
4. Step-by-step instructions with concrete code snippets and commands.
5. Verification commands and guardrails.

### Step 3.3: Execute Skill Authoring via CLI or MCP
Using CLI:
```bash
nfp-skill-author create \
  --name "redis-health-audit" \
  --description "Diagnostic commands for auditing Redis memory and key expiry" \
  --instructions "1. Run redis-cli info memory. 2. Verify maxmemory policy." \
  --category "database"
```

Using MCP Tool (`author_skill`):
```json
{
  "name": "redis-health-audit",
  "description": "Diagnostic commands for auditing Redis memory and key expiry",
  "instructions": "1. Run redis-cli info memory. 2. Verify maxmemory policy.",
  "category": "database"
}
```

### Step 3.4: Verify the New Skill
Run validation check:
```bash
nfp-skill-author verify redis-health-audit
```

---

## 4. Verification & Deterministic Guardrails
- All newly authored skills must pass formatting checks (`nix fmt`).
- Avoid hardcoding secrets, absolute non-impermanent paths, or deprecated Nix syntax.
- Verify that the OpenCode symlink in `layers/70-agents/71-harness/opencode/skills/` is valid.
