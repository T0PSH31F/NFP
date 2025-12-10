{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [
    inputs.home-manager.nixosModules.default
    inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series
    inputs.fw-fanctrl.nixosModules.default

    outputs.nixosModules.berkeley-mono
    outputs.nixosModules.omarchy-config

    ../../modules/users/henry.nix
    ./hardware-configuration.nix

    ../common/global.nix
    ../common/desktop.nix
    ../common/dev.nix
    ../common/samba.nix

    ../common/packages.nix

    # ../common/gnome
  ];

  home-manager.users.henry = {
    imports = [
      ../../home/henry
      inputs.omarchy.homeManagerModules.default
    ];
  };

  environment.systemPackages = [pkgs.filezilla];
  # Fan control
  programs.fw-fanctrl.enable = true;
  home-manager.useGlobalPkgs = true;
  home-manager.extraSpecialArgs = {
    inherit inputs outputs;
  };
  services.fwupd.enable = true;
  networking.hostName = "siegfried";
  system.stateVersion = "25.05";
  security.polkit.enable = true;
  boot.loader = {
    timeout = 0;
    efi.canTouchEfiVariables = true;
    systemd-boot = {
      enable = true;
      # configurationLimit = 4;
    };
  };
}
