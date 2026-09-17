#!/usr/bin/env bash
# NFP harness initialization — run at the start of every agent session.
# Edit the three command arrays only if the repo's verification path changes.
set -euo pipefail

INSTALL_CMD=(true)             # deps are pinned via flake.lock; nothing to install
VERIFY_CMD=(true)              # baseline verification (fast eval in step 4)
START_CMD=(clan machines list) # fleet sanity check (read-only)

# Hermes pre-deploy guard: dirty tree, failed assertions, flake, drift, eval
# Bypass with ALLOW_DIRTY=1 for emergency hotfix only
if [ '${ALLOW_DIRTY:-0}' != "1" ] && ! git diff --quiet --no-ext-diff 2>/dev/null; then
  echo "ERROR: dirty working tree — commit or stash before deploy" >&2
  git status --porcelain >&2
  exit 1
fi
# Failed NixOS assertions (zero output required)
for m in luffy z0r0 nami; do
  count=$(nix eval --json ".#nixosConfigurations.$m.config.assertions" --apply 'xs: builtins.filter (x: !x.assertion) xs' 2>/dev/null | jq 'length')
  if [ "$count" != "0" ]; then
    echo "ERROR: $m has $count failed assertions" >&2
    nix eval --json ".#nixosConfigurations.$m.config.assertions" --apply 'xs: builtins.filter (x: !x.assertion) xs' 2>/dev/null | jq -r '.[] | .message' >&2
    exit 1
  fi
done
# Canonical address / Headscale drift (raw LAN IPs, .local, bare hostnames, Tailnet IPs) — exempt: matrix.local, firewall/gateway/bind topology
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
statix check . || echo "    (statix check failed or uninstalled — check files)"

echo "==> [3/5] Baseline verification"
"${VERIFY_CMD[@]}"

echo "==> [4/5] Machine evaluation (luffy, z0r0, nami)"
nix eval --raw .#nixosConfigurations.luffy.config.system.build.toplevel.drvPath >/dev/null
nix eval --raw .#nixosConfigurations.z0r0.config.system.build.toplevel.drvPath >/dev/null
nix eval --raw .#nixosConfigurations.nami.config.system.build.toplevel.drvPath >/dev/null
echo "    all 3 machines evaluate"

echo "==> [5/5] Fleet visibility"
"${START_CMD[@]}" || echo "    (clan CLI unavailable locally — non-fatal)"

echo "==> Harness initialized. Read agent-progress.md and feature_list.json next."
