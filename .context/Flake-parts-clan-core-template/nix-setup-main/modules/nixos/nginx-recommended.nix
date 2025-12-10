{
  config,
  lib,
  pkgs,
  ...
}: {
  options.nginxRecommended = {
    enable = lib.mkEnableOption "Nginx with recommended security settings and ACME";

    baseDomainName = lib.mkOption {
      type = lib.types.str;
      default = "sipp.family";
      description = "Base domain name for ACME certificate";
    };

    acmeEmail = lib.mkOption {
      type = lib.types.str;
      default = "henry.sipp@hey.com";
      description = "Email address for ACME certificate registration";
    };
  };

  config = lib.mkIf config.nginxRecommended.enable {
    sops.secrets.cloudflare_api_token = {};

    # ACME configuration for wildcard certificate
    security.acme = {
      acceptTerms = true;
      defaults = {
        email = config.nginxRecommended.acmeEmail;
      };
      certs."${config.nginxRecommended.baseDomainName}" = {
        domain = "*.${config.nginxRecommended.baseDomainName}";
        extraDomainNames = [config.nginxRecommended.baseDomainName];
        dnsProvider = "cloudflare";
        dnsResolver = "1.1.1.1:53";
        environmentFile = config.sops.secrets.cloudflare_api_token.path;
        group = "nginx";
      };
    };

    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      appendHttpConfig = ''
        map $http_upgrade $connection_upgrade {
          default upgrade;
          "" close;
        }

        # Rate limiting
        limit_req_zone $binary_remote_addr zone=login:10m rate=5r/m;
        limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
      '';
    };

    # Fail2ban for intrusion prevention
    services.fail2ban = {
      enable = true;
      maxretry = 3;
      bantime = "24h";

      jails = {
        nginx-http-auth = ''
          enabled = true
          filter = nginx-http-auth
          logpath = /var/log/nginx/error.log
          maxretry = 3
          bantime = 24h
        '';

        nginx-limit-req = ''
          enabled = true
          filter = nginx-limit-req
          logpath = /var/log/nginx/error.log
          maxretry = 10
          bantime = 24h
        '';

        nginx-bad-request = ''
          enabled = true
          filter = nginx-bad-request
          logpath = /var/log/nginx/access.log
          maxretry = 5
          bantime = 24h
        '';
      };
    };

    services.nginx.virtualHosts."default" = {
      default = true;
      forceSSL = true;
      useACMEHost = config.nginxRecommended.baseDomainName;
      locations."/" = {
        return = "444"; # Close connection without response
      };
    };
  };
}
