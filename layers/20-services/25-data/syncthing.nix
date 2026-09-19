{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.layers.layer-20.services.config.syncthing;
in
{
  options.layers.layer-20.services.config.syncthing = {
    enable = mkEnableOption "Syncthing peer-to-peer directory synchronization";
    user = mkOption {
      type = types.str;
      default = "t0psh31f";
      description = "User account running Syncthing daemon";
    };
    dataDir = mkOption {
      type = types.str;
      default = "/home/t0psh31f";
      description = "Base data directory for Syncthing sync folders";
    };
    guiAddress = mkOption {
      type = types.str;
      default = "127.0.0.1:8384";
      description = "Address for local Syncthing Web UI";
    };
  };

  config = mkIf cfg.enable {
    nfp.services.syncthing = {
      enable = true;
      host = config.networking.hostName;
      bind = "127.0.0.1";
      port = 8384;
      tailnetName = "syncthing";
      tls = "headscale";
      healthcheck = {
        enable = true;
        path = "/rest/noauth/health";
        expectedStatus = [
          200
          401
          403
        ];
      };
      homepage = {
        enable = true;
        category = "luffy";
        order = 40;
        title = "Syncthing";
        subtitle = "P2P Treasure Mirror";
        icon = "syncthing";
        metric = {
          mode = "health-only";
        };
      };
    };

    services.syncthing = {
      enable = true;
      inherit (cfg) user;
      inherit (cfg) dataDir;
      configDir = "${cfg.dataDir}/.config/syncthing";
      inherit (cfg) guiAddress;
      overrideDevices = false; # Allow dynamic pairing via web UI
      overrideFolders = false;
    };

    # Firewall - open Syncthing listening ports for Tailscale mesh
    networking.firewall.allowedTCPPorts = [ 22000 ];
    networking.firewall.allowedUDPPorts = [
      22000
      21027
    ];

    # Impermanence persistence
    environment.persistence."/persist" =
      mkIf (config.layers.layer-10.system.config.impermanence.enable or false)
        {
          directories = optional (cfg.user == "syncthing") "/var/lib/syncthing";
          users.${cfg.user}.directories = [
            ".config/syncthing"
          ];
        };
  };
}
