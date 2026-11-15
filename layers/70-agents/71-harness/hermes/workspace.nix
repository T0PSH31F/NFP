{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  options.layers.layer-76.hermes-workspace = {
    enable = lib.mkEnableOption "Hermes WebUI (nesquena/hermes-webui)";

    workspaceDir = lib.mkOption {
      type = lib.types.str;
      default = toString inputs.hermes-webui;
      description = "Path to the hermes-webui source tree.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = "Port for the web UI.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      description = "Bind address (0.0.0.0 for LAN access).";
    };
  };

  config =
    let
      cfg = config.layers.layer-76.hermes-workspace;
      hermesState = "${config.services.hermes-agent.stateDir}/.hermes";
      webuiPython = pkgs.python3.withPackages (ps: [
        ps.pyyaml
        ps.cryptography
      ]);
    in
    lib.mkIf cfg.enable {
      systemd.services.hermes-workspace = {
        description = "Hermes WebUI — nesquena/hermes-webui";
        wantedBy = [ "multi-user.target" ];
        after = [
          "network.target"
          "hermes-agent.service"
        ];

        environment = {
          HERMES_WEBUI_PORT = toString cfg.port;
          HERMES_WEBUI_HOST = cfg.host;
          HERMES_WEBUI_AGENT_DIR = config.services.hermes-agent.stateDir;
          HERMES_WEBUI_PYTHON = "${webuiPython}/bin/python";
          HERMES_HOME = hermesState;
          PYTHONDONTWRITEBYTECODE = "1";
        };

        serviceConfig = {
          Type = "simple";
          User = "t0psh31f";
          Group = "users";
          WorkingDirectory = cfg.workspaceDir;
          ExecStart = "${webuiPython}/bin/python ${cfg.workspaceDir}/server.py";
          EnvironmentFile = "${hermesState}/.env";
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };

      networking.firewall.allowedTCPPorts = [ cfg.port ];
    };
}
