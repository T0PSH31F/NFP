# machines/z0r0/default.nix
# Main configuration for z0r0 laptop
# Hardware-specific config in ./hardware.nix
{
  lib,
  inputs,
  ...
}:
{
  # ============================================================================
  # IMPORTS - New flake-parts structure
  # ============================================================================
  imports = [
    # Hardware configuration (LUKS, filesystems, swap)
    ./hardware.nix

    # Home Manager
    inputs.home-manager.nixosModules.home-manager

    # Legacy Clan Lib (required for packages/ modules)
    ../../modules/clan/lib.nix

    # Machine now managed by clan inventory for services
    # See: flake-parts/clan-inventory.nix for service instances

    # Core system modules from flake-parts
    ../../flake-parts/system
    ../../flake-parts/hardware
    ../../flake-parts/themes
    ../../flake-parts/desktop
    ../../flake-parts/features/nixos

    ../../flake-parts/services/ai
    ../../flake-parts/services/media
    ../../flake-parts/services/infrastructure
    ../../flake-parts/services/communication

    # Clan modules replaced by clan-core and clan-inventory.nix
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
    ../../modules/nixos/nix-tools.nix
  ];

  # ============================================================================
  # MACHINE METADATA
  # ============================================================================
  networking.hostName = "z0r0";
  system.stateVersion = "25.05";

  # ============================================================================
  # FEATURE TOGGLES
  # ============================================================================

  # System features
  nix-tools.enable = true;
  desktop-portals.enable = true;

  # Themes
  themes = {
    sddm-lainframe.enable = true;
    sddm-lain.enable = false;
    sddm-sel = {
      enable = false;
      variant = "shaders";
    };

    grub-lain.enable = true;
    plymouth-hellonavi.enable = true;
  };

  # Mobile device support
  mobile = {
    android.enable = true;
    ios.enable = true;
  };

  # Gaming & Virtualization
  gaming.enable = false;
  virtualization.enable = true;

  # Flatpak & AppImage
  flatpak.enable = true;

  # Impermanence
  system-config.impermanence.enable = true;

  # ============================================================================
  # SERVICES
  # ============================================================================

  services = {
    # Desktop Services
    ssh-agent.enable = true;
    searxng.enable = true;
    pastebin.enable = true;

    # Home Automation & Infrastructure
    home-assistant-server.enable = true;
    caddy-server.enable = true;
    n8n-server.enable = true;

    # AI Services - Granular toggles
    llm-agents.enable = true;
    ai-services = {
      enable = true;
      open-webui.enable = true;
      localai.enable = true;
      chromadb.enable = true;
      qdrant.enable = false;
      lmstudio.enable = true;
      jan.enable = true;
      cherry-studio.enable = true;
      aider.enable = true;
    };

    # Media & Cloud
    immich-server.enable = true;
    calibre-web-app.enable = true;
    nextcloud-server.enable = true;

    # Communication
    matrix-server.enable = true;
    mautrix-bridges.enable = true;

    # Extra Services
    glances-server.enable = true;
    filebrowser-app.enable = true;
    deluge-server.enable = true;
    transmission-server.enable = true;
    headscale-server.enable = true;

    # Service configuration files
    aria2.rpcSecretFile = "/etc/aria2-rpc-token";
    deluge.authFile = "/etc/deluge-auth";
  };

  # Services config (separate namespace for config-only services)
  services-config = {
    media-stack.enable = false; # Toggle for *arr suite
    avahi.enable = true; # mDNS
    monitoring.enable = true;
    homepage-dashboard.enable = true;
  };

  # ============================================================================
  # SOPS SECRETS
  # ============================================================================
  sops.age.keyFile = "/home/t0psh31f/.config/sops/age/keys.txt";

  # ============================================================================
  # HOME-MANAGER CONFIGURATION
  # ============================================================================
  home-manager = {
    backupFileExtension = "hm-backup";
    extraSpecialArgs = { inherit inputs; };
    users.t0psh31f = {
      imports = [
        ../../flake-parts/features/home
      ];
      programs.cli-environment.enable = true;
    };
  };

  # Enable Yazelix System Module
  # DISABLED: The yazelix flake input is missing homeManagerModules attribute causing build failure.
  # modules.yazelix.enable = true;

  # ============================================================================
  # ENVIRONMENT CONFIGURATION
  # ============================================================================

  # Aria2 RPC secret file
  environment.etc."aria2-rpc-token" = {
    text = "temporary-secret-change-me";
    mode = "0400";
    user = "media";
    group = "media";
  };

  # Deluge auth file
  environment.etc."deluge-auth" = {
    text = "localclient:a7c6f0e3bc4:10";
    mode = "0400";
    user = "media";
    group = "media";
  };

  # ============================================================================
  # SECURITY / ACME
  # ============================================================================
  security.acme = {
    acceptTerms = true;
    defaults.email = "admin@grandlix.com";
  };
}
