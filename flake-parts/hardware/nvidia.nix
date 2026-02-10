{ config, lib, pkgs, ... }:

with lib;

{
  options.hardware.nvidia.enable = mkEnableOption "NVIDIA graphics support";

  config = mkIf config.hardware.nvidia.enable {
    # NVIDIA driver configuration
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };

    # NVIDIA specific packages
    environment.systemPackages = with pkgs; [
      nvidia-vaapi-driver
      libva-utils
      nvtopPackages.nvidia
    ];

    # Graphics packages for NVIDIA
    hardware.graphics.extraPackages = with pkgs; [
      nvidia-vaapi-driver
      vaapiVdpau
      libvdpau-va-gl
    ];
  };
}