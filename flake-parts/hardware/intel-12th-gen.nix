# flake-parts/hardware/intel-12th-gen.nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  hasTag = tag: builtins.elem tag (config.clan.core.tags or [ ]);
in
{
  config = lib.mkIf (hasTag "intel-12th-gen") {
    boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver # iHD driver for Gen9+
        libva-vdpau-driver
        libvdpau-va-gl
      ];
    };

    # Thermal management (Thermald is causing "Temperature check failed" on this hardware)
    services.thermald.enable = lib.mkForce false;

    # Power management (Switching to PPD for better GNOME/KDE integration and stability)
    services.auto-cpufreq.enable = lib.mkForce false;
    services.power-profiles-daemon.enable = lib.mkDefault true;

    # Thunderbolt
    services.hardware.bolt.enable = true;
  };
}
