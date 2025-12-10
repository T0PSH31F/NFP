# Machine Template - Copy this directory to create new machines
#
# Usage:
#   1. Copy this template directory: cp -r templates/machine machines/newmachine
#   2. Edit machines/newmachine/default.nix with your settings
#   3. Generate hardware config: nixos-generate-config --root /mnt --show-hardware-config > machines/newmachine/hardware-configuration.nix
#   4. Add to clan.nix inventory and machines sections
#   5. Build and deploy!
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/default.nix
    ../../modules/Desktop-env/default.nix
    ../../modules/users/t0psh31f.nix # Change to your user
  ];

  # ============================================================================
  # BASIC CONFIGURATION
  # ============================================================================

  networking.hostName = "CHANGEME"; # Set your hostname

  system.stateVersion = "25.05"; # Don't change after initial install

  # ============================================================================
  # DESKTOP ENVIRONMENT (Choose one or enable multiple)
  # ============================================================================

  desktop.dankmaterialshell = {
    enable = false;
    backend = "both"; # "hyprland", "niri", or "both"
  };

  desktop.omarchy = {
    enable = false;
    backend = "both";
  };

  desktop.caelestia = {
    enable = false;
    backend = "both";
  };

  desktop.illogical.enable = false; # End-4 Hyprland config

  # ============================================================================
  # THEMES
  # ============================================================================

  themes.sddm-lain.enable = false;
  themes.grub-lain.enable = false;
  themes.plymouth-matrix.enable = false;
  themes.plymouth-hellonavi.enable = false;

  # ============================================================================
  # GAMING
  # ============================================================================

  gaming.enable = false; # Master toggle for all gaming features

  # ============================================================================
  # VIRTUALIZATION
  # ============================================================================

  virtualization.enable = false; # Docker, Podman, QEMU/KVM

  # ============================================================================
  # ADDITIONAL FEATURES
  # ============================================================================

  # services.flatpak.enable = false;
  # programs.appimage.enable = false;
}
