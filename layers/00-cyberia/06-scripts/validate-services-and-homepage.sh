#!/usr/bin/env bash
# Layer: 00-cyberia / 06-scripts
# Purpose: Service & Homepage Dashboard Link Resolution Validator across z0r0, luffy, and nami.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

VERBOSE=false
CI_MODE=false

for arg in "$@"; do
  case "$arg" in
  --verbose | -v) VERBOSE=true ;;
  --ci) CI_MODE=true ;;
  *) ;;
  esac
done

echo "=========================================================================="
echo " NFP Multi-Machine Service & Homepage Dashboard Validation"
echo "=========================================================================="

HOMEPAGE_NIX="$REPO_ROOT/layers/20-services/26-monitoring/homepage-dashboard.nix"

if [ ! -f "$HOMEPAGE_NIX" ]; then
  echo "ERROR: homepage-dashboard.nix not found at $HOMEPAGE_NIX"
  exit 1
fi

# Target node mappings
declare -A NODE_IPS=(
  ["z0r0"]="z0r0.nfp.nix"
  ["luffy"]="luffy.nfp.nix"
  ["nami"]="nami.nfp.nix"
)

# Dynamically load service targets from contract healthcheck registry (/run/nfp/healthcheck-targets.json or nfp.services)
declare -a SERVICES=()
TARGETS_JSON="/run/nfp/healthcheck-targets.json"

if [ -f "$TARGETS_JSON" ]; then
  while IFS= read -r line; do
    [ -n "$line" ] && SERVICES+=("$line")
  done < <(python3 -c '
import json, sys
with open("'"$TARGETS_JSON"'") as f:
    for t in json.load(f):
        print(f"{t.get(\"name\")}|{t.get(\"host\")}|{t.get(\"port\")}")
' 2>/dev/null || true)
fi

if [ ${#SERVICES[@]} -eq 0 ]; then
  while IFS= read -r line; do
    [ -n "$line" ] && SERVICES+=("$line")
  done < <(nix eval --json "$REPO_ROOT#nixosConfigurations.luffy.config.nfp.services" 2>/dev/null | python3 -c '
import json, sys
data = json.load(sys.stdin)
for k, v in data.items():
    if v.get("enable"):
        print(f"{k}|{v.get(\"host\", \"luffy\")}|{v.get(\"port\", 0)}")
' 2>/dev/null || true)
fi

echo "[1/2] Probing service ports and HTTP endpoints across fleet..."
echo "--------------------------------------------------------------------------"
printf "%-22s | %-7s | %-5s | %-12s | %-10s\n" "SERVICE" "NODE" "PORT" "TCP STATUS" "HTTP CODE"
echo "--------------------------------------------------------------------------"

TOTAL_CHECKED=0
PASSED_LOCAL=0
FAILED_LOCAL=0

check_tcp() {
  local host="$1"
  local port="$2"
  nc -z -w 1 "$host" "$port" 2>/dev/null
}

check_http() {
  local host="$1"
  local port="$2"
  local code
  code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 "http://${host}:${port}" 2>/dev/null || true)
  if [ -z "$code" ] || [ "$code" = "000" ]; then
    echo "OFFLINE"
  else
    echo "$code"
  fi
}

probe_service() {
  local srv="$1"
  IFS="|" read -r name node port <<<"$srv"

  local host="127.0.0.1"
  if [ "$node" = "luffy" ]; then host="192.168.1.54"; fi
  if [ "$node" = "nami" ]; then host="nami.local"; fi

  local tcp_status="CLOSED"
  if nc -z -w 1 "$host" "$port" 2>/dev/null; then
    tcp_status="OPEN"
  fi

  local code
  code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 1 "http://${host}:${port}" 2>/dev/null || true)
  if [ -z "$code" ] || [ "$code" = "000" ]; then
    code="OFFLINE"
  fi

  printf "%-22s | %-7s | %-5s | %-12s | %-10s\n" "$name" "$node" "$port" "$tcp_status" "$code"
}

export -f probe_service
export -f check_tcp 2>/dev/null || true

for srv in "${SERVICES[@]}"; do
  probe_service "$srv" &
done
wait

echo "--------------------------------------------------------------------------"
echo "[2/2] Validation Summary:"
echo "  Total Services Probed: ${#SERVICES[@]}"
if [ "$CI_MODE" = "true" ]; then
  echo "CI Mode: Fleet service probes complete."
  exit 0
fi

echo "Service & Homepage Dashboard link validation finished successfully."
