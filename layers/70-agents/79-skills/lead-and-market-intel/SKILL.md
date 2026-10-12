---
name: lead-and-market-intel
description: Operational skill pack for Jev System-1 Inbound Lead Triage and Ad Hook Market Intelligence Mining
---

# Jev Inbound Lead Qualification & Market Intelligence Skill

## 1. Overview & High-Value Pipelines

This skill equips agents with operational procedures to execute and supervise two high-velocity business pipelines powered by **Jev** (TypeSafe AI System-1 Decision Engine):

1. **Pipeline 1: Inbound Lead Qualification & Deal Triage**
   - Ingests web forms, CRM webhooks, and direct prospect inquiries.
   - Evaluates sub-10ms decision trees against strict lead schemas.
   - Triggers automated alerts, booking links, and CRM cards for hot deals while escalating edge cases.

2. **Pipeline 2: High-Volume Ad Hook & Market Intelligence Miner**
   - Ingests competitor ad dumps, marketplace reviews, and social discussions.
   - Classifies hook types, objection handling, buyer personas, and CTA urgency.
   - Generates daily Markdown intelligence digests for PKB ingestion and agent strategy.

---

## 2. Pipeline 1: Lead Qualification & Deal Triage

### 2.1 Decision Schema (`lead_scoring.json`)
- **qualification_tier** (enum):
  - `tier_1_enterprise_hot`: Enterprise scope ($25k+, 40+ nodes/servers, urgent timeline, SLA requirements).
  - `tier_2_smb_warm`: SMB consulting, architectural review, migration planning ($5k–$20k).
  - `tier_3_low_budget_cold`: Student, hobby project, exploratory with under $1k budget.
  - `spam_or_jobseeker`: Job applications, marketing agency pitches, unsolicited SEO spam.
- **estimated_deal_size** (enum): `under_5k`, `5k_to_20k`, `20k_to_100k`, `enterprise_100k_plus`
- **technical_fit** (boolean): `true` if requirement matches NixOS, infrastructure automation, distributed systems, or LLM engineering; `false` otherwise.
- **urgency_timeline** (enum): `immediate_under_2_weeks`, `quarterly_1_3_months`, `exploratory`

### 2.2 Operational Routing Rules
When handling incoming inquiries:
1. **Hot Lead Action:** If `qualification_tier == "tier_1_enterprise_hot"` AND `confidence >= 0.85`:
   - Send instant alert to Matrix (`#ops-leads`) and ntfy.
   - Auto-dispatch discovery booking link: `https://cal.com/topsh31f/discovery`.
   - Stage lead card in `/var/lib/lead-triage/hot_leads/<lead_id>.json`.
2. **Ambiguous or Edge Cases (< 0.80 Confidence):**
   - Stage in `/var/lib/lead-triage/needs_review/<lead_id>.json`.
   - Escalate to Hermes or human operator for drafted clarification reply.

### 2.3 Invoking via MCP (`jev-decision`)
```json
{
  "name": "jev_lead_triage",
  "arguments": {
    "lead": {
      "company": "Apex Logistics",
      "name": "Alex Vance",
      "email": "alex@apexlogistics.io",
      "budget_self_reported": "$25k+",
      "message": "We need an urgent custom NixOS fleet deployment for 40 servers by next month."
    }
  }
}
```

---

## 3. Pipeline 2: Ad Hook & Market Intelligence Miner

### 3.1 Decision Schema (`ad_hook_analysis.json`)
- **hook_category** (enum):
  - `pain_point_frustration`: Highlights wasted developer hours, slow builds, debugging friction.
  - `fear_of_loss`: Focuses on system downtime, security vulnerabilities, falling behind competitors.
  - `social_proof`: Cites customer metrics, enterprise logos, developer count.
  - `curiosity_novelty`: Teases new breakthroughs, unconventional methodologies.
  - `direct_savings_roi`: Concrete cost reductions (e.g. "80% faster", "cut cloud spend by $10k").
- **primary_objection_handled** (enum): `setup_complexity`, `pricing_cost`, `security_compliance`, `performance_speed`
- **target_persona** (enum): `devops_infrastructure_lead`, `founder_cto`, `individual_contributor`, `finance_buyer`
- **call_to_action_urgency** (enum): `free_trial`, `book_demo`, `limited_offer`, `content_download`

### 3.2 Ingestion & Report Lifecycle
- Raw ad dumps or scraped posts are placed into `/var/lib/ad-miner/inbox/` as `.csv`, `.jsonl`, or `.txt`.
- The `ad-hook-miner` daemon batches items through Jev decision trees.
- Processed items are appended to `/var/lib/ad-miner/data/ad_hooks.jsonl`.
- Daily summaries are formatted into `/var/lib/ad-miner/reports/YYYY-MM-DD_market_hooks.md` for team review.

### 3.3 Invoking via MCP (`jev-decision`)
```json
{
  "name": "jev_ad_hook_mine",
  "arguments": {
    "ad_copy": "Tired of slow Nix builds wasting developer hours? Our remote build cache cuts build times by 80% with zero config."
  }
}
```
Expected output:
- `hook_category`: `pain_point_frustration`
- `primary_objection_handled`: `setup_complexity`
- `target_persona`: `devops_infrastructure_lead`
- `call_to_action_urgency`: `free_trial`
- `confidence`: $\ge 0.90$
