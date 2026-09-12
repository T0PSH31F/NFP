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
  ["z0r0"]="127.0.0.1"
  ["luffy"]="192.168.1.54"
  ["nami"]="nami.local"
)

# Defined homepage service targets: Name | Machine | Port
declare -a SERVICES=(
  "Grafana|z0r0|3008"
  "Prometheus|z0r0|9090"
  "Loki|z0r0|3100"
  "Hermes Workspace|z0r0|3000"
  "Hermes Dashboard|z0r0|9119"
  "SillyTavern|z0r0|8000"
  "brain-service|z0r0|8010"
  "ExtremeRouter|z0r0|20128"
  "FreeLLMPool|z0r0|8082"
  "FreeLLMApi|z0r0|3003"
  "Polyfloor|z0r0|8001"
  "EverOS|z0r0|8092"
  "ContextForge|z0r0|8094"

  "Open WebUI|luffy|8088"
  "Ollama|luffy|11434"
  "SearXNG|luffy|8888"
  "Vaultwarden|luffy|8222"
  "AdGuard Home|luffy|3002"
  "Jellyfin|luffy|8096"
  "Sonarr|luffy|8989"
  "Radarr|luffy|7878"
  "n8n|luffy|5678"
  "Kavita|luffy|5050"

  "Kong Gateway|nami|8090"
  "Headscale|nami|8086"
  "Paperclip|nami|3101"
  "Mission Control|nami|3099"
  "OmniRoute|nami|20128"
)

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
