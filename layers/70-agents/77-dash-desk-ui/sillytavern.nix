# Tier: 77-dash-desk-ui
# Module: sillytavern.nix
# Purpose: SillyTavern interactive LLM chat and character frontend interface.
# Option Path: services.sillytavern-app (also clan.services.ai.sillytavern)
# Enabling Host Tags: desktop, workstation, homelab
# RAM Footprint: medium (300MB-1GB)
{
  config,
  lib,
  ...
}:
with lib;
{
  options.services.sillytavern-app = {
    enable = mkEnableOption "SillyTavern service";

    port = mkOption {
      type = types.int;
      default = 8000;
      description = "SillyTavern port";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/SillyTavern";
      description = "Data directory for SillyTavern";
    };
  };

  options.clan.services.ai.sillytavern = {
    enable = mkEnableOption "SillyTavern Clan Service";
  };

  config = mkMerge [
    {
      nfp.services.sillytavern = {
        enable = config.services.sillytavern-app.enable;
        host = "nami";
        port = 8000;
        homepage = {
          enable = true;
          category = "agents";
          order = 70;
          title = "SillyTavern";
          subtitle = "Roleplay & Chat Engine";
          icon = "sillytavern";
          metric = {
            mode = "health-only";
          };
        };
        healthcheck = {
          enable = true;
          path = "/";
          expectedStatus = 200;
        };
      };
    }
    (mkIf (config.services.sillytavern-app.enable || config.clan.services.ai.sillytavern.enable) {
      # Native NixOS SillyTavern service
      services.sillytavern = {
        enable = true;
        port = config.services.sillytavern-app.port;
        listen = true; # Listen on all interfaces
      };

      # Ensure the extensions directory exists before BindPaths tries to mount it
      systemd.tmpfiles.rules = [
        "d ${config.services.sillytavern-app.dataDir}/extensions 0755 sillytavern sillytavern -"
      ];

      # Firewall
      networking.firewall.allowedTCPPorts = [ config.services.sillytavern-app.port ];

      # Ensure data is persisted
      environment.persistence."/persist" =
        mkIf (config.layers.layer-10.system.config.impermanence.enable or false)
          {
            directories = [
              {
                directory = "/var/lib/SillyTavern";
                user = "sillytavern";
                group = "sillytavern";
                mode = "0755";
              }
            ];
          };
    })
  ];
}
