# Tier: 20-services / 23-media
# Module: feishin.nix
# Purpose: Feishin modern music client & web application service with Caddy reverse proxy & server connection defaults.
# Option Path: services.feishin (and programs.feishin / layers.layer-20.services.feishin / layers.layer-60.gui.feishin)
# Enabling Host Tags: media, desktop
{
  config,
  lib,
  pkgs,
  osConfig ? config,
  ...
}:

with lib;

let
  cfg = config.services.feishin;
  user = osConfig.layers.meta.primaryUser or "t0psh31f";
in
{
  imports = [
    (lib.mkAliasOptionModule [ "programs" "feishin" ] [ "services" "feishin" ])
    (lib.mkAliasOptionModule [ "layers" "layer-20" "services" "feishin" ] [ "services" "feishin" ])
    (lib.mkAliasOptionModule [ "layers" "layer-60" "gui" "feishin" ] [ "services" "feishin" ])
  ];

  options.services.feishin = {
    enable = mkEnableOption "Feishin modern music client & web application";

    package = mkOption {
      type = types.nullOr types.package;
      default = pkgs.feishin or null;
      description = "Package to use for Feishin desktop client";
    };

    mode = mkOption {
      type = types.enum [
        "desktop"
        "server"
        "both"
      ];
      default = "both";
      description = "Execution mode: desktop GUI client, container web player, or both";
    };

    port = mkOption {
      type = types.port;
      default = 9180;
      description = "Port to expose Feishin web application on";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Open firewall port for Feishin web application";
    };

    serverConnection = {
      url = mkOption {
        type = types.str;
        default = "http://127.0.0.1:4533";
        description = "Default music server endpoint URL (e.g., Navidrome, Jellyfin, Subsonic)";
      };

      serverType = mkOption {
        type = types.enum [
          "navidrome"
          "jellyfin"
          "subsonic"
          "custom"
        ];
        default = "navidrome";
        description = "Music server backend type";
      };

      name = mkOption {
        type = types.str;
        default = "NFP Music Server";
        description = "Display name for default music server connection";
      };
    };

    caddy = {
      enable = mkEnableOption "Caddy reverse proxy integration for Feishin";

      hostName = mkOption {
        type = types.str;
        default = "feishin.${config.layers.meta.publicDomain}";
        description = "Virtual hostname for Caddy reverse proxy (public WAN via lovelain.duckdns.org)";
      };

      useACME = mkOption {
        type = types.bool;
        default = false;
        description = "Enable ACME SSL/TLS certificate for host";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      # Install desktop package if in desktop or both mode
      environment.systemPackages = optional (
        (cfg.mode == "desktop" || cfg.mode == "both") && cfg.package != null
      ) cfg.package;

      # Firewall
      networking.firewall.allowedTCPPorts = optional cfg.openFirewall cfg.port;

      # Home-Manager configuration seeding for desktop client
      home-manager.users.${user} =
        { pkgs, ... }:
        {
          config = {
            xdg.configFile."feishin/server-config.json".text = builtins.toJSON {
              servers = [
                {
                  id = "default-server";
                  name = cfg.serverConnection.name;
                  url = cfg.serverConnection.url;
                  type = cfg.serverConnection.serverType;
                }
              ];
              activeServerId = "default-server";
            };
          };
        };
    }

    # Containerized web player when mode is "server" or "both"
    (mkIf (cfg.mode == "server" || cfg.mode == "both") {
      virtualisation.oci-containers.containers.feishin = {
        image = "ghcr.io/jeffvli/feishin:latest";
        autoStart = true;
        ports = [ "${toString cfg.port}:9180" ];
        environment = {
          SERVER_URL = cfg.serverConnection.url;
          SERVER_TYPE = cfg.serverConnection.serverType;
          SERVER_NAME = cfg.serverConnection.name;
        };
      };
    })

    # Caddy reverse proxy integration
    (mkIf cfg.caddy.enable {
      services.caddy = {
        enable = true;
        virtualHosts."http://${cfg.caddy.hostName}" = {
          extraConfig = ''
            reverse_proxy 127.0.0.1:${toString cfg.port}
          '';
        };
      };
    })
  ]);
}
