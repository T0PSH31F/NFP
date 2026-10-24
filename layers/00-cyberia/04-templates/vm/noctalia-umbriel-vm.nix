{
  pkgs,
  lib,
  config,
  inputs,
  modulesPath,
  ...
}:
{
  imports = [
    "${modulesPath}/virtualisation/qemu-vm.nix"
    inputs.home-manager.nixosModules.home-manager
    inputs.nixos-passthru-cache.nixosModules.nixos-passthru-cache
    ../../../10-system/13-users/hm-catalog.nix
    ../../../10-system/11-foundation
    ../../../30-environments
    ../../../40-desktop
  ];

  networking.hostName = "noctalia-umbriel-vm";

  virtualisation = {
    memorySize = 4096;
    cores = 4;
    graphics = true;
    resolution = {
      x = 1920;
      y = 1080;
    };
    qemu.options = [
      "-vga virtio"
      "-display gtk,gl=on"
    ];
  };

  machine.tags = [
    "desktop"
    "vm"
  ];

  layers.desktop = {
    enable = true;
    experience = "noctalia-umbriel";
  };

  hardware.graphics.enable = true;

  services = {
    qemuGuest.enable = true;
    spice-vdagentd.enable = true;
    displayManager.autoLogin = {
      enable = true;
      user = "t0psh31f";
    };
  };

  users.users.t0psh31f = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "video"
      "input"
      "audio"
    ];
    initialPassword = "nixos";
  };

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    ghostty
    kitty
    fastfetch
    pciutils
  ];

  system.stateVersion = "26.05";
}
