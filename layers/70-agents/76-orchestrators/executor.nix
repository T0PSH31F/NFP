# Tier: 76-orchestrators
# Module: executor.nix
# Purpose: Authoritative Executor (Agent Executor / AX) integration gateway and task orchestration daemon.
# Option Path: layers.layer-76.orchestrators.executor
# Enabling Host Tags: agent-orchestrator, homelab
# RAM Footprint: light (<300MB)
{
  config,
  lib,
  pkgs,
  inputs ? { },
  ...
}:
with lib;
{
  imports = [
    (lib.mkRenamedOptionModule
      [ "services" "ai-services" "executor" "enable" ]
      [ "layers" "layer-76" "orchestrators" "executor" "enable" ]
    )
    (lib.mkRenamedOptionModule
      [ "services" "ai-services" "executor" "port" ]
      [ "layers" "layer-76" "orchestrators" "executor" "port" ]
    )
    (lib.mkRenamedOptionModule
      [ "layers" "layer-20" "services" "executor" "enable" ]
      [ "layers" "layer-76" "orchestrators" "executor" "enable" ]
    )
    (lib.mkRenamedOptionModule
      [ "layers" "layer-20" "services" "executor" "port" ]
      [ "layers" "layer-76" "orchestrators" "executor" "port" ]
    )
  ];

  options.layers.layer-76.orchestrators.executor = {
    enable = mkEnableOption "Agent Executor (AX) authoritative integration gateway";

    port = mkOption {
      type = types.port;
      default = 8097;
      description = "Port for Executor integration gateway API";
    };

    host = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Listen host address for Executor gateway (127.0.0.1 or Tailnet IP)";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/executor";
      description = "Persistent data directory for Executor state and logs";
    };
  };

  config =
    let
      cfg = config.layers.layer-76.orchestrators.executor;
      primaryUser = config.layers.meta.primaryUser or "t0psh31f";
      llmPkgs = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system} or { };
      executorPkg =
        llmPkgs.ax or (pkgs.ax or (pkgs.writeShellScriptBin "executor" ''
          PORT="''${EXECUTOR_PORT:-8097}"
          HOST="''${EXECUTOR_HOST:-127.0.0.1}"
          echo "Starting fallback Executor daemon on ''${HOST}:''${PORT}..."
          exec ${pkgs.python3}/bin/python3 -m http.server "$PORT" --bind "$HOST"
        '')
        );
    in
    mkIf cfg.enable {
      systemd.tmpfiles.rules = [
        "d ${cfg.dataDir} 0755 ${primaryUser} users -"
      ];

      systemd.services.executor = {
        description = "Agent Executor (AX) Integration Gateway";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          User = primaryUser;
          Group = "users";
          ExecStart = "${lib.getExe executorPkg} --port ${toString cfg.port} --host ${cfg.host}";
          Restart = "always";
          RestartSec = 5;
          WorkingDirectory = cfg.dataDir;
          Environment = [
            "EXECUTOR_PORT=${toString cfg.port}"
            "EXECUTOR_HOST=${cfg.host}"
            "HOME=/home/${primaryUser}"
          ];
          # Hardening
          ProtectSystem = "full";
          ProtectHome = "read-only";
          PrivateTmp = true;
        };
      };
    };
}
