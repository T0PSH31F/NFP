{
  pkgs,
  ...
}:
{
  users.users.t0psh31f = {
    isNormalUser = true;
    description = "t0psh31f";

    # All required groups for Grandlix-Gang services
    extraGroups = [
      "wheel" # Sudo access
      "networkmanager" # Network configuration
      "audio" # Audio devices
      "video" # Video devices
      "libvirtd" # Virtualization (QEMU/KVM)
      "docker" # Docker containers
      "podman" # Podman containers
      "i2c" # OpenRGB RGB control
    ];

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJrQr8qxQTw45PNpsDNahVE23tpV3Zap+IKr6eVkL75Z t0psh31f@grandlix.gang"
    ];

    shell = pkgs.zsh;
    hashedPassword = "$6$WbMMiboG5lnMx4Ok$.RCZzi7GUXpt0gqsdgHL3jnke5OgCfdoOpErWxZ9/2oJj/guc5zZRYPBYzcBkV/929cwSIno/4RtW0Rfz8GCy/";
  };

  programs.zsh.enable = true;

  # Back up existing files that would be clobbered by home-manager
  # home-manager.backupFileExtension = "home-backup"; # Moved to machine-specific config

  home-manager.users.t0psh31f = {
    imports = [
      ../../flake-parts/features/home
    ];

    home.stateVersion = "25.05";
    home.username = "t0psh31f";
    home.homeDirectory = "/home/t0psh31f";

    # Enable the new CLI environment
    programs.cli-environment.enable = true;
  };
}
