# Jackett — API Support for Torrent Trackers
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.layers.layer-20.services.config.jackett;
in
{
  options.layers.layer-20.services.config.jackett = {
    enable = mkEnableOption "Jackett API support for torrent trackers";

    port = mkOption {
      type = types.port;
      default = 9117;
      description = "Port to listen on for Jackett Web UI and API";
    };
  };

  config = mkIf cfg.enable {
    services.jackett = {
      enable = true;
      inherit (cfg) port;
    };

    nfp.services.jackett = {
      enable = true;
      host = "luffy";
      bind = "127.0.0.1";
      inherit (cfg) port;
      tailnetName = "jackett";
      tls = "headscale";
      healthcheck = {
        enable = true;
        path = "/UI/Dashboard";
        expectedStatus = [
          200
          302
        ];
      };
      homepage = {
        enable = true;
        category = "vegapunk";
        order = 45;
        title = "Jackett";
        subtitle = "Edison — Tracker Gateway";
        icon = "jackett";
        satellite = "edison";
        metric = {
          mode = "health-only";
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
