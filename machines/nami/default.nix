# machines/nami/default.nix
# Lightweight server/ISO machine (Dell XPS 13)
# Hardware-specific config in ./hardware.nix
{
  inputs,
  lib,
  ...
}:
{
  # ============================================================================
  # IMPORTS - New flake-parts structure
  # ============================================================================
  imports = [
    # Hardware configuration (Dell XPS 13, Intel 7th gen)
    ./hardware.nix

    # Home Manager
    inputs.home-manager.nixosModules.home-manager

    ../../modules/clan/lib.nix

    # Core system modules from flake-parts
    ../../flake-parts/system
    ../../flake-parts/themes
    ../../flake-parts/features/nixos

    # Clan modules
    # Clan modules replaced by clan-core
    # ../../modules/clan/tags.nix
    # ../../modules/clan/lib.nix
    # ../../modules/clan/metadata.nix
    # ../../modules/clan/service-distribution.nix
    # ../../modules/clan/secrets.nix

    # User configuration
    ../../modules/users/t0psh31f.nix

    # Packages and overlays
    ../../packages/default.nix
    ../../modules/nixos/overlays.nix

    # Additional modules not yet migrated
    ../../modules/nixos/yazelix.nix
  ];

  # ============================================================================
  # MACHINE METADATA
  # ============================================================================
  networking.hostName = "nami";
  system.stateVersion = "25.05";

  # ============================================================================
  # FEATURE TOGGLES
  # ============================================================================

  # Themes
  themes = {
    sddm-lain.enable = false;
    grub-lain.enable = true;
    plymouth-matrix.enable = false;
    plymouth-hellonavi.enable = true;
  };

  # Portals
  desktop.portals.enable = false;

  # Mobile device support
  mobile = {
    android.enable = false;
    ios.enable = false;
  };

  # System tools
  nix-tools.enable = false;

  # Gaming & Virtualization
  gaming.enable = false;
  virtualization.enable = false;

  # Flatpak & AppImage
  flatpak.enable = false;

  # Impermanence
  system-config.impermanence.enable = true;

  # ============================================================================
  # SERVICES
  # ============================================================================

  services = {
    llm-agents.enable = true;

    # AI Services (mostly disabled for lightweight setup)
    ai-services = {
      enable = false;
    };

    # Media & Cloud (disabled)
    immich-server.enable = false;
    calibre-web-app.enable = false;
    nextcloud-server.enable = false;

    # Communication (disabled)
    matrix-server.enable = false;
    mautrix-bridges.enable = false;

    # Machine-specific DNS fix
    resolved.dnssec = "false";
  };

  # Services config (separate namespace)
  services-config = {
    avahi.enable = false;
    monitoring.enable = false;
  };

  # ============================================================================
  # YAZELIX INTEGRATION
  # ============================================================================
  # DISABLED: Yazelix flake missing homeManagerModules
  # modules.yazelix.enable = true;

  # ============================================================================
  # HOME-MANAGER CONFIGURATION
  # ============================================================================
  home-manager = {
    backupFileExtension = "hm-backup";
    extraSpecialArgs = { inherit inputs; };
    users.t0psh31f = {
      imports = [ ../../flake-parts/features/home ];
      programs = {
        keybind-cheatsheet.enable = false;
        pentest.enable = false;
      };
    };
  };
}
