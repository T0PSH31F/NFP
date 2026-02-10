# modules/nixos/performance.nix
# Purpose:
# - Kernel sysctl tuning for memory and network
# - zram compressed swap for 16GB RAM systems
# - Faster boot (initrd + disabling unnecessary waits)
# - tmpfs for /tmp
# Designed to be safe across all machines.

{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Kernel sysctl settings
  boot.kernel.sysctl = {
    # Memory behaviour
    "vm.swappiness" = lib.mkDefault 10;
    "vm.vfs_cache_pressure" = lib.mkDefault 50;
    "vm.dirty_ratio" = lib.mkDefault 10;
    "vm.dirty_background_ratio" = lib.mkDefault 5;

    # Network buffers (good defaults for LAN & WAN)
    "net.core.rmem_max" = lib.mkDefault 134217728;
    "net.core.wmem_max" = lib.mkDefault 134217728;
    "net.ipv4.tcp_rmem" = lib.mkDefault "4096 87380 67108864";
    "net.ipv4.tcp_wmem" = lib.mkDefault "4096 65536 67108864";
    "net.ipv4.tcp_window_scaling" = lib.mkDefault 1;
    "net.ipv4.tcp_timestamps" = lib.mkDefault 1;
  };

  # zram swap: crucial for 16GB systems with heavy builds
  zramSwap = {
    enable = lib.mkDefault true;
    algorithm = lib.mkDefault "zstd";
    memoryPercent = lib.mkDefault 50; # ~8GB virtual swap
    priority = lib.mkDefault 5;
  };

  # Boot optimization
  boot.initrd.systemd.enable = lib.mkForce true;
  boot.initrd.compressor = lib.mkDefault "zstd";
  boot.initrd.compressorArgs = lib.mkDefault [
    "-19"
    "-T0"
  ];

  # Do not block boot on udev settle or network
  systemd.services.systemd-udev-settle.enable = lib.mkDefault false;
  systemd.network.wait-online.enable = lib.mkDefault false;

  # tmpfs for /tmp (fast, auto-cleaning)
  boot.tmp.useTmpfs = lib.mkDefault true;
  boot.tmp.tmpfsSize = lib.mkDefault "4G";
  boot.tmp.cleanOnBoot = lib.mkDefault true;
  # Explicitly enable dbus-broker (modern performance-oriented dbus implementation)
  # This prevents deployment failure when switching from a system that already has it.
  services.dbus.implementation = "broker";

  # Explicitly disable conflicting power services
  services.thermald.enable = lib.mkForce false;
  services.auto-cpufreq.enable = lib.mkForce false;
}
