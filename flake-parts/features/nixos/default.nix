# flake-parts/features/nixos/default.nix
# NixOS feature toggles - optional system functionality
{
  imports = [
    ./appimage.nix
    ./desktop
    ./flatpak.nix
    ./gaming.nix
    ./impermanence.nix
    ./mobile-support.nix
    ./packages
    ./performance.nix
    ./virtualization.nix
  ];
}
