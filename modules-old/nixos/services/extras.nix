{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services;
in
{
  options.services = {
    # Glances
    glances-server = {
      enable = mkEnableOption "Glances system monitoring";
      port = mkOption {
        type = types.port;
        default = 61208;
      };
    };

    # FileBrowser
    filebrowser-app = {
      enable = mkEnableOption "FileBrowser web interface";
      port = mkOption {
        type = types.port;
        default = 8085;
      };
      rootDir = mkOption {
        type = types.str;
        default = "/var/lib/filebrowser";
      };
    };

    # Deluge
    deluge-server = {
      enable = mkEnableOption "Deluge BitTorrent client";
      port = mkOption {
        type = types.port;
        default = 8113;
      }; # 8112 often conflicts
    };

    # Transmission
    transmission-server = {
      enable = mkEnableOption "Transmission BitTorrent client";
      port = mkOption {
        type = types.port;
        default = 9091;
      };
    };

    # Headscale
    headscale-server = {
      enable = mkEnableOption "Headscale Tailscale control server";
      port = mkOption {
        type = types.port;
        default = 8086;
      };
    };
  };

  config = mkMerge [
    # Glances
    (mkIf cfg.glances-server.enable {
      services.glances = {
        enable = true;
        openFirewall = true;
      };
    })

    # FileBrowser - Native NixOS service
    (mkIf cfg.filebrowser-app.enable {
      services.filebrowser = {
        enable = true;
        openFirewall = true;
        settings = {
          port = cfg.filebrowser-app.port;
          address = "0.0.0.0";
          root = cfg.filebrowser-app.rootDir;
          # Use subdirectory for database to avoid tmpfiles conflict
          database = "/var/lib/filebrowser/data/filebrowser.db";
        };
      };
      # Note: Native service handles directory creation automatically
    })

    (mkIf cfg.deluge-server.enable {
      services.deluge = {
        enable = true;
        web = {
          enable = true;
          port = cfg.deluge-server.port;
        };
      };
      networking.firewall.allowedTCPPorts = [
        cfg.deluge-server.port
        58846
      ];
      # Fix permissions for Deluge state directory
      systemd.tmpfiles.rules = [
        "Z /var/lib/deluge 0750 deluge deluge -"
      ];
      # Disable DynamicUser to ensure access to /var/lib/deluge owned by static 'deluge' user
      systemd.services.delugeweb.serviceConfig.DynamicUser = lib.mkForce false;
      systemd.services.deluged.serviceConfig.DynamicUser = lib.mkForce false;
      systemd.services.delugeweb.serviceConfig.User = "deluge";
      systemd.services.delugeweb.serviceConfig.Group = "deluge";
      systemd.services.deluged.serviceConfig.User = "deluge";
      systemd.services.deluged.serviceConfig.Group = "deluge";
    })

    # Transmission
    (mkIf cfg.transmission-server.enable {
      services.transmission = {
        enable = true;
        package = pkgs.transmission_4;
        settings = {
          rpc-bind-address = "0.0.0.0";
          rpc-port = cfg.transmission-server.port;
          rpc-whitelist-enabled = false;
        };
      };
      networking.firewall.allowedTCPPorts = [ cfg.transmission-server.port ];
    })

    # Headscale
    (mkIf cfg.headscale-server.enable {
      services.headscale = {
        enable = true;
        port = cfg.headscale-server.port;
        address = "0.0.0.0";
        settings = {
          dns = {
            base_domain = "grandlix.net";
            magic_dns = true;
            nameservers.global = [
              "1.1.1.1"
              "1.0.0.1"
            ];
          };
          server_url = "http://localhost:${toString cfg.headscale-server.port}";
        };
      };
      networking.firewall.allowedTCPPorts = [ cfg.headscale-server.port ];
      # Disable DynamicUser to prevent state directory migration issues
      systemd.services.headscale.serviceConfig.DynamicUser = lib.mkForce false;

      users.users.headscale = {
        group = "headscale";
        isSystemUser = true;
        home = "/var/lib/headscale";
        createHome = true;
      };
      users.groups.headscale = { };

      systemd.tmpfiles.rules = [
        "d /var/lib/headscale 0750 headscale headscale -"
      ];
    })
  ];
}
