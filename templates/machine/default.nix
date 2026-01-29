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
  # FEATURE TOGGLES (Dendritic Pattern - Nested Attrsets)
  # ============================================================================

  config = {
    # Desktop environments (choose one or enable multiple)
    desktop = {
      dankmaterialshell = {
        enable = true;
        backend = "hyprland"; # "hyprland", "niri", or "both"
      };
      omarchy = {
        enable = false;
        backend = "hyprland";
      };
      caelestia = {
        enable = false;
        backend = "hyprland";
      };
      noctalia = {
        enable = false;
        backend = "hyprland";
      };
      illogical-impulse.enable = false; # End-4 Hyprland config
    };

    # Programs
    programs = {
      yazelix.enable = false; # Yazi + Helix integration
      keybind-cheatsheet.enable = false; # Super+B keybind overlay
      pentest.enable = false; # Penetration testing tools
    };

    # Themes
    themes = {
      sddm-lain.enable = false;
      sddm-sel.enable = false;
      grub-lain.enable = false;
      plymouth-matrix.enable = false;
      plymouth-hellonavi.enable = false;
    };

    # Mobile device support
    mobile = {
      android.enable = false;
      ios.enable = false;
    };

    # System tools
    nix-tools.enable = false; # Nix development tools
    desktop-portals.enable = false; # XDG desktop portals
    
    # Gaming & Virtualization
    gaming.enable = false; # Master toggle for all gaming features
    virtualization.enable = false; # Docker, Podman, QEMU/KVM
    
    # Flatpak & AppImage
    flatpak.enable = false;
    programs.appimage-support.enable = false;
  };

  # ============================================================================
  # SERVICE TOGGLES (Dendritic Pattern - Nested Attrsets)
  # ============================================================================

  services = {
    # Desktop services
    ssh-agent.enable = false;

    # AI & LLM
    llm-agents.enable = false;

    # Infrastructure
    home-assistant-server.enable = false;
    caddy-server.enable = false;
    sillytavern-app.enable = false;

    # AI Services
    ai-services = {
      enable = false; # Enables PostgreSQL vector DB
      # open-webui.enable = false;
      # localai.enable = false;
      # chromadb.enable = false;
    };

    # Media & Cloud
    immich-server.enable = false;
    calibre-web-app.enable = false;
    nextcloud-server.enable = false;

    # Communication
    matrix-server.enable = false;
    mautrix-bridges.enable = false;
  };

  # Services config (separate namespace)
  services-config = {
    media-stack.enable = false;
    avahi.enable =e;
    monitoring.enable = false;
  };

  # ============================================================================
  # ADDITIONAL FEATURES
  # ============================================================================

  # services.flatpak.enable = false;
  # programs.appimage.enable = false;
}
