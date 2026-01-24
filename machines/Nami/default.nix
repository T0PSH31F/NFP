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
    ./disko.nix
    ../../modules/nixos/default.nix
    ../../modules/Desktop-env/default.nix
    ../../modules/users/t0psh31f.nix
    inputs.nixos-hardware.nixosModules.dell-xps-13-9360
  ];

  # ============================================================================
  # BASIC CONFIGURATION
  # ============================================================================

  networking.hostName = "Nami"; # Set your hostname

  system.stateVersion = "25.05"; # Don't change after initial install

  # ============================================================================
  # DESKTOP ENVIRONMENT (Choose one or enable multiple)
  # ============================================================================

  desktop.dankmaterialshell = {
    enable = true;
    backend = "hyprland"; # "hyprland", "niri", or "both"
  };

  desktop.omarchy = {
    enable = false;
    backend = "hyprland";
  };

  desktop.caelestia = {
    enable = false;
    backend = "hyprland";
  };

  desktop.illogical.enable = false; # End-4 Hyprland config

  # ============================================================================
  # THEMES
  # ============================================================================

  themes.sddm-lain.enable = false;
  themes.grub-lain.enable = true;
  themes.plymouth-matrix.enable = false;
  themes.plymouth-hellonavi.enable = true;

  # ============================================================================
  # MOBILE DEVICE SUPPORT
  # ============================================================================
  mobile.android.enable = false;
  mobile.ios.enable = false;

  # ============================================================================
  # SERVICES
  # ============================================================================
  services.home-assistant-server.enable = false;
  services.caddy-server.enable = false;
  services.sillytavern-app.enable = false;

  services.ai-services = {
    enable = false; # Enables PostgreSQL vector DB
    # open-webui.enable = false;
    # localai.enable = false;
    # chromadb.enable = false;
  };

  # Media & Cloud
  services.immich-server.enable = false;
  services.calibre-web-app.enable = false;
  services.nextcloud-server.enable = false;
  services-config.media-stack.enable = false;

  # Communication
  services.matrix-server.enable = false;
  services.mautrix-bridges.enable = false;
  services-config.avahi.enable = false;

  # Monitoring
  services-config.monitoring.enable = false;

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
  system-config.impermanence.enable = true;
}
