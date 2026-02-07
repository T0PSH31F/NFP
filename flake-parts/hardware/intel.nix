{ config, lib, pkgs, ... }:

with lib;

{
  options.hardware.intel.enable = mkEnableOption "Intel graphics support";

  config = mkIf config.hardware.intel.enable {
    # Intel driver configuration
    services.xserver.videoDrivers = [ "modesetting" ];

    # Enable Intel GPU support
    boot.initrd.kernelModules = [ "i915" ];

    # Intel GPU early loading
    boot.kernelParams = [ "i915.enable_guc=2" ];

    # Intel specific packages
    environment.systemPackages = with pkgs; [
      intel-gpu-tools
      nvtopPackages.intel
    ];

    # Graphics packages for Intel (already configured in default.nix)
    hardware.graphics.extraPackages = with pkgs; [
      intel-media-driver
      vaapiIntel
      intel-compute-runtime
      intel-ocl
    ];

    hardware.graphics.extraPackages32 = with pkgs.pkgsi686Linux; [
      vaapiIntel
    ];

    # Intel GPU power management
    powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  };
}