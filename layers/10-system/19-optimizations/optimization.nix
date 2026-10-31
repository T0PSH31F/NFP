# flake-parts/system/optimization.nix
# System optimization, stability, and performance tuning
{
  lib,
  ...
}:
{
  # ============================================================================
  # MEMORY MANAGEMENT
  # ============================================================================

  # Zram - compressed swap in RAM (crucial for 16GB systems)
  zramSwap = {
    enable = lib.mkDefault true;
    algorithm = lib.mkDefault "zstd";
    memoryPercent = lib.mkDefault 50;
    priority = lib.mkDefault 100; # Higher priority than disk swap
  };

  # ============================================================================
  # BOOT & KERNEL TUNING
  # ============================================================================

  boot = {
    kernel.sysctl = {
      # Memory behavior (Optimized for desktop/zram)
      "vm.swappiness" = lib.mkDefault 100; # Proactive swapping for zram
      "vm.vfs_cache_pressure" = lib.mkDefault 50;
      "vm.dirty_ratio" = lib.mkDefault 10;
      "vm.dirty_background_ratio" = lib.mkDefault 5;
      "vm.oom_kill_allocating_task" = lib.mkDefault 1;
      "fs.inotify.max_user_watches" = lib.mkForce 524288;

      # Network buffers (Performance tuning for LAN & WAN)
      "net.core.rmem_max" = lib.mkDefault 134217728;
      "net.core.wmem_max" = lib.mkDefault 134217728;
      "net.ipv4.tcp_rmem" = lib.mkDefault "4096 87380 67108864";
      "net.ipv4.tcp_wmem" = lib.mkDefault "4096 65536 67108864";
      "net.ipv4.tcp_window_scaling" = lib.mkDefault 1;
      "net.ipv4.tcp_timestamps" = lib.mkDefault 1;
    };

    initrd = {
      systemd.enable = lib.mkForce true;
      compressor = lib.mkDefault "zstd";
    };

    # TMPFS for /tmp (fast, auto-cleaning in RAM)
    tmp = {
      useTmpfs = lib.mkDefault true;
      tmpfsSize = lib.mkDefault "4G";
      cleanOnBoot = lib.mkDefault true;
    };
  };

  # Faster boot: do not block on udev settle or network
  systemd.services.systemd-udev-settle.enable = lib.mkDefault false;
  systemd.network.wait-online.enable = lib.mkDefault false;

  # ============================================================================
  # SYSTEM SERVICES & MAINTENANCE
  # ============================================================================

  services = {
    # Earlyoom - proactive OOM killer preventing total kernel page-thrashing lockups
    earlyoom = {
      enable = lib.mkDefault true;
      freeMemThreshold = lib.mkDefault 5;
      freeSwapThreshold = lib.mkDefault 5;
      enableNotifications = true;
      extraArgs = [
        "--prefer"
        "^(Web Content|Isolated Web Co|chromium|firefox|brave)$"
        "--avoid"
        "^(Hyprland|hyprland|noctalia|Noctalia|sshd|systemd|greetd|extreme-router|omniroute|brain-service|caddy|calibre-web|nix-daemon|nix|nix-build|clan|nixos-rebuild|glados.*|jarvis.*|ghostty|neovim|nvim)$"
        "--ignore"
        "^(nix-daemon|nix|nix-build|clan|nixos-rebuild|systemd)$"
      ];
    };

    # Modern performance-oriented dbus implementation
    dbus.implementation = "broker";

    # Conflict resolution: keep systembus-notify enabled for smartd / desktop alerts
    systembus-notify.enable = lib.mkForce true;

    # Explicitly disable conflicting power services (managed elsewhere)
    thermald.enable = lib.mkForce false;
    auto-cpufreq.enable = lib.mkForce false;

    # SSD TRIM support
    fstrim = {
      enable = lib.mkDefault true;
      interval = lib.mkDefault "weekly";
    };

    # SMART monitoring for disk health
    smartd = {
      enable = lib.mkDefault true;
      autodetect = true;
    };

    # Fail2ban for basic SSH/auth security
    fail2ban = {
      enable = lib.mkDefault true;
      maxretry = lib.mkDefault 3;
      bantime = lib.mkDefault "1h";
      bantime-increment.enable = true;
    };
  };
}
