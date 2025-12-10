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
}: {
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")

    # Full Grandlix-Gang modules
    ../../modules/nixos/default.nix
    ../../modules/Desktop-env/default.nix
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
  themes.sddm-lain.enable = true;
  # themes.grub-lain.enable = true; # Not needed for ISO (uses isolinux/EFI)
  # themes.plymouth-matrix.enable = true;

  # ============================================================================
  # ESSENTIAL INSTALLATION TOOLS
  # ============================================================================
  environment.systemPackages = with pkgs; [
    # Installers
    calamares
    gparted

    # Editors
    vim
    nano
    helix

    # Network tools
    networkmanager
    wget
    curl

    # Utilities
    git
    htop
    tree
    eza
    bat
    ripgrep

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
  networking.networkmanager.enable = true;
  networking.wireless.enable = false; # Disable to use NetworkManager

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
  # Set a default password for live user (hashed password: 5677)
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
