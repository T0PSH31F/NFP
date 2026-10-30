# HedgeDoc - Collaborative Markdown Editor (WYSIWYG)
# layers/nixos/services/hedgedoc.nix
{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.layers.layer-20.services.config.hedgedoc;
  # Generate a session secret from machine-id for determinism without secrets
  sessionSecret = builtins.hashString "sha256" "${config.networking.hostName}-hedgedoc-session";
in
{
  options.layers.layer-20.services.config.hedgedoc = {
    enable = mkEnableOption "HedgeDoc collaborative markdown editor";

    port = mkOption {
      type = types.port;
      default = 3001;
      description = "Web interface port";
    };

    domain = mkOption {
      type = types.str;
      default = "hedgedoc.lovelain.duckdns.org";
      description = "Public domain for HedgeDoc";
    };
  };

  config = mkIf cfg.enable {
    # PostgreSQL: ensure database and user exist (shared instance on luffy)
    services.postgresql = {
      ensureDatabases = [ "hedgedoc" ];
      ensureUsers = [
        {
          name = "hedgedoc";
          ensureDBOwnership = true;
        }
      ];
    };

    # HedgeDoc OCI container
    virtualisation.oci-containers.containers.hedgedoc = {
      image = "quay.io/hedgedoc/hedgedoc:1.11.0";
      ports = [ "${toString cfg.port}:3000" ];
      volumes = [
        "/var/lib/hedgedoc/uploads:/hedgedoc/public/uploads"
      ];
      environment = {
        CMD_DB_URL = "postgres://hedgedoc@localhost:5432/hedgedoc";
        CMD_DB_DIALECT = "postgres";
        CMD_DOMAIN = cfg.domain;
        CMD_PROTOCOL_USESSL = "true";
        CMD_PORT = "3000";
        CMD_ALLOW_ORIGIN = "['localhost', '${cfg.domain}']";
        CMD_SESSION_SECRET = sessionSecret;
        CMD_EMAIL = "false";
        CMD_ALLOW_EMAIL_REGISTER = "false";
        CMD_ALLOW_ANONYMOUS = "false";
        CMD_ALLOW_ANONYMOUS_EDITS = "true";
        CMD_ALLOW_FREEURL = "true";
        CMD_REQUIRE_FREEURL_AUTH = "false";
      };
    };

    # Ensure uploads directory exists (impermanence may recreate /var/lib/hedgedoc empty)
    systemd.tmpfiles.rules = [
      "d /var/lib/hedgedoc/uploads 0755 root root -"
    ];

    # Impermanence: persist uploads
    environment.persistence."/persist" = mkIf config.layers.layer-10.system.config.impermanence.enable {
      directories = [
        {
          directory = "/var/lib/hedgedoc";
          user = "root";
          group = "root";
          mode = "0755";
        }
      ];
    };

    # Firewall
    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
