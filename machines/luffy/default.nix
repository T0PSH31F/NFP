# machines/luffy/default.nix
# Gaming + AI laptop with Nvidia GPU
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
    # Hardware configuration (Disko, Nvidia hybrid)
    ./hardware.nix

    # Core system modules from flake-parts
    ../../flake-parts/system
    ../../flake-parts/themes
    ../../flake-parts/desktop
    ../../flake-parts/features/nixos
    ../../flake-parts/features/home
    ../../flake-parts/services/ai

    # Clan modules
    ../../modules/clan/tags.nix
    ../../modules/clan/lib.nix
    ../../modules/clan/metadata.nix
    ../../modules/clan/service-distribution.nix
    ../../modules/clan/secrets.nix

    # User configuration
    ../../modules/users/t0psh31f.nix

    # Packages and overlays
    ../../packages/default.nix
    ../../modules/nixos/overlays.nix
  ];

  # ============================================================================
  # MACHINE METADATA
  # ============================================================================
  networking.hostName = "luffy";
  system.stateVersion = "25.05";

  # ============================================================================
  # CLAN TAGS - Drives service distribution
  # ============================================================================
  clan.tags = [
    "desktop"
    "laptop"
    "gaming"
    "ai-heavy"
    "nvidia"
  ];

  # ============================================================================
  # FEATURE TOGGLES
  # ============================================================================

  # Themes
  themes = {
    plymouth-hellonavi.enable = true;
    grub-lain.enable = true;
  };

  # Gaming
  gaming.enable = true;

  # Impermanence
  system-config.impermanence.enable = true;

  # ============================================================================
  # SERVICES
  # ============================================================================

  services.ai-services = {
    enable = true;
    open-webui.enable = true;
    ollama.enable = true;
    ollama.acceleration = "cuda"; # Nvidia GPU acceleration
  };

  # ============================================================================
  # HOME-MANAGER CONFIGURATION
  # ============================================================================
  home-manager = {
    backupFileExtension = "hm-backup";
    extraSpecialArgs = { inherit inputs; };
    users.t0psh31f = {
      imports = [ ../../modules/home ];
      # programs.vicinae.enable = true;
    };
  };
}
