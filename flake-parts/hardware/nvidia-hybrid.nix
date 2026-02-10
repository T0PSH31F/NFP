{
  config,
  lib,
  pkgs,
  ...
}:
{
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = true;
    open = false; # Proprietary drivers
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };

      # PLACEHOLDER BUS IDs - MUST BE UPDATED WITH `lspci`
      # Intel Bus ID: typically 00:02.0
      intelBusId = "PCI:0:2:0";
      # Nvidia Bus ID: typically 01:00.0 or similar
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true; # For Steam
  };
}
