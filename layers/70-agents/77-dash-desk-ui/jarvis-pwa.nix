# Tier: 77-dash-desk-ui
# Module: jarvis-pwa.nix
# Purpose: Enterprise Jarvis Web PWA Shell & Modular Command Center (Split Workspace + 5 Docking Plugin Tabs)
# Option Path: layers.layer-77.dash-desk-ui.jarvis-pwa
# Enabling Host Tags: workstation, server, ai-agent
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.layers.layer-77.dash-desk-ui.jarvis-pwa;
in
{
  options.layers.layer-77.dash-desk-ui.jarvis-pwa = {
    enable = mkEnableOption "Jarvis Enterprise Web PWA Shell & Modular Command Center";

    port = mkOption {
      type = types.port;
      default = 8096;
      description = "Port for the Jarvis PWA Command Center";
    };

    host = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Bind address for the Jarvis PWA Command Center";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.jarvis-pwa-command-center = {
      description = "Jarvis Enterprise Web PWA Shell & Modular Command Center";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.python3}/bin/python3 ${./jarvis-pwa-server.py}";
        Restart = "always";
        RestartSec = "3s";
        Environment = [
          "JARVIS_PWA_HOST=${cfg.host}"
          "JARVIS_PWA_PORT=${toString cfg.port}"
        ];
      };
    };
  };
}
