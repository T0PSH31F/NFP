# Live ISO Configuration (The "Going-Merry" Blueprint)
#
# This template creates a bootable Live ISO with the Grandlix-Gang configuration.
# Use it for initial installations, system recovery, or showing off your setup.
#
# Build:
#   nix build .#packages.x86_64-linux.iso
#
# Burn to USB:
#   dd if=result/iso/Going-Merry.iso of=/dev/sdX bs=4M status=progress conv=fsync
#
{
  lib,
  pkgs,
  modulesPath,
  inputs,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")

    # Required external modules
    inputs.clan-core.nixosModules.clanCore
    inputs.sops-nix.nixosModules.sops

    # New flake-parts based system core
    ../../flake-parts/features/nixos
    ../../flake-parts/hardware
    ../../flake-parts/system
    ../../flake-parts/themes

    # Use specialized user config for ISO
    ../../flake-parts/users/t0psh31f.nix
  ];

  # Clan core settings for ISO
  clan.core.settings.directory = "/etc/clan";
  clan.core.settings.machine.name = "Going-Merry";
  clan.core.tags = [
    "desktop"
    "laptop"
  ];

  # Disable ZFS to avoid broken kernel package errors
  boot.supportedFilesystems = lib.mkForce [
    "btrfs"
    "exfat"
    "ext4"
    "ntfs"
    "vfat"
  ];

  networking.hostName = "Going-Merry";

  # ============================================================================
  # THEMES
  # ============================================================================
  themes.sddm-sel = {
    enable = true;
    variant = "shaders";
  };
  themes.plymouth-hellonavi.enable = true;

  # THEMES
  # ESSENTIAL INSTALLATION TOOLS
  # ============================================================================
  environment.systemPackages = with pkgs; [
    # ESSENTIAL INSTALLATION TOOLS
    calamares
    disko
    gparted
    hyprpolkitagent
    inputs.clan-core.packages.${pkgs.system}.clan-cli

    # Networking
    iwd
    toybox

    # Terminals
    ghostty
    kitty
  ];

  # ============================================================================
  # NETWORKING
  # ============================================================================
  networking.networkmanager = {
    enable = true;
    wifi.backend = "iwd";
  };
  networking.wireless.iwd.enable = true;
  networking.wireless.enable = lib.mkForce false;

  # ============================================================================
  # REPOSITORY INCLUSION
  # ============================================================================
  environment.etc."Grandlix-Gang".source = inputs.self;

  # ============================================================================
  # SSH FOR REMOTE INSTALLATION
  # ============================================================================
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  # ============================================================================
  # LIVE USER CONFIGURATION
  # ============================================================================
  users.users.nixos = {
    initialHashedPassword = lib.mkForce "$6$o5YE7K.oDW2Ow8iK$xxFnhKRYuM1EOaoQoyaV6VjsqkkVMf1hX/g9snl4nW1SjFFtREwmZljaOuU7H1IDsTueQIqcicGksJ34AO3Mj0";
  };
  users.users.root = {
    initialHashedPassword = lib.mkForce "$6$o5YE7K.oDW2Ow8iK$xxFnhKRYuM1EOaoQoyaV6VjsqkkVMf1hX/g9snl4nW1SjFFtREwmZljaOuU7H1IDsTueQIqcicGksJ34AO3Mj0";
  };

  # ISO IMAGE SETTINGS
  image.fileName = "Going-Merry";

  isoImage = {
    squashfsCompression = "zstd";
    makeEfiBootable = true;
    makeUsbBootable = true;
  };

  system.stateVersion = "25.05";
}
