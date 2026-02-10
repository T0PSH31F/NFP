{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.transmission-server;
in
{
  options.services.transmission-server = {
    enable = mkEnableOption "Transmission BitTorrent client";
    port = mkOption {
      type = types.port;
      default = 9091;
    };
  };

  config = mkIf cfg.enable {
    services.transmission = {
      enable = true;
      package = pkgs.transmission_4;
      settings = {
        rpc-bind-address = "0.0.0.0";
        rpc-port = cfg.port;
        rpc-whitelist-enabled = false;
      };
    };
    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
