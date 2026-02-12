#!/usr/bin/env bash
# =============================================================================
# Nami NixOS Installation Script (Disko-based)
# Uses the disko config at machines/nami/disko.nix for declarative partitioning
# =============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "============================================"
echo "  Nami NixOS Installation (Disko)"
echo "============================================"
echo ""
echo "This will use disko to partition /dev/nvme0n1:"
echo "  - 4GB EFI boot"
echo "  - 16GB LUKS-encrypted swap"
echo "  - Remaining: LUKS-encrypted BTRFS"
echo "    Subvolumes: @root @home @nix @persist @backup @log"
echo ""
echo "WARNING: This will ERASE ALL DATA on /dev/nvme0n1"
echo "Press Ctrl+C to abort, or Enter to continue..."
read -r

# =============================================================================
# Step 1: Set LUKS password
# =============================================================================
echo "[1/4] Setting LUKS encryption password..."
echo ""
echo "Enter the LUKS disk encryption password:"
read -rs LUKS_PASS
echo ""
echo "Confirm password:"
read -rs LUKS_PASS_CONFIRM
echo ""

if [ "$LUKS_PASS" != "$LUKS_PASS_CONFIRM" ]; then
    echo "ERROR: Passwords don't match!"
    exit 1
fi

echo -n "$LUKS_PASS" > /tmp/secret.key
chmod 600 /tmp/secret.key

# =============================================================================
# Step 2: Run disko to partition and format
# =============================================================================
echo "[2/4] Running disko to partition and format..."
nix run github:nix-community/disko -- --mode disko "${REPO_DIR}/machines/nami/disko.nix"

# =============================================================================
# Step 3: Install NixOS
# =============================================================================
echo "[3/4] Running nixos-install..."
echo "  This will take a while (downloading packages)..."
nixos-install --flake "${REPO_DIR}#nami" --root /mnt --no-root-password

# =============================================================================
# Step 4: Cleanup and done
# =============================================================================
rm -f /tmp/secret.key

echo ""
echo "============================================"
echo "  Installation Complete!"
echo "============================================"
echo ""
echo "Next steps:"
echo "  1. Reboot: reboot"
echo "  2. Enter LUKS password at boot"
echo "  3. Log in as t0psh31f with password: changeme123"
echo "  4. IMMEDIATELY change your password: passwd"
echo "  5. Change root password: sudo passwd root"
echo ""
