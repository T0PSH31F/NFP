# Tier: 73-memory
# Module: task_watcher.nix
# Purpose: Super + N Task Watcher & Proactive Life/Business Orchestrator.
# Option Path: layers.layer-73.memory.task-watcher
# Enabling Host Tags: ai-agent, workstation, homelab
# RAM Footprint: light (<100MB)
{
  config,
  lib,
  pkgs,
  osConfig ? config,
  ...
}:
with lib;
let
  cfg = config.layers.layer-73.memory.task-watcher;
  primaryUser = osConfig.layers.meta.primaryUser or "t0psh31f";

  taskWatcherScript = pkgs.writeShellScriptBin "nfp-task-watcher" ''
    set -euo pipefail
    exec ${pkgs.python3}/bin/python3 ${./task_watcher.py} "$@"
  '';
in
{
  imports = [
    (lib.mkAliasOptionModule
      [ "layers" "layer-73" "memory" "task_watcher" ]
      [ "layers" "layer-73" "memory" "task-watcher" ]
    )
    (lib.mkAliasOptionModule
      [ "services" "task-watcher" ]
      [ "layers" "layer-73" "memory" "task-watcher" ]
    )
  ];

  options.layers.layer-73.memory.task-watcher = {
    enable = mkEnableOption "Super + N Task Watcher & Proactive Life Orchestrator";

    tasklistFile = mkOption {
      type = types.str;
      default = "/home/${primaryUser}/Clan/NFP/tasklist.md";
      description = "Path to the canonical markdown tasklist file watched by the daemon.";
    };

    piDurableUrl = mkOption {
      type = types.str;
      default = "http://127.0.0.1:8089";
      description = "Endpoint of the local Pi durable autonomous worker daemon.";
    };

    everosUrl = mkOption {
      type = types.str;
      default = "http://127.0.0.1:8092";
      description = "Endpoint of the local EverOS memory engine for consolidation.";
    };

    pollInterval = mkOption {
      type = types.int;
      default = 15;
      description = "Polling interval in seconds between file scans.";
    };

    gladosVoice = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to vocalize task pick-up, completions, and approval gates via GLaDOS voice.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      taskWatcherScript
    ];

    systemd.tmpfiles.rules = [
      "d /home/${primaryUser}/.local/share/nfp-task-watcher 0775 ${primaryUser} users -"
    ];

    systemd.services.nfp-task-watcher = {
      description = "NFP Super + N Task Watcher & Proactive Life/Business Orchestrator";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "pi-durable-daemon.service"
      ];
      path = [
        pkgs.bash
        pkgs.coreutils
        pkgs.git
        pkgs.python3
        pkgs.piper-tts
        pkgs.pipewire
      ];
      environment = {
        HOME = "/home/${primaryUser}";
        USER = primaryUser;
        TASKLIST_PATH = cfg.tasklistFile;
        PI_DURABLE_URL = cfg.piDurableUrl;
        EVEROS_URL = cfg.everosUrl;
        POLL_INTERVAL = toString cfg.pollInterval;
      };
      serviceConfig = {
        ExecStart = "${pkgs.python3}/bin/python3 ${./task_watcher.py} --watch --file ${cfg.tasklistFile} --interval ${toString cfg.pollInterval}${
          optionalString (!cfg.gladosVoice) " --no-voice"
        }";
        Restart = "always";
        RestartSec = "5s";
        User = primaryUser;
        Group = "users";
        WorkingDirectory = "/home/${primaryUser}/Clan/NFP";
        PrivateTmp = false;
      };
    };
  };
}
