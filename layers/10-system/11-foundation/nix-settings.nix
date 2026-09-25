# layers/nixos/nix-settings.nix
# Purpose:
# - Configure Nix daemon resource limits (CPU, RAM)
# - Configure binary caches (extra substituters)
# - Enable flakes and new nix command
# - Set up automatic GC/optimization
# Notes:
# - This module is designed to be imported by ALL machines.

{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Nix daemon core settings
  nix = {
    settings = {
      # CRITICAL: Build resource limits for 16GB RAM system
      max-jobs = lib.mkDefault 4; # Limit parallel jobs to 4
      cores = lib.mkDefault 2; # Max 2 cores per job

      # Trusted users allowed to manage store
      trusted-users = lib.mkDefault [
        "root"
        "@wheel"
        "t0psh31f"
      ];

      # Enable flakes + new CLI
      experimental-features = lib.mkDefault [
        "nix-command"
        "flakes"
      ];
      accept-flake-config = lib.mkDefault true;

      connect-timeout = lib.mkDefault 5; # fail fast on dead caches (numtide, etc.)

      # Store optimization
      auto-optimise-store = lib.mkDefault true;

      # CRITICAL: Fix "download buffer is full" warnings for large files
      download-buffer-size = lib.mkDefault 536870912; # 512MB (Default is 64MB)

      # Keep some free disk space thresholds (bytes)
      min-free = lib.mkForce 1073741824; # 1GiB
      max-free = lib.mkForce 5368709120; # 5GiB
    };

    # Automatic garbage collection
    gc = {
      automatic = lib.mkDefault true;
      dates = lib.mkDefault "weekly";
      options = lib.mkDefault "--delete-older-than 7d";
    };

    # Automatic store optimization
    optimise = {
      automatic = lib.mkDefault true;
      dates = lib.mkDefault [ "weekly" ];
    };
  };

  # Systemd resource limits for nix-daemon
  # Keeps builds from eating all RAM/CPU
  systemd.services.nix-daemon = {
    serviceConfig = {
      # CPU: limit to ~3 cores total
      CPUQuota = lib.mkDefault "300%";
      CPUWeight = lib.mkDefault 50; # Lower priority vs interactive tasks

      # Memory: cap at 8GB hard, 6GB soft
      MemoryMax = lib.mkDefault "8G";
      MemoryHigh = lib.mkDefault "6G";

      # Some swap allowed, but not excessive
      MemorySwapMax = lib.mkDefault "2G";

      # Lower IO priority
      IOWeight = lib.mkDefault 100;

      # Reasonable task limit
      TasksMax = lib.mkDefault 1000;

      # Lower scheduling priority
      Nice = lib.mkDefault 10;
    };
  };
}
