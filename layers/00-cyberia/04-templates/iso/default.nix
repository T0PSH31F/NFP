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
    inputs.home-manager.nixosModules.home-manager
    # inputs.sops-nix.nixosModules.sops # Included in clanCore
    inputs.nixos-passthru-cache.nixosModules.nixos-passthru-cache

    # New flake-parts based system core
    ../../../10-system
    ../../../10-system/12-processor
    ../../../10-system/11-foundation
    ../../../30-environments
    ../../../10-system/13-users/t0psh31f.nix
    ../../../40-desktop
  ];

  # Clan core settings for ISO
  clan.core.settings.directory = "/etc/clan";
  clan.core.settings.machine.name = "Going-Merry";
  machine.tags = [
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
  layers.layer-30.theming.themes.greeter.type = "sddm";
  layers.layer-30.theming.themes.plymouth-hellonavi.enable = true;
  layers.layer-40.desktop.hyprland.enable = true;

  # THEMES
  # ESSENTIAL INSTALLATION TOOLS
  # ============================================================================
  environment.systemPackages = with pkgs; [
    # ESSENTIAL INSTALLATION TOOLS
    calamares
    disko
    gparted
    hyprpolkitagent
    inputs.clan-core.packages.${pkgs.stdenv.hostPlatform.system}.clan-cli

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
  # ============================================================================
  # NETWORKING
  # ============================================================================
  networking.networkmanager.enable = true;
  # networking.wireless.enable = lib.mkForce false; # Disabled by default in installation-cd-minimal

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
  # Enable auto-login for t0psh31f so the user lands in their custom environment
  services.displayManager.autoLogin.user = "t0psh31f";
  services.displayManager.defaultSession = lib.mkForce "hyprland-uwsm";

  users.users.nixos = {
    initialHashedPassword = lib.mkForce "$6$o5YE7K.oDW2Ow8iK$xxFnhKRYuM1EOaoQoyaV6VjsqkkVMf1hX/g9snl4nW1SjFFtREwmZljaOuU7H1IDsTueQIqcicGksJ34AO3Mj0";
  };
  users.users.root = {
    initialHashedPassword = lib.mkForce "$6$o5YE7K.oDW2Ow8iK$xxFnhKRYuM1EOaoQoyaV6VjsqkkVMf1hX/g9snl4nW1SjFFtREwmZljaOuU7H1IDsTueQIqcicGksJ34AO3Mj0";
  };

  # Ensure t0psh31f has sudo access without password in live ISO
  security.sudo.wheelNeedsPassword = false;

  # ISO IMAGE SETTINGS
  image.fileName = "Going-Merry";

  isoImage = {
    squashfsCompression = "zstd";
    makeEfiBootable = true;
    makeUsbBootable = true;
  };

  system.stateVersion = "25.05";
}
