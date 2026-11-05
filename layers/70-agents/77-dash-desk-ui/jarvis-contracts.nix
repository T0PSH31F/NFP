# Tier: 77-dash-desk-ui
# Module: jarvis-contracts.nix
# Purpose: Expose Enterprise Jarvis services to NFP Homepage Dashboard & Fleet Monitoring
{
  config,
  lib,
  ...
}:
with lib;
let
  jarvisEnabled = config.services.jarvis.enable or false;
in
{
  config = mkIf jarvisEnabled {
    nfp.services = {
      jarvis-pwa = {
        enable = config.services.jarvis.pwa.enable or false;
        host = config.networking.hostName;
        port = config.services.jarvis.pwa.port or 8096;
        healthcheck = {
          enable = true;
          path = "/";
          expectedStatus = 200;
        };
        homepage = {
          enable = true;
          category = "luffy";
          order = 1;
          title = "Jarvis Command Center";
          subtitle = "Autonomous Executive AI Appliance & A2UI Cards";
          icon = "terminal";
          metric = {
            mode = "health-only";
          };
        };
      };

      jarvis-jev = {
        enable = config.services.jarvis.core.enable or false;
        host = config.networking.hostName;
        port = config.services.jarvis.core.port or 20127;
        healthcheck = {
          enable = true;
          path = "/healthz";
          expectedStatus = 200;
        };
        homepage = {
          enable = true;
          category = "luffy";
          order = 2;
          title = "Jev System-1 Proxy";
          subtitle = "0-Token Heuristic Event Classifier (<1ms)";
          icon = "shield";
          metric = {
            mode = "health-only";
          };
        };
      };

      jarvis-durable = {
        enable = config.services.jarvis.harness.enable or false;
        host = config.networking.hostName;
        port = config.services.jarvis.harness.port or 8089;
        healthcheck = {
          enable = true;
          path = "/healthz";
          expectedStatus = 200;
        };
        homepage = {
          enable = true;
          category = "luffy";
          order = 3;
          title = "Pi Durable Daemon";
          subtitle = "24/7 SQLite WAL Background Agent Loop";
          icon = "robot";
          metric = {
            mode = "health-only";
          };
        };
      };
    };
  };
}
