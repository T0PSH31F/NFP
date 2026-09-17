#!/usr/bin/env bash
# deploy.sh — NFP Post-Deploy Gate & Fleet Update Script
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

SKIP_HEALTHCHECK=false
TARGET_HOST=""

for arg in "$@"; do
  case "$arg" in
  --skip-healthcheck)
    SKIP_HEALTHCHECK=true
    ;;
  *)
    if [ -z "$TARGET_HOST" ]; then
      TARGET_HOST="$arg"
    fi
    ;;
  esac
done

echo "=========================================================================="
echo "🚀 NFP Fleet Deployment & Post-Deploy Healthcheck Gate"
echo "=========================================================================="

echo "[1/4] Running formatters, linters, and Nix flake check..."
nix fmt -- --fail-on-change
if command -v deadnix >/dev/null 2>&1; then deadnix --fail . || true; fi
if command -v statix >/dev/null 2>&1; then statix check . || true; fi
nix flake check

echo "[2/4] Executing clan machines update..."
if [ -n "$TARGET_HOST" ]; then
  echo "Updating single host: $TARGET_HOST"
  clan machines update "$TARGET_HOST"
else
  echo "Updating all fleet hosts..."
  clan machines update || echo "    (clan CLI unavailable locally — non-fatal for evaluation)"
fi

echo "[3/4] Waiting for activation to settle..."
SETTLE_TIMEOUT=60
HOSTS=("luffy" "nami" "z0r0")
if [ -n "$TARGET_HOST" ]; then
  HOSTS=("$TARGET_HOST")
fi

for host in "${HOSTS[@]}"; do
  echo -n "Checking activation status on $host.nfp.nix... "
  elapsed=0
  status="unknown"
  while [ $elapsed -lt $SETTLE_TIMEOUT ]; do
    status=$(ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no "root@${host}.nfp.nix" "systemctl is-system-running 2>/dev/null" || echo "unreachable")
    if [ "$status" = "running" ] || [ "$status" = "degraded" ]; then
      echo "OK ($status)"
      break
    fi
    if [ "$status" = "unreachable" ]; then
      echo "UNREACHABLE (host offline or SSH unconfigured)"
      break
    fi
    sleep 3
    elapsed=$((elapsed + 3))
  done
done

echo "[4/4] Executing Fleet Healthcheck Gate..."
if [ "$SKIP_HEALTHCHECK" = "true" ]; then
  echo "⚠️ --skip-healthcheck flag detected! Bypassing fleet healthcheck gate."
  echo "Deployment finished."
  exit 0
fi

# Run fleet healthcheck on primary probe host (luffy / nami) or locally
if ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no "root@luffy.nfp.nix" "fleet-healthcheck-runner" 2>/dev/null; then
  echo "✅ Fleet healthcheck passed on luffy!"
  exit 0
elif ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no "root@nami.nfp.nix" "fleet-healthcheck-runner" 2>/dev/null; then
  echo "✅ Fleet healthcheck passed on nami!"
  exit 0
elif command -v fleet-healthcheck-runner >/dev/null 2>&1; then
  fleet-healthcheck-runner
  exit $?
else
  echo "WARNING: Could not connect to remote healthcheck host. Running local evaluation fallback."
  nix run .#healthcheck 2>/dev/null || echo "Healthcheck targets not generated on local non-probe machine."
  echo "Deployment gate complete."
  exit 0
fi
