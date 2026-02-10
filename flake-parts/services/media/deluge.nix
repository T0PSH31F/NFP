{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.deluge-server;
in
{
  options.services.deluge-server = {
    enable = mkEnableOption "Deluge BitTorrent client";
    port = mkOption {
      type = types.port;
      default = 8113;
    };
  };

  config = mkIf cfg.enable {
    services.deluge = {
      enable = true;
      web = {
        enable = true;
        port = cfg.port;
      };
    };
    networking.firewall.allowedTCPPorts = [
      cfg.port
      58846
    ];

    systemd.tmpfiles.rules = [
      "Z /var/lib/deluge 0750 deluge deluge -"
    ];

    systemd.services.delugeweb.serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = "deluge";
      Group = "deluge";
    };
    systemd.services.deluged.serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = "deluge";
      Group = "deluge";
    };
  };
}
