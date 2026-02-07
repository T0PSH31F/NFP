{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.searxng;
in
{
  options.services.searxng = {
    enable = mkEnableOption "SearxNG metasearch engine";

    port = mkOption {
      type = types.port;
      default = 8888;
      description = "Port for SearxNG web interface";
    };

    host = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Host address to bind to";
    };

    secretKeyFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to file containing the secret key";
    };

    settings = mkOption {
      type = types.attrs;
      default = { };
      description = "Additional SearxNG settings";
    };
  };

  config = mkIf cfg.enable {
    services.searx = {
      enable = true;
      package = pkgs.searxng;
      
      settings = mkMerge [
        {
          server = {
            port = cfg.port;
            bind_address = cfg.host;
            secret_key = "@SEARXNG_SECRET@";
            base_url = "http://localhost:${toString cfg.port}/";
            image_proxy = true;
          };

          ui = {
            static_use_hash = true;
            default_theme = "simple";
            theme_args = {
              simple_style = "dark";
            };
          };

          search = {
            safe_search = 0;
            autocomplete = "duckduckgo";
            default_lang = "en";
          };

          engines = [
            {
              name = "duckduckgo";
              disabled = false;
            }
            {
              name = "google";
              disabled = false;
            }
            {
              name = "github";
              disabled = false;
            }
            {
              name = "stackoverflow";
              disabled = false;
            }
            {
              name = "wikipedia";
              disabled = false;
            }
          ];
        }
        cfg.settings
      ];

      environmentFile = mkIf (cfg.secretKeyFile != null) cfg.secretKeyFile;
    };

    # Create secret key file if not provided
    systemd.services.searx.preStart = mkIf (cfg.secretKeyFile == null) ''
      if [ ! -f /var/lib/searxng/secret_key ]; then
        mkdir -p /var/lib/searxng
        ${pkgs.openssl}/bin/openssl rand -hex 32 > /var/lib/searxng/secret_key
        chmod 600 /var/lib/searxng/secret_key
      fi
      export SEARXNG_SECRET=$(cat /var/lib/searxng/secret_key)
    '';

    # Firewall configuration (optional - only if you want external access)
    # networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
