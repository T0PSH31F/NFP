{
  config,
  lib,
  pkgs,
  ...
}: {
  options.plex = {
    enable = lib.mkEnableOption "Plex media server";
    subDomainName = lib.mkOption {
      type = lib.types.str;
      default = "plex";
      description = "Subdomain for Plex service";
    };
    baseDomainName = lib.mkOption {
      type = lib.types.str;
      default = "sipp.family";
      description = "Base domain name for Plex service";
    };
  };

  config = lib.mkIf config.plex.enable {
    networking.firewall = {
      allowedTCPPorts = [32400];
      allowedUDPPorts = [
        1900 # DLNA/UPnP discovery
        5353 # Bonjour/Avahi discovery
        32410 # GDM network discovery
        32412 # GDM network discovery
        32413 # GDM network discovery
        32414 # GDM network discovery
      ];
    };

    containers.plex = {
      autoStart = true;
      privateNetwork = false; # Share host networking
      # No need for hostAddress, localAddress, or forwardPorts

      bindMounts = {
        "/var/lib/plex" = {
          hostPath = "/persistent/plex";
          isReadOnly = false;
        };
        "/media" = {
          hostPath = "/mnt/net-video";
          isReadOnly = true;
        };
      };

      config = {pkgs, ...}: {
        nixpkgs.config.allowUnfree = true;

        services.plex = {
          enable = true;
          openFirewall = true;
          dataDir = "/var/lib/plex";
        };

        systemd.tmpfiles.rules = [
          "d /var/lib/plex 0755 plex plex -"
        ];
      };
    };

    # Update nginx to use localhost
    services.nginx.virtualHosts."${config.plex.subDomainName}.${config.plex.baseDomainName}" = {
      forceSSL = true;
      useACMEHost = config.plex.baseDomainName;
      locations."/" = {
        proxyPass = "http://localhost:32400"; # Now using localhost
        proxyWebsockets = true;
        extraConfig = ''
          proxy_buffering off;
          proxy_request_buffering off;

          proxy_connect_timeout 3600;
          proxy_send_timeout 3600;
          proxy_read_timeout 3600;
          send_timeout 3600;
        '';
      };
    };
  };
}
