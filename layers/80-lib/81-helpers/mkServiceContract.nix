# layers/80-lib/81-helpers/mkServiceContract.nix
# Declarative contract schema for NFP fleet services (nfp.services.<name>).
{ lib, ... }:
with lib;
let
  serviceSubmodule = types.submodule (
    { name, ... }:
    {
      options = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable service contract.";
        };

        host = mkOption {
          type = types.str;
          default = "luffy";
          description = "Clan machine target host.";
        };

        bind = mkOption {
          type = types.str;
          default = "127.0.0.1";
          description = "Listening IP address (default loopback).";
        };

        port = mkOption {
          type = types.port;
          description = "Primary listening port for service.";
        };

        tailnetName = mkOption {
          type = types.str;
          default = name;
          description = "MagicDNS / Caddy subdomain name on tailnet.";
        };

        tls = mkOption {
          type = types.enum [
            "headscale"
            "internal-ca"
            "none"
          ];
          default = "headscale";
          description = "TLS termination strategy for tailnet access.";
        };

        metrics = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = "Enable Prometheus metrics scraping.";
          };

          port = mkOption {
            type = types.port;
            default = 0;
            description = "Metrics exporter port (0 = use service port or disable).";
          };
        };

        backup = {
          paths = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "List of filesystem paths to include in restic backup.";
          };

          preCommand = mkOption {
            type = types.str;
            default = "";
            description = "Shell command executed prior to backup snapshot (e.g. pg_dump).";
          };
        };

        homepage = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = "Include service entry on Homepage dashboard.";
          };

          group = mkOption {
            type = types.str;
            default = "Services";
            description = "Homepage category group.";
          };

          icon = mkOption {
            type = types.str;
            default = name;
            description = "Dashboard service icon identifier.";
          };

          widget = mkOption {
            type = types.nullOr types.attrs;
            default = null;
            description = "Optional Homepage widget configuration.";
          };
        };

        sso = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable SSO authentication integration.";
          };
        };
      };
    }
  );
in
{
  options.nfp.services = mkOption {
    type = types.attrsOf serviceSubmodule;
    default = { };
    description = "Declarative service contracts registry across NFP fleet.";
  };
}
