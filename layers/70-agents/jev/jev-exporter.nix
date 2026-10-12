# Tier: 26-monitoring
# Module: jev-exporter.nix
# Purpose: Prometheus metrics exporter for Jev System-1 decision latency, confidence, and cost savings.
# Option Path: services.jev-exporter
# Enabling Host Tags: homelab, ai-server, monitoring
# RAM Footprint: minimal (<50MB)
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.jev-exporter;
in
{
  options.services.jev-exporter = {
    enable = lib.mkEnableOption "Jev Prometheus Metrics Exporter";

    port = lib.mkOption {
      type = lib.types.port;
      default = 20132;
      description = "Port to expose Prometheus metrics on";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      description = "Host address to bind the metrics server to";
    };

    jevUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://127.0.0.1:20130";
      description = "Endpoint URL of local Jev Decision Engine";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open metrics exporter port in firewall";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.jev-exporter = {
      description = "Jev Decision Engine Prometheus Metrics Exporter";
      after = [
        "network.target"
        "jev-engine.service"
      ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        JEV_EXPORTER_HOST = cfg.host;
        JEV_EXPORTER_PORT = toString cfg.port;
        JEV_ENGINE_URL = cfg.jevUrl;
        JEV_DATA_DIR = "/var/lib/jev-engine";
      };

      serviceConfig = {
        ExecStart = "${pkgs.python3}/bin/python3 ${./jev-exporter.py}";
        Restart = "on-failure";
        RestartSec = 5;
        DynamicUser = true;
        StateDirectory = "jev-engine";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];
  };
}
