# Netdata — Real-Time Infrastructure Performance Monitoring
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.layers.layer-20.services.config.netdata;
in
{
  options.layers.layer-20.services.config.netdata = {
    enable = mkEnableOption "Netdata real-time performance monitoring";

    port = mkOption {
      type = types.port;
      default = 19999;
      description = "Netdata web dashboard port";
    };
  };

  config = mkIf cfg.enable {
    services.netdata = {
      enable = true;
      config = {
        global = {
          "default port" = toString cfg.port;
          "bind socket to IP" = "127.0.0.1";
        };
      };
    };

    nfp.services.netdata = {
      enable = true;
      host = config.networking.hostName;
      bind = "127.0.0.1";
      inherit (cfg) port;
      tailnetName = "netdata";
      tls = "headscale";
      healthcheck = {
        enable = true;
        path = "/api/v1/info";
        expectedStatus = [ 200 ];
      };
      homepage = {
        enable = true;
        category = "chopper";
        order = 40;
        title = "Netdata";
        subtitle = "Real-Time Telemetry";
        icon = "netdata";
        metric = {
          mode = "health-only";
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
