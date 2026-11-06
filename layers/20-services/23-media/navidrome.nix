# Tier: 20-services / 23-media
# Module: navidrome.nix
# Purpose: Navidrome lightweight self-hosted Spotify replacement / OpenSubsonic music streaming server.
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.layers.layer-20.services.media.navidrome;
in
{
  options.layers.layer-20.services.media.navidrome = {
    enable = mkEnableOption "Navidrome music server";

    port = mkOption {
      type = types.port;
      default = 4533;
      description = "Port to expose Navidrome on";
    };

    musicFolder = mkOption {
      type = types.str;
      default = "/persist/home/t0psh31f/Music";
      description = "Path to music library";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = true;
      description = "Open port in firewall (Tailscale and local)";
    };
  };

  config = mkIf cfg.enable {
    services.navidrome = {
      enable = true;
      openFirewall = cfg.openFirewall;
      settings = {
        Address = "0.0.0.0";
        Port = cfg.port;
        MusicFolder = cfg.musicFolder;
        ScanSchedule = "@every 1h";
        Transcoding = {
          Enable = true;
        };
      };
    };

    # Ensure navidrome user can access music folder under impermanence/home
    systemd.services.navidrome.serviceConfig = {
      ProtectHome = lib.mkForce "read-only";
    };

    users.users.navidrome.extraGroups = [ "users" ];

    # Register in Homepage dashboard if enabled
    nfp.services.navidrome = {
      enable = true;
      host = config.networking.hostName;
      port = cfg.port;
      homepage = {
        enable = true;
        category = "brook";
        order = 10;
        title = "Navidrome";
        subtitle = "Soul King Audio Cloud";
        icon = "navidrome";
        metric = {
          mode = "health-only";
        };
      };
      healthcheck = {
        enable = true;
        path = "/ping";
        expectedStatus = [ 200 ];
      };
    };
  };
}
