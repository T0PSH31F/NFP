# Tier: 74-ai-infra
# Module: jev-engine.nix
# Purpose: High-speed System-1 discriminative classifier and routing service.
# Option Path: services.jev-engine
# Enabling Host Tags: homelab, ai-server
# RAM Footprint: light (<200MB)
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.jev-engine;
in
{
  options.services.jev-engine = {
    enable = lib.mkEnableOption "Jev System-1 Decision Engine & Discriminative Routing Daemon";

    port = lib.mkOption {
      type = lib.types.port;
      default = 20130;
      description = "HTTP API port bound on Tailnet";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      description = "Host IP to bind the daemon to";
    };

    mode = lib.mkOption {
      type = lib.types.enum [
        "local"
        "typesafe-proxy"
      ];
      default = "local";
      description = "Execution mode: local discriminative joint-embedding scoring or TypeSafe API client proxy";
    };

    upstreamUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Upstream TypeSafe/Jev API endpoint when mode is 'typesafe-proxy'";
    };

    apiKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to file containing TypeSafe API key for proxy authorization";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open port in firewall";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.jev-engine = {
      description = "Jev System-1 Decision Engine";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        JEV_HOST = cfg.host;
        JEV_PORT = toString cfg.port;
        JEV_MODE = cfg.mode;
      }
      // (lib.optionalAttrs (cfg.upstreamUrl != null) {
        JEV_UPSTREAM_URL = cfg.upstreamUrl;
      })
      // (lib.optionalAttrs (cfg.apiKeyFile != null) {
        JEV_API_KEY_FILE = toString cfg.apiKeyFile;
      });

      serviceConfig = {
        ExecStart = "${pkgs.python3}/bin/python3 ${./jev-engine.py}";
        Restart = "on-failure";
        RestartSec = 5;
        NoNewPrivileges = true;
        PrivateTmp = true;
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];

    environment.persistence."/persist" =
      lib.mkIf (config.layers.layer-10.system.config.impermanence.enable or false)
        {
          directories = [
            {
              directory = "/var/lib/jev-engine";
              mode = "0750";
            }
          ];
        };
  };
}
