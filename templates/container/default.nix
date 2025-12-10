# Container Image Configuration
#
# Creates container images for Docker/Podman
# Useful for:
# - Microservices
# - Development environments
# - CI/CD
#
# Build with: nix build .#images.container
{
  config,
  lib,
  pkgs,
  ...
}: {
  # Base container configuration
  # This creates a minimal container with essential tools

  imports = [
    ../../modules/system/packages.nix
  ];

  # No need for boot configuration in containers
  boot.isContainer = true;

  # Minimal networking
  networking = {
    hostName = "grandlix-container";
    useDHCP = false;
    firewall.enable = true;
  };

  # Essential packages for containers
  environment.systemPackages = with pkgs; [
    # Basic utilities
    coreutils
    curl
    wget
    git
    vim

    # Networking
    iproute2
    iputils
    dnsutils

    # Process management
    procps
    htop

    # Compression
    gzip
    unzip

    # Development
    gcc
    gnumake

    # Nix tools
    nix
  ];

  # Enable SSH for remote management
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  # Create a default user
  users.users.container = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    initialPassword = "container";
  };

  # Allow sudo without password (for development containers)
  security.sudo.wheelNeedsPassword = false;

  # Enable nix flakes in container
  nix.settings.experimental-features = ["nix-command" "flakes"];

  system.stateVersion = "25.05";
}
