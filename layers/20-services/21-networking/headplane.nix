# Tier: 20-services
# Module: headplane.nix
# Purpose: Headplane web UI management console for Headscale tailnet.
# Option Path: layers.layer-20.services.config.headplane
# Service Contract: nfp.services.headplane
{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.layers.layer-20.services.config.headplane;
  headplaneConfig = pkgs.writeText "headplane-config.yaml" (
    builtins.toJSON {
      server = {
        host = "0.0.0.0";
        inherit (cfg) port;
        cookie_secret_path = config.clan.core.vars.generators.headplane.files."cookie-secret".path;
      };
      headscale = {
        url = cfg.headscaleUrl;
        config_strict = false;
      };
      integration = {
        proc = {
          enabled = false;
        };
      };
    }
  );
in
{
  options.layers.layer-20.services.config.headplane = {
    enable = mkEnableOption "Headplane Headscale management web UI";
    port = mkOption {
      type = types.port;
      default = 3000;
      description = "Listen port for Headplane web UI";
    };
    headscaleUrl = mkOption {
      type = types.str;
      default = "http://100.80.146.120:8086";
      description = "URL of authoritative Headscale server (luffy)";
    };
  };

  config = mkIf cfg.enable {
    # Generate Headplane session secret via Clan vars
    clan.core.vars.generators.headplane = {
      files."cookie-secret" = {
        secret = true;
        owner = "headplane";
        group = "headplane";
      };
      script = ''
        SECRET=$(${pkgs.openssl}/bin/openssl rand -hex 16)
        echo "$SECRET" > "$out/cookie-secret"
      '';
    };

    # Headplane system user & group
    users.users.headplane = {
      isSystemUser = true;
      group = "headplane";
      description = "Headplane daemon user";
    };
    users.groups.headplane = { };

    # Systemd service for Headplane
    systemd.services.headplane = {
      description = "Headplane Headscale Management Console";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      environment = {
        HEADPLANE_CONFIG_FILE = "${headplaneConfig}";
        PORT = toString cfg.port;
        HOST = "0.0.0.0";
      };
      serviceConfig = {
        ExecStart = "${pkgs.headplane}/bin/headplane";
        User = "headplane";
        Group = "headplane";
        Restart = "on-failure";
        RestartSec = 5;
        StateDirectory = "headplane";
        WorkingDirectory = "/var/lib/headplane";
      };
    };

    # Data contract & homepage integration
    nfp.services.headplane = {
      enable = true;
      host = config.networking.hostName;
      bind = "0.0.0.0";
      inherit (cfg) port;
      tailnetName = "headplane";
      tls = "headscale";
      healthcheck = {
        enable = true;
        path = "/admin";
        expectedStatus = [
          200
          302
          401
        ];
      };
      homepage = {
        enable = true;
        category = "nami";
        widget = {
          type = "customapi";
          url = "http://127.0.0.1:${toString cfg.port}";
        };
      };
    };
  };
}
