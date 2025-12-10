{
  config,
  lib,
  pkgs,
  ...
}: {
  options.jellyfin = {
    enable = lib.mkEnableOption "Jellyfin media server";

    subDomainName = lib.mkOption {
      type = lib.types.str;
      default = "jellyfin";
      description = "Subdomain for Jellyfin service";
    };

    baseDomainName = lib.mkOption {
      type = lib.types.str;
      default = "sipp.family";
      description = "Base domain name for Jellyfin service";
    };
  };

  config = lib.mkIf config.jellyfin.enable {
    # Create storage for actual media files
    systemd.tmpfiles.rules = [
      "d /mnt/net-video/Movies 0755 jellyfin jellyfin"
      "d /mnt/net-video/Shows 0755 jellyfin jellyfin"
    ];

    containers.jellyfin = {
      autoStart = true;
      privateNetwork = true;
      hostAddress = "10.50.0.1";
      localAddress = "10.50.0.4";
      forwardPorts = [
        {
          containerPort = 8096;
          hostPort = 8096;
        }
      ];

      bindMounts = {
        "/var/lib/jellyfin" = {
          hostPath = "/persistent/jellyfin";
          isReadOnly = false;
        };
        "/media" = {
          hostPath = "/mnt/net-video";
          isReadOnly = true;
        };
      };

      config = {
        config,
        pkgs,
        ...
      }: {
        services.jellyfin = {
          enable = true;
          openFirewall = true;
        };

        networking.firewall.allowedTCPPorts = [8096];

        system.stateVersion = "25.05";
      };
    };

    services.nginx.virtualHosts."${config.jellyfin.subDomainName}.${config.jellyfin.baseDomainName}" = {
      serverName = "${config.jellyfin.subDomainName}.${config.jellyfin.baseDomainName}";
      forceSSL = true;
      useACMEHost = config.jellyfin.baseDomainName;
      locations."/" = {
        proxyPass = "http://10.50.0.4:8096";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_buffering off;
        '';
      };
    };
  };
}
