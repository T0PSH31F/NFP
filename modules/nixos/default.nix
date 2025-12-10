{
  inputs,
  lib,
  ...
}: {
  imports = [
    inputs.home-manager.nixosModules.home-manager

    # System Core
    ./system/base.nix

    # Display & Desktop
    ./display-manager.nix

    # Hardware
    ./hardware/hardware.nix

    # Packages & Tools
    ./packages.nix
    ./browsers.nix
    ./file-managers.nix
    ./nix-tools.nix

    # Networking
    ./networking.nix

    # Services
    ./services/default.nix

    # Features
    ./virtualization.nix
    ./gaming.nix
    ./impermanence.nix

    # Themes
    ./themes/sddm-lain.nix
    ./themes/grub-lain.nix
    ./themes/plymouth-matrix.nix
    ./themes/plymouth-hellonavi.nix
  ];

  # Force clear nixpkgs config to avoid conflicts with clan-core's external instance
  # The allowUnfree setting is handled in flake.nix via pkgsForSystem
  nixpkgs.config = lib.mkForce {allowUnfree = true;};
  nixpkgs.overlays = [inputs.nur.overlays.default];

  # Home manager configuration
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = {inherit inputs;};
}
