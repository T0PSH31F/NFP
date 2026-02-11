# modules/nixos/nix-settings.nix
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

let
  # Extra binary caches to accelerate builds during refactor
  extraSubstituters = [
    "https://cache.nixos.org"
    "https://nix-community.cachix.org"
    "https://hyprland.cachix.org"
    "https://numtide.cachix.org"
    "https://mic92.cachix.org"
    "https://vicinae.cachix.org"
    "https://cuda-maintainers.cachix.org"
    "https://niri.cachix.org"
  ];

  extraTrustedKeys = [
    # Official NixOS cache
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="

    # Nix community (sops-nix, disko, etc.)
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="

    # Hyprland cache (Wayland compositor)
    "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="

    # Numtide (common dev tooling)
    "numtide.cachix.org-1:vSxzZPSh9OCpqJc572Mk9BdbrGMNSbR4F5O4/jVtHK8="

    # Mic92’s cache (sops-nix maintainer, infra tools)
    "mic92.cachix.org-1:2Vf2WbWuQDWg9s2ykt8ZzNt6gtB+oqjEUo3vAqVM0GA="

    # Other existing caches
    "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
    "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNq7Ow="
    "niri.cachix.org-1:Xv07V9KiYFrQ4qXvpxN6vH/AnU01A+E+S7OfYmR7jYg="
  ];
in
{
  # Nix daemon core settings
  nix = {
    settings = {
      # Binary caches (order matters)
      substituters = lib.mkDefault extraSubstituters;

      # Keys for verifying cache signatures
      trusted-public-keys = lib.mkDefault extraTrustedKeys;

      # CRITICAL: Build resource limits for 16GB RAM system
      max-jobs = lib.mkDefault 4; # Limit parallel jobs to 4
      cores = lib.mkDefault 2; # Max 2 cores per job
      # Let Nix decide per-job threads, respecting 'cores'
      build-cores = lib.mkDefault 0;

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

      # Store optimization
      auto-optimise-store = lib.mkDefault true;

      # CRITICAL: Fix "download buffer is full" warnings for large files
      download-buffer-size = lib.mkDefault 134217728; # 128MB (Default is 64MB)

      # Keep some free disk space thresholds (bytes)
      min-free = lib.mkForce 1073741824; # 1GiB
      max-free = lib.mkForce 5368709120; # 5GiB
    };

    # Automatic garbage collection
    gc = {
      automatic = lib.mkDefault true;
      dates = lib.mkDefault "weekly";
      options = lib.mkDefault "--delete-older-than 30d";
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
