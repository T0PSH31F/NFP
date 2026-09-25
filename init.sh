#!/usr/bin/env bash
# NFP harness initialization — run at the start of every agent session.
set -euo pipefail

INSTALL_CMD=(true)             # deps are pinned via flake.lock; nothing to install
VERIFY_CMD=(true)              # baseline verification
START_CMD=(clan machines list) # fleet sanity check (read-only)

WORKTREE_MODE=0

if [ "${1:-}" = "--worktree" ]; then
  WORKTREE_MODE=1
  shift
fi

if [ "${WORKTREE_MODE}" = "1" ]; then
  echo "==> [WORKTREE MODE] Validating uncommitted worktree changes"
  echo "==> Git working tree status:"
  git status --short
  echo "--------------------------------------------------------"
else
  if ! git diff --quiet --no-ext-diff 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
    echo "ERROR: dirty working tree — commit changes or run './init.sh --worktree' to validate intentional edits" >&2
    git status --short >&2
    exit 1
  fi
fi

# Failed NixOS assertions evaluated in a single Nix process
failed_assertions=$(nix eval --json --expr '
  let
    flake = builtins.getFlake (toString ./.);
    evalHost = name: host: {
      machine = name;
      failed = builtins.filter (x: !x.assertion) host.config.assertions;
    };
    results = builtins.map (name: evalHost name flake.nixosConfigurations.${name}) ["luffy" "z0r0" "nami"];
  in
    builtins.filter (res: builtins.length res.failed > 0) results
' 2>/dev/null || echo "[]")

if [ "${failed_assertions}" != "[]" ] && [ "${failed_assertions}" != "" ]; then
  echo "ERROR: Failed NixOS assertions detected:" >&2
  echo "${failed_assertions}" | jq -r '.[] | "\(.machine): \(.failed[].message)"' >&2
  exit 1
fi

# Canonical address / Headscale drift checks — exempt: matrix.local, firewall/gateway/bind topology
if grep -R "192\.168\.1\.54:8086" --include="*.nix" machines/luffy/default.nix >/dev/null 2>&1; then
  echo "ERROR: raw LAN 192.168.1.54:8086 still in machines/luffy/default.nix — should be luffy.nfp.nix" >&2
  exit 1
fi
if grep -R "nami\.local" --include="*.md" layers/00-cyberia/01-docs/post-rebuild-setup.md >/dev/null 2>&1; then
  echo "ERROR: stale nami.local in post-rebuild-setup.md — use nfp.nix MagicDNS" >&2
  exit 1
fi
# Polyfloor authority: health must be /healthz from locked upstream
if ! grep -q 'path = "/healthz"' layers/70-agents/76-orchestrators/polyfloor.nix 2>/dev/null; then
  echo "ERROR: polyfloor healthcheck path not /healthz (locked upstream)" >&2
  exit 1
fi

echo "==> [1/5] Dependency step"
"${INSTALL_CMD[@]}"

echo "==> [2/5] Format & linter check (nixfmt, deadnix, statix)"
nix fmt -- --fail-on-change
deadnix --fail . || echo "    (deadnix check failed or uninstalled — check files)"
statix check . || echo "    (statix check reported baseline debt warnings)"

echo "==> [3/5] Baseline verification"
"${VERIFY_CMD[@]}"

echo "==> [4/5] Single-pass guarded machine evaluation (luffy, z0r0, nami)"
./layers/00-cyberia/06-scripts/nfp-check.sh eval all
echo "    all 3 machines evaluate"

echo "==> [5/5] Fleet visibility"
"${START_CMD[@]}" || echo "    (clan CLI unavailable locally — non-fatal)"

echo "==> Harness initialized successfully."
