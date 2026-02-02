{
  config,
  lib,
  pkgs,
  ...
}:
{
  boot.kernelPackages = pkgs.linuxPackages_latest;

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # iHD driver for Gen9+
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  # Thermal management
  services.thermald.enable = lib.mkForce true;

  # Power management
  services.auto-cpufreq.enable = lib.mkForce true;
  services.power-profiles-daemon.enable = lib.mkForce false; # Conflict with auto-cpufreq

  # Thunderbolt
  services.hardware.bolt.enable = true;
}
