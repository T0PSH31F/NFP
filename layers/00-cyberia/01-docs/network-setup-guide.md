# Network Setup & Topology Guide — NFP Fleet

## Architecture Overview

```
                               ┌─────────────────────────────────────────┐
                               │   nami (nami) — Cloud Control Plane    │
                               │   Public IP: 47.254.90.69               │
                               │                                         │
                               │   • Headscale Control Plane (:8086)     │
                               │   • Caddy SSL Proxy (:80, :443)         │
                               │   • Tailscale Client                    │
                               │   • OmniRoute / Kong Gateway (:8090)    │
                               │   • Hermes / Mission Control            │
                               └────────────────────┬────────────────────┘
                                                    │
                                  Tailnet Mesh (100.64.0.0/10)
                                  MagicDNS Domain: lovelain.duckdns.org
                                                    │
              ┌─────────────────────────────────────┴─────────────────────────────────────┐
              │                                                                           │
┌─────────────┴──────────────────────────┐                               ┌────────────────┴──────────────────────────┐
│  z0r0 — Workstation / AI Agent         │                               │  luffy — Homelab / PKB Memory             │
│  Tailnet IP: 100.64.x.x                │                               │  Tailnet IP: 100.80.146.120               │
│  DNS: z0r0.lovelain.duckdns.org        │                               │  DNS: luffy.lovelain.duckdns.org          │
│                                        │                               │                                           │
│  • Tailscale Client                    │                               │  • Tailscale Client                       │
│  • ExtremeRouter (127.0.0.1:20128 ONLY)│                               │  • Brain Service / Honcho / Qdrant        │
│  • Local Dev / Workstation Apps        │                               │  • Harmonia Cache / Matrix Homeserver     │
└────────────────────────────────────────┘                               └─────────────────────────────────────────┘
```

## Fleet Overlay Network Specification

- **Authoritative Control Plane**: `nami` (`nami`) running Headscale (`https://headscale.lovelain.duckdns.org`).
- **Client Overlay Daemon**: Standard `services.tailscale` clients targeting `--login-server=https://headscale.lovelain.duckdns.org`.
- **Domain & Addressing**: `*.lovelain.duckdns.org` within `100.64.0.0/10` CIDR block.
- **Decommissioned Overlays**: ZeroTier and Clan WireGuard have been fully decommissioned. Tailscale is the sole inter-node mesh.

## Node Inventory & Tailnet Mapping

| Node Name | Host Alias | Role / Purpose | Tailnet DNS | WAN / LAN IP | Open Ports (WAN) | Tailnet Allowed Flows |
|-----------|------------|----------------|-------------|--------------|------------------|-----------------------|
| `nami` | `nami` | Cloud Control Plane / Headscale | `nami.lovelain.duckdns.org` | `47.254.90.69` | 22 (SSH), 80 (HTTP), 443 (HTTPS), 8086 (Headscale) | Tailscale coordination, Kong Gateway, Hermes, gno sync |
| `luffy` | `luffy` | Homelab Server / PKB Memory | `luffy.lovelain.duckdns.org` | `192.168.1.54` (LAN) | 22 (SSH LAN/WAN), 41641 (Tailscale UDP) | Brain Service, Honcho, Qdrant, Matrix, Harmonia |
| `z0r0` | `z0r0` | Workstation / Dev Laptop | `z0r0.lovelain.duckdns.org` | `192.168.1.39` (LAN) | 22 (SSH LAN/WAN), 41641 (Tailscale UDP) | Tailnet client access; ExtremeRouter (127.0.0.1:20128 only) |

## ExtremeRouter & Scoping Guardrails

- `z0r0` ExtremeRouter is strictly bound to `127.0.0.1:20128` (local loopback). It is NOT exposed to Tailnet or public WAN interfaces.
- `nami` OmniRoute runs on `nami` host on port `20128` fronted by Kong Gateway (`:8090`).

## Emergency Out-of-Band Recovery Procedures

If Tailscale connectivity is lost on any node:

1. **nami (`nami`) Recovery**:
   - Access via direct WAN SSH from allowed admin IP: `ssh root@47.254.90.69`
   - Alternatively, open Alibaba Cloud Web Console VNC terminal.
   - Run: `systemctl restart tailscaled && tailscale status`

2. **Luffy Recovery**:
   - Access via direct physical LAN SSH: `ssh root@192.168.1.54`
   - Run manual authentication trigger:
     ```bash
     systemctl restart tailscaled
     tailscale up --login-server=https://headscale.lovelain.duckdns.org
     ```

3. **Z0r0 Recovery**:
   - Access via direct local workstation terminal or LAN SSH (`192.168.1.39`).

## Fleet Post-Rebuild Command Checklist

Run these validation steps after every `clan machines update`:

```bash
# 1. Execute automated tailnet verification suite
./layers/00-cyberia/06-scripts/validate-tailnet-mesh.sh

# 2. Check Headscale node list on nami
ssh root@nami.lovelain.duckdns.org "headscale nodes list"

# 3. Check client daemon status on z0r0 / luffy
tailscale status

# 4. Verify inter-node endpoint reachability
curl -sf http://luffy.lovelain.duckdns.org:8010/healthz   # Luffy Brain Service
curl -sf http://nami.lovelain.duckdns.org:8090/status    # nami Kong Gateway
curl -sf http://127.0.0.1:20128/v1/models         # Z0r0 local ExtremeRouter
```