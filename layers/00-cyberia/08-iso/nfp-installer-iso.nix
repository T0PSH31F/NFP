# NFP Fleet Provisioning ISO — Zero-Touch Installer
#
# Purpose: Self-contained bootable installer for bootstrapping new NFP hosts
# into the Clan fleet with full Btrfs impermanence, SOPS/Age keys, and
# Headscale Tailnet enrollment.  Run `nfp-install-host` from the live session.
#
# Outputs: packages.x86_64-linux.installer-iso
#
# This is SEPARATE from the pentest live ISO (layers/00-cyberia/08-iso/noctalia-installer.nix).
{
  pkgs,
  lib,
  inputs,
  modulesPath,
  ...
}:

{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
    inputs.sops-nix.nixosModules.sops
    ../../10-system/11-foundation/fonts.nix
  ];

  # ── ISO metadata ────────────────────────────────────────────────────────
  image.fileName = "nfp-installer-${pkgs.stdenv.hostPlatform.system}.iso";
  isoImage = {
    volumeID = "NFP_FLEET_INSTALLER";
    squashfsCompression = "zstd -Xcompression-level 19";
    makeEfiBootable = true;
    makeUsbBootable = true;
  };

  # ── Boot & kernel ────────────────────────────────────────────────────────
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    zfs.forceImportRoot = false;
    supportedFilesystems = [
      "btrfs"
      "vfat"
      "ext4"
    ];
  };

  # ── Network ──────────────────────────────────────────────────────────────
  networking = {
    wireless.enable = lib.mkForce false;
    networkmanager.enable = true;
    hostName = "nfp-installer";
  };

  # ── Auto-login to installer user ─────────────────────────────────────────
  services.getty.autologinUser = "nixos";

  # ── Installer user ───────────────────────────────────────────────────────
  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "disk"
    ];
  };
  security.sudo.wheelNeedsPassword = false;

  # ── Core installer tooling ───────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # Disk management
    btrfs-progs
    parted
    gptfdisk
    cryptsetup
    lvm2
    util-linux

    # Age / SOPS key generation
    age
    sops
    ssh-to-age

    # Clan CLI — fleet enrollment & vars management
    inputs.clan-core.packages.${pkgs.stdenv.hostPlatform.system}.clan-cli

    # Network enrollment
    headscale
    tailscale

    # System tools
    git
    curl
    wget
    jq
    htop
    tmux
    vim
    neovim

    # NixOS install helpers
    nixos-install-tools
    nixos-anywhere

    # ── nfp-install-host wizard ──────────────────────────────────────────
    (pkgs.writeShellScriptBin "nfp-install-host" ''
      #!/usr/bin/env bash
      set -euo pipefail

      RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
      info()    { echo -e "''${BLUE}[NFP]''${NC} $*"; }
      success() { echo -e "''${GREEN}[OK ]''${NC} $*"; }
      warn()    { echo -e "''${YELLOW}[WRN]''${NC} $*"; }
      error()   { echo -e "''${RED}[ERR]''${NC} $*"; exit 1; }

      echo ""
      echo "╔══════════════════════════════════════════════════════════╗"
      echo "║        NFP FLEET PROVISIONING WIZARD                    ║"
      echo "║        Zero-Touch Host Bootstrap                        ║"
      echo "╚══════════════════════════════════════════════════════════╝"
      echo ""

      # ── Step 1: Gather host information ──────────────────────────────
      read -rp "New hostname (e.g. sanji, zoro2): " HOSTNAME
      [[ -z "$HOSTNAME" ]] && error "Hostname cannot be empty"

      read -rp "Target disk (e.g. /dev/nvme0n1, /dev/sda): " DISK
      [[ ! -b "$DISK" ]] && error "Device $DISK not found"

      read -rp "Enable LUKS encryption? [Y/n]: " ENCRYPT_CHOICE
      ENCRYPT=true
      [[ "$ENCRYPT_CHOICE" =~ ^[Nn]$ ]] && ENCRYPT=false

      if $ENCRYPT; then
        read -rsp "LUKS passphrase: " LUKS_PASS; echo
        read -rsp "Confirm LUKS passphrase: " LUKS_PASS2; echo
        [[ "$LUKS_PASS" != "$LUKS_PASS2" ]] && error "Passphrases do not match"
      fi

      read -rp "Headscale pre-auth key (leave blank to skip Tailnet enrollment): " HS_PREAUTH_KEY

      echo ""
      warn "=== SUMMARY ==="
      info  "Hostname : $HOSTNAME"
      info  "Disk     : $DISK"
      info  "Encrypt  : $ENCRYPT"
      info  "Tailnet  : $([ -n "$HS_PREAUTH_KEY" ] && echo YES || echo NO)"
      echo ""
      read -rp "Proceed? This will WIPE $DISK. [yes/NO]: " CONFIRM
      [[ "$CONFIRM" != "yes" ]] && error "Aborted by user"

      # ── Step 2: Partition ────────────────────────────────────────────
      info "Partitioning $DISK …"
      parted "$DISK" --script mklabel gpt
      parted "$DISK" --script mkpart ESP fat32 1MiB 512MiB
      parted "$DISK" --script set 1 esp on
      parted "$DISK" --script mkpart primary 512MiB 100%

      # Detect partition names (nvme uses p suffix)
      if [[ "$DISK" =~ nvme|mmcblk ]]; then
        BOOT_PART="''${DISK}p1"
        DATA_PART="''${DISK}p2"
      else
        BOOT_PART="''${DISK}1"
        DATA_PART="''${DISK}2"
      fi

      mkfs.vfat -F32 -n BOOT "$BOOT_PART"

      # ── Step 3: Encryption ───────────────────────────────────────────
      if $ENCRYPT; then
        info "Setting up LUKS on $DATA_PART …"
        echo -n "$LUKS_PASS" | cryptsetup luksFormat "$DATA_PART" -
        echo -n "$LUKS_PASS" | cryptsetup open "$DATA_PART" cryptroot -
        BTRFS_DEV=/dev/mapper/cryptroot
      else
        BTRFS_DEV="$DATA_PART"
      fi

      # ── Step 4: Btrfs impermanence subvolumes ────────────────────────
      info "Creating Btrfs impermanence subvolume layout …"
      mkfs.btrfs -L nixos "$BTRFS_DEV"
      mount "$BTRFS_DEV" /mnt

      btrfs subvolume create /mnt/@root
      btrfs subvolume create /mnt/@persist
      btrfs subvolume create /mnt/@nix
      btrfs subvolume create /mnt/@swap
      btrfs subvolume create /mnt/@log

      # Blank snapshot of @root for impermanence wipe-on-boot
      btrfs subvolume snapshot -r /mnt/@root /mnt/@root-blank

      umount /mnt

      # Mount subvolumes
      mount -o subvol=@root,compress=zstd,noatime "$BTRFS_DEV" /mnt
      mkdir -p /mnt/{boot,nix,persist,var/log,swap}
      mount -o subvol=@nix,compress=zstd,noatime "$BTRFS_DEV" /mnt/nix
      mount -o subvol=@persist,compress=zstd,noatime "$BTRFS_DEV" /mnt/persist
      mount -o subvol=@log,compress=zstd,noatime "$BTRFS_DEV" /mnt/var/log
      mount -o subvol=@swap,noatime "$BTRFS_DEV" /mnt/swap
      mount "$BOOT_PART" /mnt/boot

      success "Disk layout ready"

      # ── Step 5: Age / SOPS machine key generation ────────────────────
      info "Generating machine Age key …"
      mkdir -p /mnt/persist/etc/sops/age
      age-keygen -o /mnt/persist/etc/sops/age/machine.key
      AGE_PUBKEY=$(age-keygen -y /mnt/persist/etc/sops/age/machine.key)
      success "Age public key: $AGE_PUBKEY"

      # ── Step 6: Tailnet enrollment ───────────────────────────────────
      if [ -n "$HS_PREAUTH_KEY" ]; then
        info "Enrolling $HOSTNAME into Headscale Tailnet …"
        # tailscale up is run post-boot via a firstboot service, so we
        # just store the pre-auth key in persist for the activation script
        mkdir -p /mnt/persist/etc/nfp
        echo "$HS_PREAUTH_KEY" > /mnt/persist/etc/nfp/headscale-preauth-key
        chmod 600 /mnt/persist/etc/nfp/headscale-preauth-key
        success "Pre-auth key stored — Tailnet enrollment will complete on first boot"
      fi

      # ── Step 7: NixOS install ────────────────────────────────────────
      info "Installing NixOS from NFP flake …"
      info "(This will take several minutes; packages are pre-bundled in the ISO)"

      nixos-install \
        --no-root-password \
        --flake "github:T0PSH31F/NFP#$HOSTNAME" \
        --root /mnt

      success "NixOS installed!"

      # ── Step 8: Summary ──────────────────────────────────────────────
      echo ""
      echo "╔══════════════════════════════════════════════════════════╗"
      echo "║  INSTALLATION COMPLETE                                  ║"
      echo "╚══════════════════════════════════════════════════════════╝"
      echo ""
      success "Hostname    : $HOSTNAME"
      success "Age pubkey  : $AGE_PUBKEY"
      echo ""
      warn "NEXT STEPS:"
      echo "  1. Add the Age pubkey above to .sops.yaml in NFP (machines.$HOSTNAME)"
      echo "  2. Run: clan machines update $HOSTNAME (to provision vars/secrets)"
      echo "  3. Reboot the new machine"
      if [ -n "$HS_PREAUTH_KEY" ]; then
        echo "  4. Tailscale will auto-enroll on first boot"
      fi
      echo ""
      read -rp "Reboot now? [Y/n]: " REBOOT_CHOICE
      [[ ! "$REBOOT_CHOICE" =~ ^[Nn]$ ]] && reboot
    '')
  ];

  # ── Unfree ────────────────────────────────────────────────────────────────
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "25.05";
}
