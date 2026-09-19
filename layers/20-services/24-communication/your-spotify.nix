# Your Spotify - Spotify listening history analytics
# layers/nixos/services/your-spotify.nix
{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.layers.layer-20.services.config.your-spotify;
in
{
  options.layers.layer-20.services.config.your-spotify = {
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
      description = ''
        Path to file containing Spotify application secret.
        By default, this is automatically generated/prompted via Clan vars generator.
      '';
    };

    nginxVirtualHost = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Nginx virtual host for the client (optional)";
    };
  };

  config = mkIf cfg.enable {
    nfp.services.your-spotify = {
      enable = true;
      host = "luffy";
      bind = "127.0.0.1";
      inherit (cfg) port;
      tailnetName = "your-spotify";
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
        category = "sanji";
        order = 30;
        title = "Your Spotify";
        subtitle = "Galley Music History";
        icon = "your-spotify";
        metric = {
          mode = "health-only";
        };
      };
    };

    clan.core.vars.generators.your-spotify = {
      files."spotify-secret" = {
        secret = true;
      };
      prompts."spotify-secret" = {
        type = "hidden";
        description = "Spotify application client secret";
      };
      script = ''
        if [ -f "$prompts/spotify-secret" ]; then
          cat "$prompts/spotify-secret" > "$out/spotify-secret"
        else
          # Generate a fallback dummy secret to avoid service startup crash on initial build
          echo "DUMMY_SPOTIFY_SECRET" > "$out/spotify-secret"
        fi
      '';
    };

    # Native NixOS Your Spotify service
    services.your_spotify = {
      enable = true;
      enableLocalDB = false; # Using containerized MongoDB to avoid source build

      settings = {
        PORT = cfg.port;
        API_ENDPOINT = cfg.apiEndpoint;
        CLIENT_ENDPOINT = cfg.clientEndpoint;
        SPOTIFY_PUBLIC = cfg.spotifyPublic;
        MONGO_ENDPOINT = "mongodb://localhost:27017/your_spotify";
      };

      spotifySecretFile =
        if cfg.spotifySecretFile != null then
          cfg.spotifySecretFile
        else
          config.clan.core.vars.generators.your-spotify.files."spotify-secret".path;
      inherit (cfg) nginxVirtualHost;
    };

    # MongoDB Container (SSPL licensed, avoids local compilation)
    virtualisation.oci-containers.containers.your-spotify-db = {
      image = "mongo:7.0";
      ports = [ "27017:27017" ];
      volumes = [
        "/var/lib/mongodb-container:/data/db"
      ];
    };

    # Firewall
    networking.firewall.allowedTCPPorts = [
      cfg.port
      3457
    ];

  };
}
