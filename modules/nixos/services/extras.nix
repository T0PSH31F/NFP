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

    # Audiobookshelf (BookLore?)
    audiobookshelf-app = {
      enable = mkEnableOption "Audiobookshelf server";
      port = mkOption {
        type = types.port;
        default = 13378;
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

    # Pi-hole (Container)
    pihole-server = {
      enable = mkEnableOption "Pi-hole DNS blocker";
      port = mkOption {
        type = types.port;
        default = 8089;
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

    # FileBrowser
    (mkIf cfg.filebrowser-app.enable {
      services.filebrowser = {
        enable = true;
        port = cfg.filebrowser-app.port;
        # Bind to all interfaces to be accessible
        address = "0.0.0.0";
        # Use root directory
      };
      systemd.services.filebrowser.serviceConfig.StateDirectory = "filebrowser";
      networking.firewall.allowedTCPPorts = [ cfg.filebrowser-app.port ];
    })

    # Audiobookshelf
    (mkIf cfg.audiobookshelf-app.enable {
      services.audiobookshelf = {
        enable = true;
        port = cfg.audiobookshelf-app.port;
        host = "0.0.0.0";
      };
      networking.firewall.allowedTCPPorts = [ cfg.audiobookshelf-app.port ];
    })

    # Deluge
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
    })

    # Transmission
    (mkIf cfg.transmission-server.enable {
      services.transmission = {
        enable = true;
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
          dns_config.base_domain = "grandlix.net";
          server_url = "http://localhost:${toString cfg.headscale-server.port}";
        };
      };
      networking.firewall.allowedTCPPorts = [ cfg.headscale-server.port ];
    })

    # Pi-hole (Docker)
    (mkIf cfg.pihole-server.enable {
      virtualisation.oci-containers.containers.pihole = {
        image = "pihole/pihole:latest";
        ports = [
          "${toString cfg.pihole-server.port}:80"
          "53:53/tcp"
          "53:53/udp"
        ];
        environment = {
          TZ = "America/Los_Angeles";
        };
        volumes = [
          "/var/lib/pihole/etc-pihole:/etc/pihole"
          "/var/lib/pihole/etc-dnsmasq.d:/etc/dnsmasq.d"
        ];
      };
      networking.firewall.allowedTCPPorts = [
        cfg.pihole-server.port
        53
      ];
      networking.firewall.allowedUDPPorts = [ 53 ];

      systemd.tmpfiles.rules = [
        "d /var/lib/pihole/etc-pihole 0755 root root -"
        "d /var/lib/pihole/etc-dnsmasq.d 0755 root root -"
      ];
    })
  ];
}
