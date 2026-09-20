{
  config,
  lib,
  ...
}:
with lib;
{
  options.services.caddy-server = {
    enable = mkEnableOption "Caddy web server";

    email = mkOption {
      type = types.str;
      default = "";
      description = "Email for Let's Encrypt certificates";
    };

    virtualHosts = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            extraConfig = mkOption {
              type = types.lines;
              default = "";
              description = "Extra Caddy configuration";
            };
            useACMEHost = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Use ACME certificate for this host";
            };
            serverAliases = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = "Alternative names for this host";
            };
          };
        }
      );
      default = { };
      description = "Virtual hosts configuration";
    };
  };

  options.layers.layer-20.services.config.reverseProxy = {
    routes = mkOption {
      type = types.attrsOf types.int;
      default = { };
      description = "Registry of subdomains to localhost ports. E.g. { ollama = 11434; }";
    };
  };

  config = mkMerge [
    {
      nfp.services.caddy = {
        enable = config.services.caddy-server.enable;
        host = config.networking.hostName;
        bind = "127.0.0.1";
        port = 2019;
        tailnetName = "caddy";
        tls = "headscale";
        healthcheck = {
          enable = true;
          path = "/config/";
          expectedStatus = [ 200 ];
        };
        homepage = {
          enable = true;
          category = "zoro";
          order = 20;
          title = "Caddy";
          subtitle = "Santoryu Navigation Routes";
          icon = "caddy";
          metric = {
            mode = "health-only";
          };
        };
      };
    }
    (mkIf config.services.caddy-server.enable {
      security.acme.acceptTerms = true;

      services.caddy = {
        enable = true;

        globalConfig = mkIf (config.services.caddy-server.email != "") ''
          email ${config.services.caddy-server.email}
        '';

        virtualHosts =
          let
            baseVirtualHosts = mapAttrs (
              _name: value:
              filterAttrs (_: v: v != null) {
                inherit (value) extraConfig useACMEHost serverAliases;
              }
            ) config.services.caddy-server.virtualHosts;

            # Registry routes are public Caddy routes via *.publicDomain (lovelain.duckdns.org).
            # Tailnet-only routes must NOT use this registry — they use nfp.services + tailnetDomain.
            registryRoutes = mapAttrs' (
              subdomain: port:
              nameValuePair "http://${subdomain}.${config.layers.meta.publicDomain}" {
                extraConfig = ''
                  reverse_proxy localhost:${toString port}
                '';
              }
            ) config.layers.layer-20.services.config.reverseProxy.routes;
          in
          if config.layers.layer-20.services.config.reverseProxy.routes != { } then
            lib.mkMerge [
              baseVirtualHosts
              registryRoutes
            ]
          else
            baseVirtualHosts;
      };

      # Firewall
      networking.firewall.allowedTCPPorts = [
        80
        443
      ];
      networking.firewall.allowedUDPPorts = [ 443 ]; # For QUIC

      # Ensure data is persisted
      environment.persistence."/persist" = mkIf config.layers.layer-10.system.config.impermanence.enable {
        directories = [
          "/var/lib/caddy"
        ];
      };
    })
  ];
}
