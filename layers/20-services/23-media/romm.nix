# RomM — ROM Manager & Emulator Web Interface
# Containerized via Podman on port 8098
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.layers.layer-20.services.config.romm;
in
{
  options.layers.layer-20.services.config.romm = {
    enable = mkEnableOption "RomM — Web-based ROM Manager";

    port = mkOption {
      type = types.port;
      default = 8098;
      description = "Port to expose RomM on";
    };

    romsDir = mkOption {
      type = types.str;
      default = "/var/lib/romm/roms";
      description = "Path to ROM files directory";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/romm/data";
      description = "Path to RomM application state and DB";
    };
  };

  config = mkIf cfg.enable {
    nfp.services.romm = {
      enable = true;
      host = config.networking.hostName;
      bind = "127.0.0.1";
      inherit (cfg) port;
      tailnetName = "romm";
      tls = "headscale";
      healthcheck = {
        enable = true;
        path = "/";
        expectedStatus = [
          200
          302
        ];
      };
      homepage = {
        enable = true;
        category = "vegapunk";
        order = 30;
        title = "RomM";
        subtitle = "Atlas — Retro Memory Station";
        icon = "romm";
        satellite = "atlas";
        metric = {
          mode = "health-only";
        };
      };
    };

    virtualisation.oci-containers.containers.romm = {
      image = "ghcr.io/rommapp/romm:latest";
      autoStart = true;
      ports = [ "${toString cfg.port}:8080" ];
      environment = {
        DB_DRIVER = "sqlite";
      };
      volumes = [
        "${cfg.romsDir}:/romm/roms"
        "${cfg.dataDir}:/romm/resources"
      ];
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.romsDir} 0755 root root -"
      "d ${cfg.dataDir} 0755 root root -"
    ];

    networking.firewall.allowedTCPPorts = [ cfg.port ];

    environment.persistence."/persist" =
      mkIf (config.layers.layer-10.system.config.impermanence.enable or false)
        {
          directories = [ "/var/lib/romm" ];
        };
  };
}
