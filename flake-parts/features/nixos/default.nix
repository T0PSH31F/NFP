# flake-parts/features/nixos/default.nix
# NixOS feature toggles - optional system functionality
{
  imports = [
    ./gaming.nix
    ./virtualization.nix
    ./impermanence.nix
    ./mobile-support.nix
    ./flatpak.nix
    ./appimage.nix
    ./performance.nix
  ];
}
