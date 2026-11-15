# Tier: 24-communication
# Module: email-triage-daemon.nix
# Purpose: Autonomous Maildir/IMAP triage daemon using Jev System-1 decision engine.
# Option Path: services.email-triage-daemon
# Enabling Host Tags: communication, workstation, homelab
# RAM Footprint: light (<100MB)
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.email-triage-daemon;
  user = config.layers.meta.primaryUser or "t0psh31f";
in
{
  options.services.email-triage-daemon = {
    enable = lib.mkEnableOption "Jev Email Triage Daemon";

    maildir = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to local Maildir directory. If null, automatically scans standard paths.";
    };

    himalayaAccount = lib.mkOption {
      type = lib.types.str;
      default = "wrighterik77,lovelainautomations";
      description = "Comma-separated Himalaya email account name(s)";
    };

    jevUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://luffy.nfp.nix:20130";
      description = "Jev Engine URL";
    };

    interval = lib.mkOption {
      type = lib.types.str;
      default = "5m";
      description = "Systemd timer execution interval";
    };

    dryRun = lib.mkEnableOption "dry run mode (logs decisions without modifying message flags)";

    confidenceThreshold = lib.mkOption {
      type = lib.types.numbers.between 0.0 1.0;
      default = 0.80;
      description = "Threshold below which messages are flagged for LLM/human escalation";
    };
  };

  config = lib.mkIf cfg.enable {
    # System CLI helper
    environment.systemPackages = [
      pkgs.himalaya
      (pkgs.writeShellScriptBin "jev-email-triage" ''
        exec ${pkgs.python3}/bin/python3 ${./email-triage-daemon.py} \
          --jev-url "${cfg.jevUrl}" \
          --himalaya-account "${cfg.himalayaAccount}" \
          --confidence-threshold "${toString cfg.confidenceThreshold}" \
          ${lib.optionalString (cfg.maildir != null) "--maildir \"${toString cfg.maildir}\""} \
          ${lib.optionalString cfg.dryRun "--dry-run"} \
          "$@"
      '')
    ];

    # Periodic background triage runner
    systemd.services.email-triage-daemon = {
      description = "Jev Email Triage Daemon";
      after = [ "network.target" ];
      path = [
        pkgs.himalaya
        pkgs.coreutils
        pkgs.bash
        pkgs.python3
        pkgs.libnotify
        pkgs.pipewire
        pkgs.util-linux
      ];
      environment = {
        XDG_RUNTIME_DIR = "/run/user/1000";
        DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/1000/bus";
        PIPEWIRE_RUNTIME_DIR = "/run/user/1000";
      };
      serviceConfig = {
        Type = "oneshot";
        User = user;
        ExecStart =
          let
            args = [
              "${pkgs.python3}/bin/python3"
              "${./email-triage-daemon.py}"
              "--jev-url"
              cfg.jevUrl
              "--himalaya-account"
              cfg.himalayaAccount
              "--confidence-threshold"
              (toString cfg.confidenceThreshold)
            ]
            ++ lib.optional (cfg.maildir != null) "--maildir ${toString cfg.maildir}"
            ++ lib.optional cfg.dryRun "--dry-run";
          in
          "${lib.concatStringsSep " " args}";
        Restart = "no";
        PrivateTmp = true;
      };
    };

    systemd.timers.email-triage-daemon = {
      description = "Jev Email Triage Periodic Timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "2m";
        OnUnitInactiveSec = cfg.interval;
        Persistent = true;
      };
    };
  };
}
