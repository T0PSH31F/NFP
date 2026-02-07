{ config, lib, pkgs, ... }:

with lib;

{
  options.hardware.amd.enable = mkEnableOption "AMD graphics support";

  config = mkIf config.hardware.amd.enable {
    # AMD driver configuration
    services.xserver.videoDrivers = [ "amdgpu" ];

    # Enable AMD GPU support
    boot.initrd.kernelModules = [ "amdgpu" ];

    # AMD specific packages
    environment.systemPackages = with pkgs; [
      radeontop
      nvtopPackages.amd
    ];

    # Graphics packages for AMD
    hardware.graphics.extraPackages = with pkgs; [
      amdvlk
      rocm-opencl-icd
      rocm-opencl-runtime
    ];

    hardware.graphics.extraPackages32 = with pkgs.pkgsi686Linux; [
      driversi686Linux.amdvlk
    ];

    # AMD GPU firmware
    hardware.enableRedistributableFirmware = true;
  };
}