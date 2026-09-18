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
                                  MagicDNS Domain: nfp.nix
                                                    │
              ┌─────────────────────────────────────┴─────────────────────────────────────┐
              │                                                                           │
┌─────────────┴──────────────────────────┐                               ┌────────────────┴──────────────────────────┐
│  z0r0 — Workstation / AI Agent         │                               │  luffy — Homelab / PKB Memory             │
│  Tailnet IP: 100.64.0.1                │                               │  Tailnet IP: 100.64.0.3                   │
│  DNS: z0r0.nfp.nix                     │                               │  DNS: luffy.nfp.nix                       │
│                                        │                               │                                           │
│  • Tailscale Client                    │                               │  • Tailscale Client                       │
│  • ExtremeRouter (127.0.0.1:20128 ONLY)│                               │  • Brain Service / Honcho / Qdrant        │
│  • Local Dev / Workstation Apps        │                               │  • Harmonia Cache / Matrix Homeserver     │
└────────────────────────────────────────┘                               └─────────────────────────────────────────┘
```

## Fleet Overlay Network Specification

- **Authoritative Control Plane: `luffy` (`luffy.nfp.nix`) running Headscale (`https://headscale.lovelain.duckdns.org` public bootstrap, `http://luffy.nfp.nix:8086` Tailnet).**
- **Client Overlay Daemon**: Standard `services.tailscale` clients targeting `--login-server=https://headscale.lovelain.duckdns.org` (bootstrap) then `nfp.nix` MagicDNS.
- **Domain & Addressing**: `*.nfp.nix` Tailnet MagicDNS within `100.64.0.0/10`; `*.lovelain.duckdns.org` public WAN/Caddy/ACME only.
- **Fleet Resolver**: AdGuard Home on `luffy` (`100.64.0.3:53` Tailnet, `192.168.1.54:53` LAN, `127.0.0.1:53` loopback) — WireGuard protects Tailnet transport, DoH/DoT protects upstream (quad9/cloudflare). `luffy` uses `127.0.0.1` + bootstrap `9.9.9.9` to avoid self-loop; others `--accept-dns=true`.
- **Polyfloor**: Tailnet-only `nami.nfp.nix:7777` (bind `0.0.0.0`, Headscale ACL `tag:control-plane` + firewall `trustedInterfaces tailscale0`), WAN `47.254.90.69:7777` blocked.
- **Decommissioned Overlays**: ZeroTier and Clan WireGuard have been fully decommissioned. Tailscale is the sole inter-node mesh.

## Node Inventory & Tailnet Mapping

| Node Name | Host Alias | Role / Purpose | Tailnet DNS | WAN / LAN IP | Open Ports (WAN) | Tailnet Allowed Flows |
|-----------|------------|----------------|-------------|--------------|------------------|-----------------------|
| `nami` | `nami` | Cloud Control Plane / Kong Gateway | `nami.nfp.nix` | `47.254.90.69` | 22 (SSH), 80 (HTTP), 443 (HTTPS) | Kong Gateway, Hermes, gno sync (Headscale on luffy) |
| `luffy` | `luffy` | Homelab Server / Headscale+AdGuard / PKB Memory | `luffy.nfp.nix` | `192.168.1.54` (LAN) | 22 (SSH LAN/WAN), 41641 (Tailscale UDP) | Headscale control, AdGuard resolver, Brain Service, Honcho, Qdrant |
| `z0r0` | `z0r0` | Workstation / Dev Laptop | `z0r0.nfp.nix` | `192.168.1.39` (LAN) | 22 (SSH LAN/WAN), 41641 (Tailscale UDP) | Tailnet client access; ExtremeRouter (127.0.0.1:20128 only) |

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

# 2. Check Headscale node list on luffy (authoritative control plane)
ssh root@luffy.nfp.nix "headscale nodes list"

# 3. Check client daemon status on z0r0 / luffy
tailscale status
tailscale dns status  # expect suffix nfp.nix, resolver 100.64.0.3 (AdGuard)

# 4. Verify inter-node endpoint reachability (Tailnet via nfp.nix, not lovelain)
curl -sf http://luffy.nfp.nix:8010/healthz   # Luffy Brain Service via Tailnet
curl -sf http://nami.nfp.nix:7777/healthz     # Nami Polyfloor via Tailnet (WAN 47.254.90.69:7777 blocked)
curl -sf http://nami.nfp.nix:8090/status     # Nami Kong Gateway via Tailnet
curl -sf http://127.0.0.1:20128/v1/models     # Z0r0 local ExtremeRouter (loopback only)
# AdGuard verification
dig @100.64.0.3 example.com +short            # via AdGuard Tailnet DoH
dig @100.64.0.3 doubleclick.net +short        # → 0.0.0.0 (blocked)
```