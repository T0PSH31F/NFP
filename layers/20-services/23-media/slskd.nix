# Tier: 20-services / 23-media
# Module: slskd.nix
# Purpose: slskd modern Soulseek network daemon & web client for audio acquisition.
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.layers.layer-20.services.media.slskd;
in
{
  options.layers.layer-20.services.media.slskd = {
    enable = mkEnableOption "slskd - Soulseek daemon & web interface";

    port = mkOption {
      type = types.port;
      default = 5030;
      description = "Port for the slskd Web UI";
    };

    listenPort = mkOption {
      type = types.port;
      default = 50300;
      description = "Soulseek peer network listen port";
    };

    musicFolder = mkOption {
      type = types.str;
      default = "/persist/home/t0psh31f/Music";
      description = "Path to shared music library";
    };

    downloadFolder = mkOption {
      type = types.str;
      default = "/persist/home/t0psh31f/Music/Downloads";
      description = "Path to completed downloads directory";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = true;
      description = "Open firewall ports for Web UI and Soulseek peer connection";
    };

    environmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Optional environment file for SLSKD credentials (SLSKD_SLSK_USERNAME, SLSKD_SLSK_PASSWORD)";
    };
  };

  config = mkIf cfg.enable {
    services.slskd = {
      enable = true;
      openFirewall = cfg.openFirewall;
      environmentFile =
        if (cfg.environmentFile != null) then cfg.environmentFile else pkgs.writeText "slskd.env" "";
      settings = {
        web.port = cfg.port;
        soulseek.listen_port = cfg.listenPort;
        directories = {
          downloads = cfg.downloadFolder;
          incomplete = "${cfg.downloadFolder}/incomplete";
        };
        shares = {
          directories = [ cfg.musicFolder ];
        };
        flags = {
          no_version_check = true;
        };
      };
    };

    # Open the Web UI port explicitly if firewall is opened
    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [
      cfg.port
      cfg.listenPort
    ];

    # Relax systemd sandboxing for /persist/home paths
    systemd.services.slskd.serviceConfig = {
      ProtectHome = lib.mkForce "read-only";
      ReadWritePaths = [
        cfg.musicFolder
        cfg.downloadFolder
        "/var/lib/slskd"
      ];
    };

    users.users.slskd.extraGroups = [ "users" ];

    # Register in Homepage dashboard
    nfp.services.slskd = {
      enable = true;
      host = config.networking.hostName;
      port = cfg.port;
      homepage = {
        enable = true;
        category = "brook";
        order = 22;
        title = "slskd";
        subtitle = "Soulseek Network Gateway";
        icon = "slskd";
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
