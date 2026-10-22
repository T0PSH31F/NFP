#!/usr/bin/env bash
# nfp-doctor — Comprehensive System Health, Hardware/Firmware & Mesh Diagnostics
#
# Usage:
#   nfp-doctor [--all | --hardware | --mesh | --firmware]
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

pass() {
  echo -e "  ${GREEN}✓ PASS:${NC} $*"
  PASS_COUNT=$((PASS_COUNT + 1))
}
warn() {
  echo -e "  ${YELLOW}⚠ WARN:${NC} $*"
  WARN_COUNT=$((WARN_COUNT + 1))
}
fail() {
  echo -e "  ${RED}✗ FAIL:${NC} $*"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}
info() { echo -e "  ${BLUE}ℹ INFO:${NC} $*"; }
header() {
  echo ""
  echo -e "${BOLD}${CYAN}=== $* ===${NC}"
  echo "------------------------------------------------------------------"
}

MODE="all"
while [ $# -gt 0 ]; do
  case "$1" in
  --all)
    MODE="all"
    shift
    ;;
  --hardware)
    MODE="hardware"
    shift
    ;;
  --firmware)
    MODE="firmware"
    shift
    ;;
  --mesh)
    MODE="mesh"
    shift
    ;;
  -h | --help)
    echo "Usage: nfp-doctor [--all | --hardware | --mesh | --firmware]"
    exit 0
    ;;
  *)
    echo "Unknown option: $1" >&2
    exit 1
    ;;
  esac
done

echo ""
echo -e "${BOLD}🩺 NFP Fleet Doctor — System, Hardware & Mesh Diagnostics${NC}"
echo -e "Host: ${BOLD}$(hostname)${NC} | Date: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo "=================================================================="

# ──────────────────────────────────────────────────────────────────
# PASS 1: Hardware & Firmware Optimization Audit
# ──────────────────────────────────────────────────────────────────
run_hardware_firmware() {
  header "1. Hardware & Firmware Optimization Audit"

  # CPU Governor Check
  if [ -d /sys/devices/system/cpu/cpu0/cpufreq ]; then
    GOV=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "unknown")
    if [[ $GOV =~ ^(performance|schedutil)$ ]]; then
      pass "CPU governor: $GOV (optimized)"
    else
      warn "CPU governor: $GOV (recommend 'performance' or 'schedutil')"
    fi
  else
    info "CPU scaling governor interface not exposed (virtualized/containerized)"
  fi

  # Microcode Loading
  CPU_VENDOR=$(grep -m1 "vendor_id" /proc/cpuinfo 2>/dev/null | awk '{print $3}' || echo "unknown")
  UCODE=$(grep -m1 "microcode" /proc/cpuinfo 2>/dev/null | awk '{print $3}' || echo "unknown")
  if [ "$UCODE" != "unknown" ]; then
    pass "CPU microcode loaded ($CPU_VENDOR, revision $UCODE)"
  else
    warn "CPU microcode revision could not be determined"
  fi

  # Thermal Throttling
  THROTTLED=0
  for core in /sys/devices/system/cpu/cpu*/thermal_throttle/core_throttle_count; do
    if [ -f "$core" ]; then
      CNT=$(cat "$core" 2>/dev/null || echo "0")
      if [ "$CNT" -gt 0 ]; then
        THROTTLED=$((THROTTLED + CNT))
      fi
    fi
  done
  if [ "$THROTTLED" -eq 0 ]; then
    pass "Thermal throttling: 0 events detected"
  else
    warn "Thermal throttling detected: $THROTTLED throttling event(s)"
  fi

  # GPU Acceleration
  if [ -d /dev/dri ]; then
    RENDERS=$(ls -1 /dev/dri/renderD* 2>/dev/null | wc -l || echo "0")
    if [ "$RENDERS" -gt 0 ]; then
      pass "GPU DRM render nodes active: $RENDERS node(s) (/dev/dri)"
    else
      warn "No DRM render nodes found under /dev/dri"
    fi
  else
    info "No /dev/dri directory (headless or GPU passthrough)"
  fi

  # SSD TRIM Timers
  if systemctl is-active --quiet fstrim.timer 2>/dev/null; then
    pass "SSD fstrim.timer is active"
  elif systemctl is-enabled --quiet fstrim.timer 2>/dev/null; then
    warn "fstrim.timer is enabled but inactive"
  else
    warn "fstrim.timer is not enabled or active"
  fi

  # Btrfs Device Health & Error Counters
  if command -v btrfs >/dev/null 2>&1; then
    BTRFS_ERRORS=0
    for mountpt in "/" "/persist"; do
      if findmnt -n -o FSTYPE "$mountpt" 2>/dev/null | grep -q "btrfs"; then
        STATS=$(btrfs device stats "$mountpt" 2>/dev/null || true)
        ERRS=$(echo "$STATS" | awk '$2 > 0 {print $1, $2}' | grep -v "0$" || true)
        if [ -z "$ERRS" ]; then
          pass "Btrfs error counters clean on $mountpt (0 read/write/corruption errors)"
        else
          fail "Btrfs device errors on $mountpt: $ERRS"
          BTRFS_ERRORS=$((BTRFS_ERRORS + 1))
        fi
      fi
    done
  else
    info "btrfs command not present"
  fi

  # Battery Health (for mobile / laptop hosts)
  BATS=(/sys/class/power_supply/BAT*)
  if [ -e "${BATS[0]}" ]; then
    for bat in "${BATS[@]}"; do
      [ -d "$bat" ] || continue
      BNAME=$(basename "$bat")
      CAP=$(cat "$bat/capacity" 2>/dev/null || echo "unknown")
      STATUS=$(cat "$bat/status" 2>/dev/null || echo "unknown")
      FULL=$(cat "$bat/energy_full" 2>/dev/null || cat "$bat/charge_full" 2>/dev/null || echo "0")
      DESIGN=$(cat "$bat/energy_full_design" 2>/dev/null || cat "$bat/charge_full_design" 2>/dev/null || echo "0")

      if [ "$FULL" -gt 0 ] && [ "$DESIGN" -gt 0 ]; then
        HEALTH=$((FULL * 100 / DESIGN))
        if [ "$HEALTH" -ge 80 ]; then
          pass "Battery $BNAME health: ${HEALTH}% (charge: ${CAP}%, status: $STATUS)"
        else
          warn "Battery $BNAME health degraded: ${HEALTH}% (charge: ${CAP}%, status: $STATUS)"
        fi
      else
        info "Battery $BNAME present (charge: ${CAP}%, status: $STATUS)"
      fi
    done
  else
    info "No battery present (desktop or server host)"
  fi
}

# ──────────────────────────────────────────────────────────────────
# PASS 2: Inter-Node Mesh Reachability & Latency Matrix
# ──────────────────────────────────────────────────────────────────
run_mesh() {
  header "2. Inter-Node Mesh Reachability & Latency Matrix"

  FLEET_NODES=("z0r0" "luffy" "sanji")
  DOMAIN="nfp.nix"
  CURRENT_HOST=$(hostname)

  # 1. Local Tailscale Status
  if ! command -v tailscale >/dev/null 2>&1; then
    fail "Tailscale CLI is not installed"
    return
  fi

  if ! tailscale status >/dev/null 2>&1; then
    fail "Tailscale daemon is not active or not authenticated"
    return
  else
    pass "Local Tailscale daemon is connected"
  fi

  # 2. Ping & Latency Matrix across Nodes
  echo ""
  info "Probing Fleet Nodes over Tailnet (*.${DOMAIN}):"
  for node in "${FLEET_NODES[@]}"; do
    if [ "$node" = "$CURRENT_HOST" ]; then
      info "Node ${node} is local host (skipping self-ping)"
      continue
    fi

    TARGET="${node}.${DOMAIN}"
    PING_OUT=$(ping -c 3 -W 2 "$TARGET" 2>&1 || true)
    if echo "$PING_OUT" | grep -q "bytes from"; then
      AVG_LATENCY=$(echo "$PING_OUT" | tail -1 | awk -F '/' '{print $5}' 2>/dev/null || echo "unknown")
      pass "Node ${node} (${TARGET}) reachable — avg RTT: ${AVG_LATENCY} ms"
    else
      warn "Node ${node} (${TARGET}) ping failed (host offline or ICMP dropped)"
    fi
  done

  # 3. Direct WireGuard vs DERP Relay Verification
  echo ""
  info "Tailscale Path Analysis (Direct WireGuard vs DERP Relay):"
  TS_STATUS=$(tailscale status 2>/dev/null || true)
  for node in "${FLEET_NODES[@]}"; do
    if [ "$node" = "$CURRENT_HOST" ]; then continue; fi
    NODE_LINE=$(echo "$TS_STATUS" | grep -E "\b${node}\b" || true)
    if [ -n "$NODE_LINE" ]; then
      if echo "$NODE_LINE" | grep -q "direct"; then
        pass "Connection to ${node}: Direct WireGuard (p2p)"
      elif echo "$NODE_LINE" | grep -q "relay"; then
        DERP=$(echo "$NODE_LINE" | grep -o 'relay "[^"]*"' || echo "relay")
        warn "Connection to ${node}: DERP fallback (${DERP}) — peer is not direct"
      else
        info "Connection to ${node}: active (${NODE_LINE})"
      fi
    else
      warn "Node ${node} not found in Tailscale peer table"
    fi
  done

  # 4. Fleet Service Reachability Matrix
  echo ""
  info "Probing Fleet Service Matrix:"
  SERVICES=(
    "luffy:8010:Brain-Service:/docs"
    "luffy:3008:Grafana:/api/health"
    "luffy:9090:Prometheus:/-/healthy"
    "luffy:3100:Loki:/ready"
    "sanji:8090:Kong-Gateway:/status"
    "sanji:3050:Headplane:/"
    "z0r0:4318:OpenTelemetry-Collector:/"
  )

  for entry in "${SERVICES[@]}"; do
    IFS=":" read -r shost sport sname spath <<<"$entry"
    URL="http://${shost}.${DOMAIN}:${sport}${spath}"
    CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 "$URL" 2>/dev/null) || CODE="000"
    if [[ $CODE =~ ^(200|204|301|302|404|401)$ ]]; then
      pass "${sname} on ${shost}:${sport} responded with HTTP ${CODE}"
    else
      warn "${sname} on ${shost}:${sport} (${URL}) unreachable (code: ${CODE})"
    fi
  done
}

# ──────────────────────────────────────────────────────────────────
# Execution Router
# ──────────────────────────────────────────────────────────────────
case "$MODE" in
all)
  run_hardware_firmware
  run_mesh
  ;;
hardware | firmware)
  run_hardware_firmware
  ;;
mesh)
  run_mesh
  ;;
esac

header "Summary"
echo -e "  Passed Checks:   ${GREEN}${PASS_COUNT}${NC}"
echo -e "  Warnings:        ${YELLOW}${WARN_COUNT}${NC}"
echo -e "  Failed Checks:   ${RED}${FAIL_COUNT}${NC}"
echo "=================================================================="

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo -e "${GREEN}${BOLD}🎉 DOCTOR AUDIT: HEALTHY${NC}"
  exit 0
else
  echo -e "${RED}${BOLD}⚠ DOCTOR AUDIT: ISSUES DETECTED (${FAIL_COUNT} failures)${NC}"
  exit 1
fi
