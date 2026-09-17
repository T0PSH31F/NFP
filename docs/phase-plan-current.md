# NFP Updated Phase Execution Plan

*Date: 2026-09-10*

## 1. Capability Status Classification Summary

| Capability / Area | Status | Notes |
|-------------------|--------|-------|
| **Phase 0: Audit & Rollback Readiness** | **Completed & Documented** | State audited in `docs/audit-current-state.md`. Flake evaluation verified. |
| **Phase 1: Headscale Authority, DNS & ACLs** | **Implemented but Unverified** | Headscale & Tailscale active; ACLs currently wildcard `*:*`. Needs admin/guest ACL hardening & internal DNS check. |
| **Phase 2: SSH & Legacy Mesh Retirement** | **Completed & Documented** | Key-only SSH active on `nami`. ZeroTier & Clan WireGuard fully decommissioned. |
| **Phase 3: Homepage & Browser Routing** | **Implemented but Unverified** | Homepage active on `luffy`/`nami`. Browser default start page via Home Manager needs verification. |
| **Phase 4: Syncthing Integration** | **Not Yet Implemented** | Syncthing module missing in `layers/20-services/25-data/`. Needs folder configs for `~/Clan`, `~/Projects`, `~/Notes`. |
| **Phase 5: Monitoring Consolidation** | **Completed & Documented** | Prometheus, Grafana, Loki, Alloy, Alertmanager-ntfy running on `luffy`/`nami`. Exporters configured. |
| **Phase 6: Media & Nixarr Adoption** | **Completed & Documented** | Media stack running on `luffy`. Nixarr patterns adopted. |
| **Phase 7: Recovery ISO** | **Completed & Documented** | Noctalia installer ISO active in `layers/00-cyberia/08-iso/noctalia-installer.nix`. |
| **Phase 8: Docs & Maintenance** | **In Progress** | Documentation updated per phase. |

---

## 2. Adapted Execution Order for This Run

1. **Phase 4 (HIGHEST PENDING PRIORITY: Implement from scratch)**:
   - Create `layers/20-services/25-data/syncthing.nix` NixOS module.
   - Configure Syncthing peer-to-peer sync between `z0r0` and `luffy` bound strictly to Tailscale mesh.
   - Define folder syncs for `~/Clan`, `~/Projects`, `~/Notes` with `.stignore` rules (ignoring `.git` objects for Git-authoritative repos, build artifacts, etc.) and staggered versioning on `luffy`.
   - Update tag profiles (`workstation`, `homelab`, `pkb-node`) and test flake evaluation.

2. **Phase 1 (FINISH & HARDEN)**:
   - Harden Headscale ACL hujson rules in `layers/20-services/21-networking/headscale.nix` (`group:admin` vs `group:guest`).
   - Verify MagicDNS / internal domain routing (`.lovelain.duckdns.org`).

3. **Phase 3 & Phase 8 (DOCUMENTATION & BROWSER ROUTING)**:
   - Ensure browser home page on `z0r0` points to `http://home.lovelain.duckdns.org` or `http://100.72.46.75:3007`.
   - Document Syncthing configuration, Headscale ACLs, and maintenance routines across READMEs.
