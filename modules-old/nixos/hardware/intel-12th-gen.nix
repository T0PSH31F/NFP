{
  config,
  lib,
  pkgs,
  ...
}:
{
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
  services.power-profiles-daemon.enable = lib.mkForce true;

  # Thunderbolt
  services.hardware.bolt.enable = true;
}
