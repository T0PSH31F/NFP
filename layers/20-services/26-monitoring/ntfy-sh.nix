# ntfy.sh — Send push notifications to your phone or desktop
# https://ntfy.sh
#
# Lightweight notification service. Can be used with Grafana, Prometheus,
# Hermes Agent, and other services for alerts.
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.layers.layer-20.services.config.ntfy-sh;
in
{
  options.layers.layer-20.services.config.ntfy-sh = {
    enable = mkEnableOption "ntfy.sh — push notification service";

    port = mkOption {
      type = types.port;
      default = 8099;
      description = "Port for ntfy HTTP server";
    };

    baseUrl = mkOption {
      type = types.str;
      default = "https://ntfy.sh";
      description = "Base URL for ntfy (use self-hosted URL if applicable)";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/ntfy";
      description = "Data directory for ntfy";
    };
  };

  config = mkIf cfg.enable {
    nfp.services.ntfy = {
      enable = true;
      host = config.networking.hostName;
      bind = "127.0.0.1";
      inherit (cfg) port;
      tailnetName = "ntfy";
      tls = "headscale";
      healthcheck = {
        enable = true;
        path = "/v1/health";
        expectedStatus = [ 200 ];
      };
      homepage = {
        enable = true;
        category = "chopper";
        order = 30;
        title = "ntfy";
        subtitle = "Transponder Snail Signal";
        icon = "ntfy";
        metric = {
          mode = "health-only";
        };
      };
    };

    # ntfy systemd service
    systemd.services.ntfy-sh = {
      description = "ntfy.sh push notification service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${pkgs.ntfy-sh}/bin/ntfy serve --config ${pkgs.writeText "ntfy.yml" ''
          base-url: ${cfg.baseUrl}
          listen-http: ":${toString cfg.port}"
          cache-file: "${cfg.dataDir}/cache.db"
          cache-duration: "24h"
          auth-file: "${cfg.dataDir}/user.db"
          auth-default-access: "read-write"
          behind-proxy: true
        ''}";
        Restart = "always";
        RestartSec = 5;
        StateDirectory = "ntfy";
      };
    };

    # Data directory
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 root root -"
    ];

    # Open firewall port
    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
