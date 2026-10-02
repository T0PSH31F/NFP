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
      overrideDevices = true;
      overrideFolders = true;
      settings = {
        devices = {
          z0r0 = {
            id = "CNKR6GT-LSK37DB-H7YITY3-6OAKL4M-G47BYXJ-XXGFFPA-AGBVURA-EYD3LQK";
            addresses = [
              "tcp://127.0.0.1:22000"
              "tcp://z0r0.nfp.nix:22000"
              "dynamic"
            ];
          };
          luffy = {
            id = "CT4EUD2-FDYRUL4-REEEGPF-NK7VXO5-PWBWKXJ-7KBUVHD-GM4GG2Q-G7DK5AZ";
            addresses = [
              "tcp://luffy.nfp.nix:22000"
              "tcp://192.168.1.54:22000"
              "dynamic"
            ];
          };
        };
        folders = {
          "clan-vault" = {
            path = "${cfg.dataDir}/Clan";
            devices = [
              "z0r0"
              "luffy"
            ];
            label = "Clan Vault";
            ignorePerms = false;
            rescanIntervalS = 60;
          };
          "projects-vault" = {
            path = "${cfg.dataDir}/Projects";
            devices = [
              "z0r0"
              "luffy"
            ];
            label = "Projects Vault";
            ignorePerms = false;
            rescanIntervalS = 60;
          };
        };
      };
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
