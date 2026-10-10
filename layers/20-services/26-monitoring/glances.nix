{ config, lib, ... }:
with lib;
let
  cfg = config.services.glances-server;
in
{
  options.services.glances-server = {
    enable = mkEnableOption "Glances system monitoring";
    port = mkOption {
      type = types.port;
      default = 61208;
    };
  };

  config = mkIf cfg.enable {
    nfp.services.glances = {
      enable = true;
      host = config.networking.hostName;
      bind = "127.0.0.1";
      inherit (cfg) port;
      tailnetName = "glances";
      tls = "headscale";
      healthcheck = {
        enable = true;
        path = "/api/3/quicklook";
        expectedStatus = [
          200
        ];
      };
      homepage = {
        enable = true;
        category = "luffy";
        order = 50;
        title = "Glances";
        subtitle = "Ship Status Monitor";
        icon = "glances";
        metric = {
          mode = "native-api";
          adapter = "glances";
          fields = [
            "cpu"
            "ram"
            "net"
          ];
        };
      };
    };

    services.glances = {
      enable = true;
      openFirewall = true;
      extraArgs = [
        "-w"
        "--bind"
        "0.0.0.0"
      ];
    };
  };
}
