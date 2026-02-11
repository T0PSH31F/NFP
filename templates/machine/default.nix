# Machine Template - Copy this directory to create new machines
#
# Usage:
#   1. Copy this template directory: cp -r templates/machine machines/newmachine
#   2. Edit machines/newmachine/default.nix with your settings
#   3. Generate hardware config: nixos-generate-config --root /mnt --show-hardware-config > machines/newmachine/hardware-configuration.nix
#   4. Add to clan.nix inventory and machines sections
#   5. Build and deploy! (clan machines update newmachine)

{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix

    # Core system setup (includes basic packages, networking, etc.)
    ../../flake-parts/system

    # Feature toggles (Dendritic Pattern)
    ../../flake-parts/features/nixos

    # Theming system
    ../../flake-parts/themes
  ];

  # ============================================================================
  # CLAN INVENTORY & TAGS
  # ============================================================================
  # Tags control automatic feature activation and role assignment in clan-inventory.nix
  clan.core.tags = [
    # "desktop"      # Enables Hyprland, GUI apps, fonts
    # "laptop"       # Enables power management, touchpad, wifi
    # "server"       # Headless server optimizations
    # "ai-server"    # Enables Ollama and AI tools
    # "media-server" # Enables Arr suite and media tools
    # "dev"          # Enables compilers and dev tools
    # "gaming"       # Enables Steam and emulators
    # "nvidia"       # Enables Nvidia drivers (hardware/nvidia.nix required)
    # "amd"          # Enables AMD optimizations
  ];

  # ============================================================================
  # BASIC MACHINE SETTINGS
  # ============================================================================

  networking.hostName = "CHANGEME"; # Set your hostname here for local files
  system.stateVersion = "25.05"; # Don't change after initial install

  # ============================================================================
  # NIXOS FEATURE TOGGLES
  # ============================================================================

  # Impermanence (Ephemeral Root)
  system-config.impermanence = {
    enable = false;
    persistPath = "/persist";
  };

  # Gaming support
  gaming = {
    enable = false;
    enableSteam = true;
    enableGamemode = true;
    enableEmulators = false;
  };

  # Virtualization (QEMU, Docker, Podman)
  virtualization.enable = false;

  # Flatpak
  flatpak = {
    enable = false;
    # packages = [ "com.discordapp.Discord" ];
  };

  # AppImage support
  programs.appimage-support.enable = false;

  # Mobile Device Support
  mobile = {
    android.enable = false;
    ios.enable = false;
  };

  # ============================================================================
  # SERVICE TOGGLES
  # ============================================================================

  # AI Services (Comprehensive Suite)
  services.ai-services = {
    enable = false;
    ollama.enable = false;
    open-webui.enable = false;
    sillytavern.enable = false;
    postgresql.enable = false; # For vector DBs
    qdrant.enable = false;
    chromadb.enable = false;
    localai.enable = false;
    jan.enable = false;
    cherry-studio.enable = false;
    aider.enable = false;
  };

  # Infrastructure Services
  services-config = {
    homepage-dashboard.enable = false;
    monitoring.enable = false;
    avahi.enable = true; # Local network discovery
    media-stack.enable = false; # Arr suite (Sonarr, Radarr, etc.)
  };

  # Communication & Media Services
  services = {
    matrix-server.enable = false;
    mautrix-bridges.enable = false;
    immich-server.enable = false;
    nextcloud-server.enable = false;
    calibre-web-app.enable = false;
    ssh-agent.enable = true;
  };

  # ============================================================================
  # HOME MANAGER / USER CONFIGURATION
  # ============================================================================

  # User activation in flake-parts/users/t0psh31f.nix handles most things,
  # but you can override or add specific per-machine user settings here.

  home-manager.users.t0psh31f =
    { config, ... }:
    {
      # Desktop Environment Toggles
      desktop = {
        hyprland.enable = builtins.elem "desktop" (config.osConfig.clan.core.tags or [ ]);
        vicinae.enable = builtins.elem "desktop" (config.osConfig.clan.core.tags or [ ]);
      };

      # CLI Environment Toggles
      programs.cli-environment = {
        enable = true;
        theming.enable = true;
        modernTools.enable = true;
        nixTools.enable = true;
        shells.zsh.enable = true;
      };
    };
}
