# Container Image Configuration
# Optimized for Docker/Podman deployment.
#
# Usage:
#   1. Copy this template: cp -r templates/container machines/my-container
#   2. Build: nix build .#packages.x86_64-linux.docker (matching machine name)

{ pkgs, lib, ... }:

{
  # Only import what is necessary for a container
  imports = [
    ../../flake-parts/system/core-programs.nix
    ../../flake-parts/features/nixos/packages/base.nix
  ];

  boot.isContainer = true;

  # Minimal networking for OCI
  networking = {
    hostName = "grandlix-container";
    useDHCP = false;
  };

  # Essential packages for containers
  environment.systemPackages = with pkgs; [
    curl
    wget
    git
    vim
    procps
    htop
  ];

  # SSH for remote management
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  # Use system-config to toggle standard features if desired
  # system-config.impermanence.enable = false;

  # Clean up and minimal config
  documentation.man.enable = false;
  services.getty.helpLine = lib.mkForce "";

  system.stateVersion = "25.05";
}
