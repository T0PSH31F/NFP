{
  config,
  lib,
  pkgs,
  ...
}: {
  options.immich = {
    enable = lib.mkEnableOption "Immich photo management";

    subDomainName = lib.mkOption {
      type = lib.types.str;
      default = "photos";
      description = "Subdomain for Immich service";
    };

    baseDomainName = lib.mkOption {
      type = lib.types.str;
      default = "sipp.family";
      description = "Base domain name for Immich service";
    };
  };

  config = lib.mkIf config.immich.enable {
    containers.immich = {
      autoStart = true;

      bindMounts = {
        "/var/lib" = {
          hostPath = "/persistent/immich";
          isReadOnly = false;
        };
        "/mnt/net-photo/immich" = {
          hostPath = "/mnt/net-photo/immich";
          isReadOnly = false;
        };
      };

      config = {
        config,
        pkgs,
        ...
      }: {
        services.immich = {
          enable = true;
          port = 2283;
          mediaLocation = "/mnt/net-photo/immich";
        };

        networking.firewall.allowedTCPPorts = [2283];

        system.stateVersion = "25.05";
      };
    };

    services.nginx.virtualHosts."${config.immich.subDomainName}.${config.immich.baseDomainName}" = {
      serverName = "${config.immich.subDomainName}.${config.immich.baseDomainName}";
      forceSSL = true;
      useACMEHost = config.immich.baseDomainName;
      locations."/" = {
        proxyPass = "http://[::1]:2283";
        proxyWebsockets = true;
        recommendedProxySettings = true;
        extraConfig = ''
          client_max_body_size 50000M;
          proxy_read_timeout   600s;
          proxy_send_timeout   600s;
          send_timeout         600s;
        '';
      };
    };
  };
}
