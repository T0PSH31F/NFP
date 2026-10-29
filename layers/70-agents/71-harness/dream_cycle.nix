# Tier: 71-harness
# Module: dream_cycle.nix
# Purpose: Nightly Reflection/Dream Cycle daemon and timer for Jarvis self-improvement.
# Option Path: layers.layer-71.harness.dream-cycle
# Enabling Host Tags: ai-agent, agent-orchestrator, workstation
# RAM Footprint: light (<300MB)
{
  config,
  lib,
  pkgs,
  osConfig ? config,
  ...
}:
with lib;
let
  cfg = config.layers.layer-71.harness.dream-cycle;
  primaryUser = osConfig.layers.meta.primaryUser or "t0psh31f";

  dreamScript = pkgs.writeShellScriptBin "nfp-dream-cycle" ''
    set -euo pipefail
    exec ${pkgs.python3}/bin/python3 ${./dream_miner.py} "$@"
  '';
in
{
  imports = [
    (lib.mkAliasOptionModule
      [ "layers" "layer-71" "harness" "dream_cycle" ]
      [ "layers" "layer-71" "harness" "dream-cycle" ]
    )
    (lib.mkAliasOptionModule
      [ "services" "jarvis-dream-cycle" ]
      [ "layers" "layer-71" "harness" "dream-cycle" ]
    )
  ];

  options.layers.layer-71.harness.dream-cycle = {
    enable = mkEnableOption "Jarvis Nightly Reflection & Dream Cycle Daemon";

    calendar = mkOption {
      type = types.str;
      default = "*-*-* 03:00:00";
      description = "Systemd OnCalendar expression for the nightly dream cycle (default: 3:00 AM).";
    };

    dbPath = mkOption {
      type = types.str;
      default = "/home/${primaryUser}/.local/share/pi-durable/state.sqlite";
      description = "SQLite database path containing agent execution logs.";
    };

    repoDir = mkOption {
      type = types.str;
      default = "/home/${primaryUser}/Clan/NFP";
      description = "Path to the NFP Git repository root for deterministic verification gates.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      dreamScript
    ];

    systemd.services.nfp-jarvis-dream-cycle = {
      description = "NFP Jarvis Nightly Reflection & Self-Improvement Dream Cycle";
      after = [ "network.target" ];
      path = [
        pkgs.bash
        pkgs.coreutils
        pkgs.git
        pkgs.nix
        pkgs.deadnix
        pkgs.statix
        pkgs.jq
        pkgs.ripgrep
        pkgs.python3
        pkgs.piper-tts
        pkgs.pipewire
      ];
      environment = {
        HOME = "/home/${primaryUser}";
        USER = primaryUser;
        PI_STATE_DB = cfg.dbPath;
        SCREENPIPE_DB = "/home/${primaryUser}/.local/share/jarvis/screenpipe.db";
        USER_PROFILE_PATH = "${cfg.repoDir}/.agents/memory/user_profile.md";
        NFP_REPO_DIR = cfg.repoDir;
      };
      serviceConfig = {
        Type = "oneshot";
        User = primaryUser;
        Group = "users";
        WorkingDirectory = cfg.repoDir;
        ExecStart = "${pkgs.python3}/bin/python3 ${./dream_miner.py} --run-nightly";
        Restart = "no";
        PrivateTmp = true;
      };
    };

    systemd.timers.nfp-jarvis-dream-cycle = {
      description = "NFP Jarvis Nightly Reflection & Dream Cycle Timer (03:00 AM)";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.calendar;
        Persistent = true;
        Unit = "nfp-jarvis-dream-cycle.service";
      };
    };
  };
}
