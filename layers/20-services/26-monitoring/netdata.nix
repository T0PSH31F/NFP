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
          "bind socket to IP" = "0.0.0.0";
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];

    nfp.services.netdata = {
      enable = true;
      host = config.networking.hostName;
      bind = "0.0.0.0";
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
        title = "Netdata (${config.networking.hostName})";
        subtitle = "Real-Time Telemetry";
        icon = "netdata";
        metric = {
          mode = "health-only";
        };
      };
    };
  };
}
