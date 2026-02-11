# VM Configuration Template
# Suitable for testing and trial runs in QEMU.
#
# Usage:
#   1. Copy this template: cp -r templates/vm machines/test-vm
#   2. Build VM: nixos-rebuild build-vm --flake .#test-vm
#   3. Run VM: ./result/bin/run-test-vm-vm

{
  pkgs,
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")

    # Standard system core
    ../../flake-parts/system
    ../../flake-parts/features/nixos
  ];

  # VM-optimized settings
  networking.hostName = "grandlix-vm";

  # Hardware acceleration in VM (optional)
  hardware.graphics.enable = true;

  # Virtualization guest tools
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  # Display Manager for testing GUI features
  # (Enable 'desktop' tag in clan.nix or set options below)

  clan.core.tags = [
    "desktop"
    "vm"
  ];

  # shared folder setup for QEMU
  fileSystems."/mnt/shared" = {
    fsType = "9p";
    device = "shared";
    options = [
      "trans=virtio"
      "version=9p2000.L"
      "msize=104857600"
    ];
  };

  # Auto-login for easy testing
  services.displayManager.autoLogin = {
    enable = true;
    user = "t0psh31f";
  };

  # Faster boot settings
  boot.loader.timeout = 1;
  boot.loader.grub.device = "/dev/vda";

  system.stateVersion = "25.05";
}
