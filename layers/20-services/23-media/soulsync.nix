# Tier: 20-services / 23-media
# Module: soulsync.nix
# Purpose: SoulSync automated music acquisition, playlist sync, and metadata enricher (connecting Navidrome, Jellyfin, and slskd).
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.layers.layer-20.services.media.soulsync;
in
{
  options.layers.layer-20.services.media.soulsync = {
    enable = mkEnableOption "SoulSync media library automator";

    port = mkOption {
      type = types.port;
      default = 8008;
      description = "Port to expose SoulSync Web UI";
    };

    musicFolder = mkOption {
      type = types.str;
      default = "/persist/home/t0psh31f/Music";
      description = "Path to music library on the host";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/soulsync";
      description = "State directory for SoulSync configuration and logs";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = true;
      description = "Open port in firewall";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.backend = "podman";

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0775 1000 users -"
      "d ${cfg.dataDir}/config 0775 1000 users -"
      "d ${cfg.dataDir}/logs 0775 1000 users -"
    ];

    virtualisation.oci-containers.containers.soulsync = {
      image = "docker.io/boulderbadgedad/soulsync:latest";
      autoStart = true;
      ports = [
        "${toString cfg.port}:8008"
        "8888:8888"
        "8889:8889"
      ];
      volumes = [
        "${cfg.dataDir}/config:/app/config:Z"
        "${cfg.dataDir}/logs:/app/logs:Z"
        "${cfg.musicFolder}:/music:Z"
      ];
      environment = {
        PUID = "1000";
        PGID = "100";
        UMASK = "002";
        TZ = config.time.timeZone or "America/Los_Angeles";
      };
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [
      cfg.port
      8888
      8889
    ];

    # Register in Homepage dashboard
    nfp.services.soulsync = {
      enable = true;
      host = config.networking.hostName;
      port = cfg.port;
      homepage = {
        enable = true;
        category = "brook";
        order = 23;
        title = "SoulSync";
        subtitle = "Soul King Stream & Sync Automator";
        icon = "soulsync";
        metric = {
          mode = "health-only";
        };
      };
      healthcheck = {
        enable = true;
        path = "/";
        expectedStatus = [
          200
          302
        ];
      };
    };
  };
}
