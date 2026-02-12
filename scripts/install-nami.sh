#!/usr/bin/env bash
# =============================================================================
# Nami NixOS Installation Script
# Partitions NVMe, creates BTRFS subvolumes, and runs nixos-install
# =============================================================================
set -euo pipefail

DISK="/dev/nvme0n1"
BOOT_SIZE="4G"         # 4GB boot partition as requested
SWAP_SIZE="16384"      # 16GB swap file (matches RAM)

echo "============================================"
echo "  Nami NixOS Installation"
echo "============================================"
echo ""
echo "Target disk: $DISK"
echo "Boot partition: ${BOOT_SIZE}"
echo ""
echo "WARNING: This will ERASE ALL DATA on $DISK"
echo "Press Ctrl+C to abort, or Enter to continue..."
read -r

# =============================================================================
# Step 1: Partition the disk
# =============================================================================
echo "[1/7] Wiping and partitioning $DISK..."

# Wipe existing partition table
wipefs -af "$DISK"
sgdisk --zap-all "$DISK"

# Create partitions:
# p1: 4GB EFI System Partition
# p2: Remaining space for BTRFS root
sgdisk -n 1:0:+${BOOT_SIZE} -t 1:ef00 -c 1:"NAMI_BOOT" "$DISK"
sgdisk -n 2:0:0 -t 2:8300 -c 2:"NAMI_ROOT" "$DISK"

# Wait for kernel to re-read partition table
partprobe "$DISK"
sleep 2

BOOT_PART="${DISK}p1"
ROOT_PART="${DISK}p2"

echo "  Boot: $BOOT_PART"
echo "  Root: $ROOT_PART"

# =============================================================================
# Step 2: Format partitions
# =============================================================================
echo "[2/7] Formatting partitions..."

# Format boot partition as FAT32
mkfs.fat -F 32 -n NAMI_BOOT "$BOOT_PART"

# Format root partition as BTRFS
mkfs.btrfs -f -L NAMI_ROOT "$ROOT_PART"

# =============================================================================
# Step 3: Create BTRFS subvolumes
# =============================================================================
echo "[3/7] Creating BTRFS subvolumes..."

mount "$ROOT_PART" /mnt

btrfs subvolume create /mnt/@root
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@log

umount /mnt

# =============================================================================
# Step 4: Mount subvolumes
# =============================================================================
echo "[4/7] Mounting subvolumes..."

MOUNT_OPTS="compress=zstd,noatime"

mount -o "subvol=@root,${MOUNT_OPTS}" "$ROOT_PART" /mnt

mkdir -p /mnt/{home,nix,var/log,boot}

mount -o "subvol=@home,${MOUNT_OPTS}" "$ROOT_PART" /mnt/home
mount -o "subvol=@nix,${MOUNT_OPTS}" "$ROOT_PART" /mnt/nix
mount -o "subvol=@log,${MOUNT_OPTS}" "$ROOT_PART" /mnt/var/log

mount "$BOOT_PART" /mnt/boot

echo "  Mounts:"
df -h /mnt /mnt/home /mnt/nix /mnt/var/log /mnt/boot

# =============================================================================
# Step 5: Generate hardware config with real UUIDs
# =============================================================================
echo "[5/7] Generating hardware config..."

# Get the repo path (where this script lives)
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

nixos-generate-config --root /mnt --show-hardware-config > /tmp/nami-hw-generated.nix

echo "  Generated hardware config saved to /tmp/nami-hw-generated.nix"
echo ""
echo "  IMPORTANT: The generated config contains the real UUIDs."
echo "  The hardware.nix in the repo uses labels (NAMI_ROOT, NAMI_BOOT)."
echo "  Labels are set by mkfs, so they should work as-is."
echo ""

# =============================================================================
# Step 6: Install NixOS
# =============================================================================
echo "[6/7] Running nixos-install..."
echo "  This will take a while (downloading packages)..."

nixos-install --flake "${REPO_DIR}#nami" --root /mnt --no-root-password

# =============================================================================
# Step 7: Done!
# =============================================================================
echo ""
echo "============================================"
echo "  Installation Complete!"
echo "============================================"
echo ""
echo "Next steps:"
echo "  1. Reboot: reboot"
echo "  2. Log in as t0psh31f with password: changeme123"
echo "  3. IMMEDIATELY change your password: passwd"
echo "  4. Change root password: sudo passwd root"
echo "  5. To recover z0r0 from this machine:"
echo "     nixos-rebuild switch --flake /path/to/NFP#z0r0 --target-host root@192.168.1.159"
echo ""
