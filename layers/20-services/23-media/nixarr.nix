# layers/20-services/23-media/nixarr.nix
# Declarative nixarr media server stack module for NFP.

{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.layers.layer-20.services.config.nixarr-stack;
in
{
  options.layers.layer-20.services.config.nixarr-stack = {
    enable = mkEnableOption "nixarr unified media server stack";

    mediaDir = mkOption {
      type = types.str;
      default = "/data/media";
      description = "Root media library directory owned by root.";
    };

    stateDir = mkOption {
      type = types.str;
      default = "/data/.state/nixarr";
      description = "State directory for nixarr service persistence.";
    };

    mediaUsers = mkOption {
      type = types.listOf types.str;
      default = [ "t0psh31f" ];
      description = "Human user accounts granted access to media directories.";
    };
  };

  config = mkIf cfg.enable {
    # NixOS Nixarr module options
    nixarr = {
      enable = true;
      inherit (cfg) mediaDir stateDir mediaUsers;

      jellyfin.enable = true;
      komga.enable = true;
      audiobookshelf.enable = true;
      seerr.enable = true;
      lidarr.enable = true;
      bazarr.enable = true;
      recyclarr = {
        enable = true;
        configFile = "${cfg.stateDir}/recyclarr/recyclarr.yml";
      };
      qbittorrent.enable = true;
      sabnzbd.enable = true;
      autobrr.enable = true;
      anchorr.enable = true;
      shelfmark.enable = true;
      sonarr.enable = true;
      radarr.enable = true;
      prowlarr.enable = true;

      plex.enable = false; # Explicitly disabled (conflicts with Jellyfin)
    };

    # Override upstream nixarr setting deprecated services.sabnzbd.configFile
    services.sabnzbd.configFile = mkForce null;

    # Declarative nfp.services contracts for nixarr media services
    nfp.services = {
      jellyfin = {
        enable = true;
        host = "luffy";
        bind = "127.0.0.1";
        port = 8096;
        tailnetName = "jellyfin";
        tls = "headscale";
        backup.paths = [ "${cfg.stateDir}/jellyfin" ];
        homepage = {
          enable = true;
          category = "vegapunk";
          order = 10;
          title = "Jellyfin";
          subtitle = "Stella — Genius Center";
          icon = "jellyfin";
          satellite = "stella";
          metric = {
            mode = "native-api";
            adapter = "jellyfin";
            fields = [
              "activeStreams"
              "movies"
              "series"
              "musicAlbums"
            ];
          };
        };
      };

      komga = {
        enable = true;
        host = "luffy";
        bind = "127.0.0.1";
        port = 25600;
        tailnetName = "komga";
        tls = "headscale";
        backup.paths = [ "${cfg.stateDir}/komga" ];
        homepage = {
          enable = true;
          category = "robin";
          order = 10;
          title = "Komga";
          subtitle = "Manga Scrolls Archive";
          icon = "komga";
          metric = {
            mode = "health-only";
          };
        };
      };

      audiobookshelf = {
        enable = true;
        host = "luffy";
        bind = "127.0.0.1";
        port = 9292;
        tailnetName = "audiobookshelf";
        tls = "headscale";
        backup.paths = [ "${cfg.stateDir}/audiobookshelf" ];
        homepage = {
          enable = true;
          category = "robin";
          order = 20;
          title = "Audiobookshelf";
          subtitle = "Ancient Audio Archives";
          icon = "audiobookshelf";
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

      sonarr = {
        enable = true;
        host = "luffy";
        bind = "127.0.0.1";
        port = 8989;
        tailnetName = "sonarr";
        tls = "headscale";
        backup.paths = [ "${cfg.stateDir}/sonarr" ];
        homepage = {
          enable = true;
          category = "vegapunk";
          order = 20;
          title = "Sonarr";
          subtitle = "Shaka — Good";
          icon = "sonarr";
          satellite = "shaka";
          metric = {
            mode = "native-api";
            adapter = "sonarr";
            fields = [
              "series"
              "episodes"
            ];
          };
        };
        healthcheck = {
          enable = true;
          path = "/";
          expectedStatus = [
            200
            401
          ];
        };
      };

      radarr = {
        enable = true;
        host = "luffy";
        bind = "127.0.0.1";
        port = 7878;
        tailnetName = "radarr";
        tls = "headscale";
        backup.paths = [ "${cfg.stateDir}/radarr" ];
        homepage = {
          enable = true;
          category = "vegapunk";
          order = 30;
          title = "Radarr";
          subtitle = "Lilith — Evil";
          icon = "radarr";
          satellite = "lilith";
          metric = {
            mode = "native-api";
            adapter = "radarr";
            fields = [ "movies" ];
          };
        };
      };

      prowlarr = {
        enable = true;
        host = "luffy";
        bind = "127.0.0.1";
        port = 9696;
        tailnetName = "prowlarr";
        tls = "headscale";
        backup.paths = [ "${cfg.stateDir}/prowlarr" ];
        homepage = {
          enable = true;
          category = "vegapunk";
          order = 40;
          title = "Prowlarr";
          subtitle = "Edison — Thinking";
          icon = "prowlarr";
          satellite = "edison";
          metric = {
            mode = "native-api";
            adapter = "prowlarr";
            fields = [ "indexers" ];
          };
        };
      };

      seerr = {
        enable = true;
        host = "luffy";
        bind = "127.0.0.1";
        port = 5055;
        tailnetName = "seerr";
        tls = "headscale";
        backup.paths = [ "${cfg.stateDir}/seerr" ];
        homepage = {
          enable = true;
          category = "vegapunk";
          order = 50;
          title = "Overseerr";
          subtitle = "York — Greed";
          icon = "overseerr";
          satellite = "york";
          metric = {
            mode = "native-api";
            adapter = "seerr";
            fields = [ "requests" ];
          };
        };
      };

      qbittorrent = {
        enable = true;
        host = "luffy";
        bind = "127.0.0.1";
        port = 8085;
        tailnetName = "qbittorrent";
        tls = "headscale";
        backup.paths = [ "${cfg.stateDir}/qbittorrent" ];
        homepage = {
          enable = true;
          category = "vegapunk";
          order = 60;
          title = "qBittorrent";
          subtitle = "Pythagoras — Wisdom";
          icon = "qbittorrent";
          satellite = "pythagoras";
          metric = {
            mode = "native-api";
            adapter = "qbittorrent";
            fields = [
              "torrentCount"
              "dlSpeed"
              "ulSpeed"
            ];
          };
        };
      };
    };

    # Impermanence state persistence for nixarr state directory
    environment.persistence."/persist" =
      mkIf (config.layers.layer-10.system.config.impermanence.enable or false)
        {
          directories = [
            cfg.stateDir
          ];
        };
  };
}
