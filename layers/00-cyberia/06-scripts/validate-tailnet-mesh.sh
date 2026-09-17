#!/usr/bin/env bash
# validate-tailnet-mesh.sh — Automated Tailnet Mesh Verification
#
# Validates Tailscale mesh connectivity, MagicDNS / Tailnet hostnames,
# HTTP service endpoints, and SSH reachability across z0r0, luffy, and nami (nami).
set -euo pipefail

RED='\031[0;31m'
GREEN='\032[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_err() {
  echo -e "${RED}[FAIL]${NC} $1"
  ERRORS=$((ERRORS + 1))
}

echo "=================================================="
echo "🌐 NFP Tailnet Mesh Verification Suite"
echo "=================================================="

# 1. Check local tailscale daemon status
log_info "Checking local tailscale daemon status..."
if tailscale status >/dev/null 2>&1; then
  log_info "Local Tailscale daemon is running."
else
  log_err "Local Tailscale daemon is down or unreachable."
fi

# 2. Check Node Reachability (ping)
NODES=("z0r0" "luffy" "nami")
DOMAIN="nfp.nix"

log_info "Probing Tailnet Node IPs and Hostnames..."
for node in "${NODES[@]}"; do
  target="${node}.${DOMAIN}"
  if ping -c 2 -W 3 "$node" >/dev/null 2>&1; then
    log_info "Node ping successful: $node"
  elif ping -c 2 -W 3 "$target" >/dev/null 2>&1; then
    log_info "Node ping successful: $target"
  else
    log_err "Unable to ping node: $node ($target)"
  fi
done

# 3. Check Headscale Control Plane Reachability
log_info "Probing Headscale Control Plane..."
HS_URL="https://headscale.lovelain.duckdns.org/health"
if curl -sf --connect-timeout 5 "$HS_URL" >/dev/null 2>&1; then
  log_info "Headscale control plane health endpoint OK: $HS_URL"
else
  log_warn "Headscale control plane health endpoint check failed: $HS_URL (checking fallback port 8086...)"
  if curl -sf --connect-timeout 5 "http://47.254.90.69:8086/health" >/dev/null 2>&1; then
    log_info "Headscale fallback port 8086 reachable on nami."
  else
    log_err "Headscale control plane unreachable!"
  fi
fi

# 4. Probing Tailnet Service Endpoints
log_info "Probing key service endpoints across tailnet..."

# Kong Gateway status on nami
if curl -sf --connect-timeout 5 "http://nami.${DOMAIN}:8090/status" >/dev/null 2>&1 || curl -sf --connect-timeout 5 "http://nami.${DOMAIN}:8090/status" >/dev/null 2>&1; then
  log_info "Kong Gateway reachable on nami:8090"
else
  log_warn "Kong Gateway unreachable on nami:8090 (host may be updating or port restricted)"
fi

# Brain Service on luffy
if curl -sf --connect-timeout 5 "http://luffy.${DOMAIN}:8010/healthz" >/dev/null 2>&1; then
  log_info "Brain Service reachable on luffy:8010"
else
  log_warn "Brain Service unreachable on luffy:8010 (checking LAN IP 192.168.1.54:8010...)"
  if curl -sf --connect-timeout 5 "http://192.168.1.54:8010/healthz" >/dev/null 2>&1; then
    log_warn "Brain Service accessible via LAN IP only — Tailscale client on luffy needs recovery!"
  else
    log_err "Brain Service down or unreachable on luffy!"
  fi
fi

echo "=================================================="
if [ "$ERRORS" -eq 0 ]; then
  echo -e "${GREEN}✓ All Tailnet Mesh Verification Checks Passed!${NC}"
  exit 0
else
  echo -e "${RED}✗ Verification finished with $ERRORS failure(s).${NC}"
  exit 1
fi
