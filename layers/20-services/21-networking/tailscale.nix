{
  config,
  lib,
  ...
}:
let
  cfg = config.layers.layer-20.services.config.tailscale;
in
{
  options.layers.layer-20.services.config.tailscale = {
    enable = lib.mkEnableOption "Tailscale client";
    loginServer = lib.mkOption {
      type = lib.types.str;
      default = "https://headscale.lovelain.duckdns.org";
      description = "Headscale login server URL for fleet-wide Tailscale authentication";
    };
    authKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to file containing Headscale pre-authenticated authkey";
    };
  };

  config = lib.mkIf cfg.enable {
    # Shared Tailscale client configuration for the fleet
    services.tailscale = {
      enable = true;
      inherit (cfg) authKeyFile;
      extraUpFlags = [ "--login-server=${cfg.loginServer}" ];
    };

    # Open UDP port 41641 for peer-to-peer Tailscale connections
    networking.firewall.allowedUDPPorts = [ 41641 ];
  };
}
