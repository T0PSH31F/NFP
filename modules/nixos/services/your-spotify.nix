# Your Spotify - Spotify listening history analytics
# modules/nixos/services/your-spotify.nix
{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.services-config.your-spotify;
in
{
  options.services-config.your-spotify = {
    enable = mkEnableOption "Your Spotify analytics service";

    port = mkOption {
      type = types.port;
      default = 3456;
      description = "API server port";
    };

    clientEndpoint = mkOption {
      type = types.str;
      default = "http://localhost:3457";
      description = "Client endpoint URL";
    };

    apiEndpoint = mkOption {
      type = types.str;
      default = "http://localhost:3456";
      description = "API endpoint URL";
    };

    spotifyPublic = mkOption {
      type = types.str;
      default = "";
      description = "Spotify application public client ID";
    };

    spotifySecretFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to file containing Spotify application secret";
    };

    nginxVirtualHost = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Nginx virtual host for the client (optional)";
    };
  };

  config = mkIf cfg.enable {
    # Native NixOS Your Spotify service
    services.your_spotify = {
      enable = true;
      enableLocalDB = true; # Use local MongoDB

      settings = {
        PORT = cfg.port;
        API_ENDPOINT = cfg.apiEndpoint;
        CLIENT_ENDPOINT = cfg.clientEndpoint;
        SPOTIFY_PUBLIC = cfg.spotifyPublic;
        MONGO_ENDPOINT = "mongodb://localhost:27017/your_spotify";
      };

      spotifySecretFile = mkIf (cfg.spotifySecretFile != null) cfg.spotifySecretFile;
      nginxVirtualHost = cfg.nginxVirtualHost;
    };

    # Firewall
    networking.firewall.allowedTCPPorts = [
      cfg.port
      3457
    ];

    # Impermanence support
    environment.persistence."/persist" = mkIf config.system-config.impermanence.enable {
      directories = [
        {
          directory = "/var/lib/mongodb";
          user = "mongodb";
          group = "mongodb";
          mode = "0755";
        }
      ];
    };
  };
}
