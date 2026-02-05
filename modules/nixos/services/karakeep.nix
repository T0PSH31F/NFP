# Karakeep - Self-hosted bookmark manager
# modules/nixos/services/karakeep.nix
{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.services-config.karakeep;
in
{
  options.services-config.karakeep = {
    enable = mkEnableOption "Karakeep bookmark manager";

    port = mkOption {
      type = types.port;
      default = 3000;
      description = "Web interface port";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/karakeep";
      description = "Data directory for Karakeep";
    };

    ollamaUrl = mkOption {
      type = types.nullOr types.str;
      default = "http://localhost:11434";
      description = "Ollama URL for local AI inference (optional)";
    };
  };

  config = mkIf cfg.enable {
    # Native NixOS Karakeep service
    services.karakeep = {
      enable = true;

      # Enable Meilisearch for full-text search
      meilisearch.enable = true;

      # Enable browser for screenshots
      browser.enable = true;

      # Environment configuration
      extraEnvironment = {
        NEXTAUTH_URL = "http://localhost:${toString cfg.port}";
      } // optionalAttrs (cfg.ollamaUrl != null) {
        OLLAMA_BASE_URL = cfg.ollamaUrl;
        INFERENCE_TEXT_MODEL = "llama3.2";
        INFERENCE_IMAGE_MODEL = "llava";
      };
    };

    # Firewall
    networking.firewall.allowedTCPPorts = [ cfg.port ];

    # Impermanence support
    environment.persistence."/persist" = mkIf config.system-config.impermanence.enable {
      directories = [
        {
          directory = "/var/lib/karakeep";
          user = "karakeep";
          group = "karakeep";
          mode = "0755";
        }
        {
          directory = "/var/lib/meilisearch-karakeep";
          user = "meilisearch-karakeep";
          group = "meilisearch-karakeep";
          mode = "0755";
        }
      ];
    };
  };
}
