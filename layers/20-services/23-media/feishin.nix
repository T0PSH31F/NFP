# Tier: 20-services / 23-media
# Module: feishin.nix
# Purpose: Feishin modern music client & web application service with Caddy reverse proxy & server connection defaults.
# Option Path: services.feishin (and programs.feishin / layers.layer-20.services.feishin / layers.layer-60.gui.feishin)
# Enabling Host Tags: media, desktop
#
# NOTE (2026-10-13): nixpkgs-unstable now ships its own services.feishin module
# (static web-app serving via nginx/caddy). We no longer declare enable/package/
# caddy here — those belong to upstream. Local extras live under distinct names
# (desktopPackage, reverseProxy, mode/port/serverConnection) to avoid the
# "option already declared" collision.
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
    # enable: declared by upstream nixpkgs services.feishin module.

    desktopPackage = mkOption {
      type = types.nullOr types.package;
      default = pkgs.feishin or null;
      description = "Desktop client package to install (upstream `package` is the web build)";
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

    # Caddy reverse proxy for the containerized player (NOT upstream's
    # caddy option, which serves the static web build).
    reverseProxy = {
      enable = mkEnableOption "Caddy reverse proxy in front of the Feishin container";

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

  config = mkMerge [
    {
      nfp.services.feishin = {
        enable = config.services.feishin.enable;
        host = config.networking.hostName;
        port = 9180;
        homepage = {
          enable = true;
          category = "brook";
          order = 20;
          title = "Feishin";
          subtitle = "Soul King Audio Streamer";
          icon = "feishin";
          metric = {
            mode = "health-only";
          };
        };
        healthcheck = {
          enable = true;
          path = "/";
          # Feishin root redirects to /web/index.html (302); accept both
          expectedStatus = [
            200
            302
          ];
        };
      };
    }
    (mkIf cfg.enable (mkMerge [
      {
        # Install desktop package if in desktop or both mode
        environment.systemPackages = optional (
          (cfg.mode == "desktop" || cfg.mode == "both") && cfg.desktopPackage != null
        ) cfg.desktopPackage;

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

      # Caddy reverse proxy for the containerized player
      (mkIf cfg.reverseProxy.enable {
        services.caddy = {
          enable = true;
          virtualHosts."http://${cfg.reverseProxy.hostName}" = {
            extraConfig = ''
              reverse_proxy 127.0.0.1:${toString cfg.port}
            '';
          };
        };
      })
    ]))
  ];
}
