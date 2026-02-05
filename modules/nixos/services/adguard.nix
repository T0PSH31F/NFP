# AdGuard Home DNS Service
# modules/nixos/services/adguard.nix
{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.services-config.adguard;
in
{
  options.services-config.adguard = {
    enable = mkEnableOption "AdGuard Home DNS filtering";

    port = mkOption {
      type = types.port;
      default = 3000;
      description = "Web interface port";
    };

    dnsPort = mkOption {
      type = types.port;
      default = 53;
      description = "DNS server port";
    };
  };

  config = mkIf cfg.enable {
    services.adguardhome = {
      enable = true;
      openFirewall = true;
      mutableSettings = true;
      settings = {
        http = {
          address = "0.0.0.0:${toString cfg.port}";
        };
        dns = {
          bind_hosts = [ "0.0.0.0" ];
          port = cfg.dnsPort;
          bootstrap_dns = [
            "9.9.9.9"
            "1.1.1.1"
          ];
          upstream_dns = [
            "https://dns.quad9.net/dns-query"
            "https://cloudflare-dns.com/dns-query"
          ];
        };
        filtering = {
          rewrites = [ ];
        };
      };
    };

    # Impermanence support
    environment.persistence."/persist" = mkIf config.system-config.impermanence.enable {
      directories = [
        {
          directory = "/var/lib/AdGuardHome";
          user = "adguardhome";
          group = "adguardhome";
          mode = "0700";
        }
      ];
    };
  };
}
