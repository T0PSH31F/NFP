# Tier: 25-data
# Module: fs-organizer-daemon.nix
# Purpose: Autonomous filesystem staging organizer and proposal generator via Jev System-1 decision engine.
# Option Path: services.fs-organizer-daemon
# Enabling Host Tags: workstation, desktop, homelab
# RAM Footprint: light (<100MB)
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.fs-organizer-daemon;
  user = config.layers.meta.primaryUser or "t0psh31f";
in
{
  options.services.fs-organizer-daemon = {
    enable = lib.mkEnableOption "Jev Filesystem Organizer Daemon";

    watchDirs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "/home/${user}/Downloads"
        "/home/${user}/Inbox"
        "/home/${user}/Scans"
      ];
      description = "List of staging directories to monitor";
    };

    targetVaultRoot = lib.mkOption {
      type = lib.types.str;
      default = "/home/${user}/Vault";
      description = "Destination root path for organized vaults";
    };

    proposalFile = lib.mkOption {
      type = lib.types.str;
      default = "/home/${user}/.local/share/jev/fs-proposals.json";
      description = "Path to write dry-run / action proposals JSON";
    };

    trashDir = lib.mkOption {
      type = lib.types.str;
      default = "/home/${user}/.local/share/Trash";
      description = "Safe trash staging directory for ephemeral items";
    };

    jevUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://luffy.nfp.nix:20130";
      description = "Jev Engine URL";
    };

    dryRun = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Dry-run mode (generates proposals without relocating files)";
    };

    confidenceThreshold = lib.mkOption {
      type = lib.types.numbers.between 0.0 1.0;
      default = 0.80;
      description = "Threshold below which files are flagged for manual review";
    };

    interval = lib.mkOption {
      type = lib.types.str;
      default = "10m";
      description = "Systemd timer execution interval";
    };
  };

  config = lib.mkIf cfg.enable {
    # System CLI helper
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "jev-fs-organize" ''
        exec ${pkgs.python3}/bin/python3 ${./fs-organizer-daemon.py} \
          --watch-dirs ${lib.escapeShellArgs cfg.watchDirs} \
          --vault-root "${cfg.targetVaultRoot}" \
          --proposal-file "${cfg.proposalFile}" \
          --trash-dir "${cfg.trashDir}" \
          --jev-url "${cfg.jevUrl}" \
          --confidence-threshold "${toString cfg.confidenceThreshold}" \
          ${lib.optionalString cfg.dryRun "--dry-run"} \
          "$@"
      '')
    ];

    systemd.services.fs-organizer-daemon = {
      description = "Jev Filesystem Organizer Daemon";
      after = [ "network.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = user;
        ExecStart =
          let
            args = [
              "${pkgs.python3}/bin/python3"
              "${./fs-organizer-daemon.py}"
              "--watch-dirs"
            ]
            ++ cfg.watchDirs
            ++ [
              "--vault-root"
              cfg.targetVaultRoot
              "--proposal-file"
              cfg.proposalFile
              "--trash-dir"
              cfg.trashDir
              "--jev-url"
              cfg.jevUrl
              "--confidence-threshold"
              (toString cfg.confidenceThreshold)
            ]
            ++ lib.optional cfg.dryRun "--dry-run";
          in
          "${lib.concatStringsSep " " args}";
        Restart = "no";
        PrivateTmp = true;
      };
    };

    systemd.timers.fs-organizer-daemon = {
      description = "Jev Filesystem Organizer Periodic Timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "3m";
        OnUnitActiveSec = cfg.interval;
        Persistent = true;
      };
    };
  };
}
