{
  inputs,
  lib,
  ...
}:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops

    # System Core
    ./system/base.nix
    ./system/desktop-portals.nix

    # Display & Desktop
    ./display-manager.nix

    # Hardware
    ./hardware/default.nix

    # Packages & Tools
    ./llm-agents.nix
    ./packages.nix
    ./file-managers.nix
    ./nix-tools.nix
    ./nix-settings.nix

    # Networking
    ./networking.nix

    # Services
    ./services/default.nix

    # Features
    ./virtualization.nix
    ./gaming.nix
    ./impermanence.nix
    ./mobile.nix
    ./flatpak.nix
    ./appimage.nix

    # Themes
    ./themes/sddm-lain.nix
    ./themes/sddm-lainframe.nix
    ./themes/sddm-sel.nix
    ./themes/grub-lain.nix
    ./themes/plymouth-matrix.nix
    ./themes/plymouth-hellonavi.nix
  ];

  # Force clear nixpkgs config to avoid conflicts with clan-core's external instance
  # The allowUnfree setting is handled in flake.nix via pkgsForSystem
  nixpkgs.config = lib.mkForce { allowUnfree = true; };
  nixpkgs.overlays =
    let
      themeOverlays = import ../../pkgs/overlays.nix;
    in
    [
      inputs.nur.overlays.default
      themeOverlays.sonic-cursor
      themeOverlays.themes
    ];

  # Home manager configuration
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = { inherit inputs; };
}
