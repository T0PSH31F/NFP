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
      intel-media-driver
      vaapiIntel # i965 driver for older gen
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  # TLP is often better for older Dell XPS
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
    };
  };

  # Disable conflicting services
  services.power-profiles-daemon.enable = lib.mkForce false;
  services.auto-cpufreq.enable = lib.mkForce false;

  # WiFi firmware fixes
  hardware.enableRedistributableFirmware = true;
}
