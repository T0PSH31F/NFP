# machines/nami/default.nix
# Main configuration for Nami
# Intel i7-7560U laptop, secondary machine
{ ... }:
{
  # ============================================================================
  # IMPORTS
  # ============================================================================
  imports = [
    # Hardware configuration (filesystems, kernel modules)
    ./hardware.nix

    # Core system modules from flake-parts
    ../../flake-parts/system
    ../../flake-parts/hardware
    ../../flake-parts/themes
    ../../flake-parts/features/nixos

    # User configuration (HM + user-specific system settings)
    ../../flake-parts/users/t0psh31f.nix
  ];

  # ============================================================================
  # MACHINE METADATA
  # ============================================================================
  networking.hostName = "nami";
  system.stateVersion = "25.05";

  # ============================================================================
  # FEATURE TOGGLES
  # ============================================================================

  # System features
  nix-tools.enable = true;
  desktop-portals.enable = true;

  # Themes - match z0r0 for consistency
  themes = {
    sddm-sel = {
      enable = true;
      variant = "shaders";
    };
    grub-lain.enable = true;
    plymouth-hellonavi.enable = true;
  };

  # Mobile device support
  mobile = {
    android.enable = false;
    ios.enable = false;
  };

  # Gaming & Virtualization
  gaming.enable = false;
  virtualization.enable = false;

  # Flatpak & AppImage
  flatpak.enable = true;

  # Impermanence - disabled for initial install, enable later once stable
  system-config.impermanence.enable = false;

  # ============================================================================
  # SERVICES - Minimal for initial setup
  # ============================================================================
  services = {
    ssh-agent.enable = true;
  };

  # ============================================================================
  # SOPS SECRETS
  # ============================================================================
  sops.age.keyFile = "/home/t0psh31f/.config/sops/age/keys.txt";

  # ============================================================================
  # SECURITY / ACME
  # ============================================================================
  security.acme = {
    acceptTerms = true;
    defaults.email = "admin@grandlix.com";
  };
}
