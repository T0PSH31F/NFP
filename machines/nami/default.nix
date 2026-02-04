# Machine Template - Copy this directory to create new machines
#
# Usage:
#   1. Copy this template directory: cp -r templates/machine machines/newmachine
#   2. Edit machines/newmachine/default.nix with your settings
#   3. Generate hardware config: nixos-generate-config --root /mnt --show-hardware-config > machines/newmachine/hardware-configuration.nix
#   4. Add to clan.nix inventory and machines sections
#   5. Build and deploy!
{
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./disko-config.nix
    ../../modules/nixos/nix-settings.nix
    ../../modules/nixos/performance.nix
    ../../modules/nixos/overlays.nix
    ../../modules/clan/tags.nix
    ../../modules/clan/lib.nix
    ../../modules/clan/metadata.nix
    ../../modules/clan/service-distribution.nix
    ../../modules/clan/secrets.nix

    ../../modules/nixos/default.nix
    ../../modules/nixos/hardware/intel-7th-gen.nix
    ../../packages/default.nix
    ../../modules/users/t0psh31f.nix
    inputs.nixos-hardware.nixosModules.dell-xps-13-9360
  ];

  # ============================================================================
  # CONFIGURATION (Dendritic Pattern - Everything in config block)
  # ============================================================================

  config = {
    # ============================================================================
    # BASIC CONFIGURATION
    # ============================================================================

    networking.hostName = "nami"; # Set your hostname
    system.stateVersion = "25.05"; # Don't change after initial install

    clan.tags = [
      "server"
      "media-server"
      "download-server"
    ];

    # Boot Loader Fix
    boot.loader = {
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };

    # Networking Fixes (IWD)
    networking.networkmanager = {
      enable = true;
      wifi.backend = "iwd";
    };
    networking.wireless.enable = false;

    # ============================================================================
    # FEATURE TOGGLES (Dendritic Pattern - Nested Attrsets)
    # ============================================================================

    # Themes
    themes = {
      sddm-lain.enable = false;
      grub-lain.enable = true;
      plymouth-matrix.enable = false;
      plymouth-hellonavi.enable = true;
    };

    # Mobile device support
    mobile = {
      android.enable = false;
      ios.enable = false;
    };

    # System tools
    nix-tools.enable = false;
    desktop-portals.enable = false;

    # Gaming & Virtualization
    gaming.enable = false; # Master toggle for all gaming features
    virtualization.enable = false; # Docker, Podman, QEMU/KVM

    # Flatpak & AppImage
    flatpak.enable = false;
    programs.appimage-support.enable = false;

    # ============================================================================
    # SERVICE TOGGLES (Dendritic Pattern - Nested Attrsets)
    # ============================================================================

    services = {
      # Infrastructure
      # home-assistant-server.enable = false;
      # caddy-server.enable = false;
      # sillytavern-app.enable = false;
      llm-agents.enable = true;

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

      # Machine-specific internet fixes
      resolved.dnssec = "false";
    };

    # Services config (separate namespace)
    services-config = {
      # media-stack.enable = false; # Managed by service-distribution.nix via 'media-server' tag
      avahi.enable = false;
      monitoring.enable = false;
    };

    # ============================================================================
    # ADDITIONAL FEATURES
    # ============================================================================

    system-config.impermanence.enable = true;

    # Machine-specific kernel blacklist
    boot.blacklistedKernelModules = [
      "b43"
      "bcma"
      "brcmsmac"
      "ssb"
    ];

    # ============================================================================
    # HOME-MANAGER CONFIGURATION
    # ============================================================================

    home-manager.users.t0psh31f = {
      # Home-Manager programs
      programs = {
        yazelix.enable = false;
        keybind-cheatsheet.enable = false;
        pentest.enable = false;
      };
    };
  };
}
