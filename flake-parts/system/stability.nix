# flake-parts/system/stability.nix
# System stability, memory management, and maintenance
{ pkgs, lib, ... }:
{
  # Zram - compressed swap in RAM
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
    priority = 100;
  };

  # Kernel parameters for better memory management
  boot.kernel.sysctl = {
    "vm.swappiness" = 100;
    "vm.vfs_cache_pressure" = 100;
    "fs.inotify.max_user_watches" = 524288;
    "vm.dirty_ratio" = 10;
    "vm.dirty_background_ratio" = 5;
    "vm.oom_kill_allocating_task" = 1;
  };

  # Earlyoom - proactive OOM killer
  services.earlyoom = {
    enable = true;
    freeMemThreshold = 15;
    freeSwapThreshold = 15;
    enableNotifications = true;
    extraArgs = [
      "--prefer"
      "^(Web Content|chromium|firefox|electron)$"
      "--avoid"
      "^(Hyprland|quickshell|sshd|systemd)$"
    ];
  };

  # Fail2ban for basic security
  services.fail2ban = {
    enable = true;
    maxretry = 3;
    bantime = "1h";
    bantime-increment.enable = true;
  };

  # System maintenance
  services.fstrim = {
    enable = true;
    interval = "weekly";
  };

  # Smartd for disk monitoring
  services.smartd = {
    enable = true;
    autodetect = true;
  };

  # Conflict resolution: earlyoom wants systembus-notify, smartd disables it
  services.systembus-notify.enable = lib.mkForce true;

  # Cleanup /tmp weekly
  systemd.timers.clear-tmp = {
    description = "Clear /tmp weekly";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
    };
  };

  systemd.services.clear-tmp = {
    description = "Clear /tmp directory";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.coreutils}/bin/find /tmp -type f -atime +7 -delete";
    };
  };
}
