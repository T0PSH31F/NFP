# machines/luffy/hardware.nix
# Hardware-specific configuration for luffy
# - Disko-based disk configuration
# - LUKS + BTRFS with impermanence
# - Nvidia hybrid graphics
{
  imports = [
    ../../flake-parts/hardware
    ../../flake-parts/hardware/laptop.nix
    ../../modules/nixos/hardware/nvidia-hybrid.nix
    ./disko.nix
  ];

  # Platform
  nixpkgs.hostPlatform = "x86_64-linux";
}
