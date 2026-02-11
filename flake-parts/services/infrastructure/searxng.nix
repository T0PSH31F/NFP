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
    services.searx = {
      enable = true;
      settings = {
        server = {
          port = cfg.port;
          bind_address = "127.0.0.1";
          secret_key = "@SEARX_SECRET_KEY@";
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
