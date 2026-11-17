# layers/20-services/23-media/jellystat.nix
# Jellystat — Viewing analytics and playback telemetry companion for Jellyfin
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.layers.layer-20.services.config.jellystat;
in
{
  options.layers.layer-20.services.config.jellystat = {
    enable = mkEnableOption "Jellystat viewing analytics for Jellyfin";

    port = mkOption {
      type = types.port;
      default = 7120;
      description = "Port Jellystat listens on.";
    };
  };

  config = mkIf cfg.enable {
    clan.core.vars.generators.jellystat = {
      files."jwt-secret".secret = true;
      runtimeInputs = [
        pkgs.openssl
        pkgs.coreutils
      ];
      script = ''
        openssl rand -hex 32 | tr -d '\n' > "$out/jwt-secret"
      '';
    };

    services.jellystat = {
      enable = true;
      openFirewall = true;
      settings = {
        JS_PORT = cfg.port;
        JS_LISTEN_IP = "0.0.0.0";
      };
      secretFiles.JWT_SECRET = config.clan.core.vars.generators.jellystat.files."jwt-secret".path;
    };

    nfp.services.jellystat = {
      enable = true;
      host = config.networking.hostName;
      bind = "127.0.0.1";
      inherit (cfg) port;
      tailnetName = "jellystat";
      tls = "headscale";
      healthcheck = {
        enable = true;
        path = "/";
        expectedStatus = [
          200
          302
        ];
      };
      homepage = {
        enable = true;
        category = "vegapunk";
        order = 25;
        title = "Jellystat";
        subtitle = "Egghead Viewing Telemetry";
        icon = "jellyfin";
        satellite = null;
        metric.mode = "health-only";
      };
    };

    environment.persistence."/persist" =
      mkIf (config.layers.layer-10.system.config.impermanence.enable or false)
        {
          directories = [
            {
              directory = config.services.jellystat.dataDir;
              user = config.services.jellystat.user;
              group = config.services.jellystat.group;
              mode = "0750";
            }
          ];
        };
  };
}
