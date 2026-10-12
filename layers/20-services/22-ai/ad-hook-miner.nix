# Tier: 22-ai
# Module: ad-hook-miner.nix
# Purpose: High-volume competitor ad hook and market intelligence batch miner via Jev System-1.
# Option Path: services.ad-hook-miner
# Enabling Host Tags: homelab, ai-server
# RAM Footprint: light (<200MB)
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.ad-hook-miner;
in
{
  options.services.ad-hook-miner = {
    enable = lib.mkEnableOption "Jev Ad Hook & Market Intelligence Miner";

    inboxDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/ad-miner/inbox";
      description = "Directory where raw CSVs, RSS, and ad dumps are staged";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/ad-miner/data";
      description = "Output directory for structured ad hook JSONL datasets";
    };

    reportsDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/ad-miner/reports";
      description = "Output directory for generated daily Markdown intelligence reports";
    };

    jevUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://127.0.0.1:20130";
      description = "Endpoint URL for local Jev decision engine";
    };

    concurrency = lib.mkOption {
      type = lib.types.int;
      default = 8;
      description = "Worker pool concurrency for streaming Jev decisions";
    };

    interval = lib.mkOption {
      type = lib.types.str;
      default = "30m";
      description = "Systemd timer execution interval";
    };
  };

  config = lib.mkIf cfg.enable {
    # System CLI helper
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "jev-ad-miner" ''
        exec ${pkgs.python3}/bin/python3 ${./ad-hook-miner.py} \
          --inbox "${toString cfg.inboxDir}" \
          --data-dir "${toString cfg.dataDir}" \
          --reports-dir "${toString cfg.reportsDir}" \
          --jev-url "${cfg.jevUrl}" \
          --concurrency "${toString cfg.concurrency}" \
          "$@"
      '')
    ];

    systemd.services.ad-hook-miner = {
      description = "Jev High-Volume Ad Hook & Market Intelligence Miner";
      after = [
        "network.target"
        "jev-engine.service"
      ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart =
          let
            args = [
              "${pkgs.python3}/bin/python3"
              "${./ad-hook-miner.py}"
              "--inbox"
              (toString cfg.inboxDir)
              "--data-dir"
              (toString cfg.dataDir)
              "--reports-dir"
              (toString cfg.reportsDir)
              "--jev-url"
              cfg.jevUrl
              "--concurrency"
              (toString cfg.concurrency)
            ];
          in
          "${lib.concatStringsSep " " args}";
        Restart = "no";
        DynamicUser = true;
        StateDirectory = "ad-miner";
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
      };
    };

    systemd.timers.ad-hook-miner = {
      description = "Jev Ad Hook Miner Periodic Timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5m";
        OnUnitActiveSec = cfg.interval;
        Persistent = true;
      };
    };

    environment.persistence."/persist" =
      lib.mkIf (config.layers.layer-10.system.config.impermanence.enable or false)
        {
          directories = [
            {
              directory = "/var/lib/ad-miner";
              mode = "0750";
            }
          ];
        };
  };
}
