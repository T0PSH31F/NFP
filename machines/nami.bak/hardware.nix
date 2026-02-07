# machines/nami/hardware.nix
# Hardware-specific configuration for nami (Dell XPS 13 9360)
# - Disko-based disk configuration
# - Intel 7th gen CPU
# - Dell XPS specific hardware quirks
{
  inputs,
  ...
}:
{
  imports = [
    ../../flake-parts/hardware
    ../../flake-parts/hardware/laptop.nix
    ../../modules/nixos/hardware/intel-7th-gen.nix
    inputs.nixos-hardware.nixosModules.dell-xps-13-9360
    ./hardware-configuration.nix
    ./disko-config.nix
  ];

  # Machine-specific kernel blacklist for Broadcom wifi issues
  boot.blacklistedKernelModules = [
    "b43"
    "bcma"
    "brcmsmac"
    "ssb"
  ];

  # Networking Fixes (IWD backend for better wifi stability)
  networking.networkmanager = {
    enable = true;
    wifi.backend = "iwd";
  };
  networking.wireless.enable = false;

  # Platform
  nixpkgs.hostPlatform = "x86_64-linux";
}
