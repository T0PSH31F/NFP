{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.searxng;
in
{
  options.services.searxng = {
    enable = lib.mkEnableOption "SearxNG metasearch engine";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8888;
      description = "Port for SearxNG web interface";
    };
  };

  config = lib.mkIf cfg.enable {
    nfp.services.searxng = {
      enable = true;
      host = "luffy";
      bind = "127.0.0.1";
      inherit (cfg) port;
      tailnetName = "searxng";
      tls = "headscale";
      healthcheck = {
        enable = true;
        path = "/healthz";
        expectedStatus = [ 200 ];
      };
      homepage = {
        enable = true;
        category = "nami";
        order = 10;
        title = "SearXNG";
        subtitle = "Grand Line Map";
        icon = "searxng";
        metric = {
          mode = "health-only";
        };
      };
    };

    clan.core.vars.generators.searxng = {
      files."searxng.env" = {
        secret = true;
      };
      script = ''
        SECRET=$(${pkgs.openssl}/bin/openssl rand -hex 32)
        echo "SEARX_SECRET_KEY=$SECRET" > "$out/searxng.env"
      '';
    };

    services.searx = {
      enable = true;
      environmentFile = config.clan.core.vars.generators.searxng.files."searxng.env".path;
      settings = {
        server = {
          inherit (cfg) port;
          bind_address = "127.0.0.1";
          secret_key = "$SEARX_SECRET_KEY";
        };
        ui = {
          static_use_hash = true;
        };
        search = {
          safe_search = 0;
          autocomplete = "google";
        };
      };
    };

    # Nginx reverse proxy (optional)
    services.nginx = lib.mkIf (config.services.nginx.enable or false) {
      virtualHosts."searx.local" = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString cfg.port}";
        };
      };
    };
  };
}
