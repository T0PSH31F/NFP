# alertmanager-ntfy — Forward Prometheus Alertmanager notifications to ntfy.sh
# https://github.com/alexbakker/alertmanager-ntfy
#
# Bridges Prometheus alerts to ntfy for push notifications.
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.alertmanager-ntfy;
in
{
  options.services.alertmanager-ntfy = {
    enable = mkEnableOption "alertmanager-ntfy — Prometheus alerts to ntfy";

    ntfyUrl = mkOption {
      type = types.str;
      default = "http://localhost:8099";
      description = "ntfy server URL";
    };

    ntfyTopic = mkOption {
      type = types.str;
      default = "prometheus-alerts";
      description = "ntfy topic for alerts";
    };

    alertmanagerUrl = mkOption {
      type = types.str;
      default = "http://localhost:9093";
      description = "Prometheus Alertmanager URL";
    };

    port = mkOption {
      type = types.port;
      default = 8094;
      description = "HTTP listen port for alertmanager-ntfy webhook receiver (avoids :8000 collision with honcho-api)";
    };
  };

  config = mkIf cfg.enable {
    # alertmanager-ntfy service
    systemd.services.alertmanager-ntfy =
      let
        configFile = pkgs.writeText "alertmanager-ntfy-config.yml" ''
          ntfy:
            url: "${cfg.ntfyUrl}"
            topic: "${cfg.ntfyTopic}"
        '';
      in
      {
        description = "alertmanager-ntfy — Prometheus alerts to ntfy";
        after = [
          "network.target"
          "alertmanager.service"
          "ntfy-sh.service"
        ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          ExecStart = "${pkgs.alertmanager-ntfy}/bin/alertmanager-ntfy --http-addr 127.0.0.1:${toString cfg.port} --configs ${configFile} --ntfy-baseurl ${cfg.ntfyUrl} --ntfy-topic ${cfg.ntfyTopic}";
          Restart = "always";
          RestartSec = 5;
        };
      };

    # Grafana notification channel for ntfy
    # Configure in Grafana UI: Alerting → Contact Points → New → ntfy
    # URL: ${cfg.ntfyUrl}/${cfg.ntfyTopic}
  };
}
