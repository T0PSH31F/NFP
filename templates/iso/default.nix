# Live ISO Configuration
#
# Creates a bootable Live ISO with Grandlix-Gang configuration
# Useful for:
# - Installation media
# - Recovery systems
# - Demonstrations
#
# Build with: nix build .#packages.x86_64-linux.iso
{
  config,
  lib,
  pkgs,
  modulesPath,
  inputs,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")

    # Full Grandlix-Gang modules
    ../../modules/nixos/default.nix
    ../../modules/Desktop-env/default.nix

    # User-specific configuration (shell, home-manager, etc.)
    ../../modules/users/t0psh31f.nix

    # Laptop-specific optimizations
    ../../modules/nixos/system/laptop.nix
  ];

  # Disable ZFS to avoid broken kernel package errors
  boot.supportedFilesystems = lib.mkForce [
    "btrfs"
    "vfat"
    "exfat"
    "ext4"
    "ntfs"
  ];

  # ISO-specific settings
  networking.hostName = "grandlix-live";

  # ============================================================================
  # DESKTOP ENVIRONMENT - Dankmaterialshell with Hyprland
  # ============================================================================
  desktop.dankmaterialshell = {
    enable = true;
    backend = "hyprland";
  };

  # Disable other desktop environments
  desktop.omarchy.enable = false;
  desktop.caelestia.enable = false;
  desktop.illogical.enable = false;

  # ============================================================================
  # THEMES
  # ============================================================================
  # Match z0r0's premium theme setup
  themes.sddm-sel = {
    enable = true;
    variant = "shaders";
  };
  themes.sddm-lain.enable = lib.mkForce false;
  themes.plymouth-hellonavi.enable = true;

  # ============================================================================
  # RESOURCE LIMITS (Prevent OOM during install)
  # ============================================================================
  nix.settings.cores = 4;
  nix.settings.max-jobs = 4;

  # ============================================================================
  # ESSENTIAL INSTALLATION TOOLS
  # ============================================================================
  environment.systemPackages = with pkgs; [
    # Installers
    calamares
    gparted
    disko
    inputs.clan-core.packages.${pkgs.system}.clan-cli

    # Editors
    vim
    nano
    helix

    # Network tools
    networkmanager
    wpa_supplicant
    iwd
    wget
    curl
    dnsutils
    iw
    toybox
    
    # Utilities
    git
    htop
    tree
    lsd
    gotree
    hyprpolkitagent
    eza
    bat
    toybox
    ripgrep
    antigravity-fhs # User requested
    thunar # User requested
    thunar-volman
    thunar-archive-plugin

    # Disk tools
    parted
    ntfs3g
    exfatprogs
    btrfs-progs

    # Terminal
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
  networking.wireless.enable = lib.mkForce false; # Disable to use NetworkManager

  # ============================================================================
  # REPOSITORY INCLUSION
  # ============================================================================
  # Include a clean copy of the configuration repository
  environment.etc."Grandlix-Gang".source = inputs.self;

  # ============================================================================
  # SSH FOR REMOTE INSTALLATION
  # ============================================================================
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  services-config.avahi.enable = true;
  services.llm-agents.enable = true;

  # Internet fixes for Dell laptops
  services.resolved.dnssec = "false";
  boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
  boot.blacklistedKernelModules = [
    "b43"
    "bcma"
    "brcmsmac"
    "ssb"
  ];


  # ============================================================================
  # LIVE USER CONFIGURATION
  # ============================================================================
  # Set a default password for live user and root for fallback convenience
  users.users.nixos = {
    initialHashedPassword = lib.mkForce "$6$o5YE7K.oDW2Ow8iK$xxFnhKRYuM1EOaoQoyaV6VjsqkkVMf1hX/g9snl4nW1SjFFtREwmZljaOuU7H1IDsTueQIqcicGksJ34AO3Mj0";
  };
  users.users.root = {
    initialHashedPassword = lib.mkForce "$6$o5YE7K.oDW2Ow8iK$xxFnhKRYuM1EOaoQoyaV6VjsqkkVMf1hX/g9snl4nW1SjFFtREwmZljaOuU7H1IDsTueQIqcicGksJ34AO3Mj0";
  };

  # ============================================================================
  # ISO IMAGE SETTINGS
  # ============================================================================
  isoImage = {
    squashfsCompression = "zstd";
    makeEfiBootable = true;
    makeUsbBootable = true;
  };

  system.stateVersion = "25.05";
}
