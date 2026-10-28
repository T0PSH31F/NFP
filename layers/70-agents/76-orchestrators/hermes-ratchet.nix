# Tier: 76-orchestrators
# Module: hermes-ratchet.nix
# Purpose: Autonomous Karpathy Ratchet Harness for Hermes & Pi.
# Option Path: layers.layer-76.orchestrators.hermes-ratchet
# Enabling Host Tags: ai-agent, agent-orchestrator, homelab
# RAM Footprint: light (<100MB)
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.layers.layer-76.orchestrators.hermes-ratchet;
  ratchetScript = pkgs.writeShellApplication {
    name = "hermes-ratchet";
    runtimeInputs = with pkgs; [
      python3
      git
      nix
      coreutils
      procps
    ];
    text = ''
      exec ${pkgs.python3}/bin/python3 ${./hermes-ratchet.py} "$@"
    '';
  };
in
{
  options.layers.layer-76.orchestrators.hermes-ratchet = {
    enable = mkEnableOption "Hermes Autonomous Karpathy Ratchet Harness Daemon";

    interval = mkOption {
      type = types.int;
      default = 180;
      description = "Poll interval in seconds between autonomous task ratchet cycles";
    };

    maxRamPercent = mkOption {
      type = types.float;
      default = 75.0;
      description = "Maximum RAM usage percentage threshold before skipping autonomous cycles";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ ratchetScript ];

    systemd.services.hermes-ratchet = {
      description = "Hermes Autonomous Karpathy Ratchet Harness Daemon";
      after = [
        "network.target"
        "pi-durable-daemon.service"
        "hermes-agent.service"
      ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        HERMES_MAX_RAM_PCT = toString cfg.maxRamPercent;
        PI_A2A_URL = "http://127.0.0.1:8089/v1/delegate";
        NFP_REPO_ROOT = "/home/t0psh31f/Clan/NFP";
        NFP_TODO_FILE = "/home/t0psh31f/Notes/EverOS/todo.md";
        NFP_TODO_BIN = "/home/t0psh31f/.local/bin/nfp-todo";
        GLADOS_TTS_BIN = "/home/t0psh31f/.local/bin/glados-tts-cli";
      };

      serviceConfig = {
        Type = "simple";
        User = "t0psh31f";
        Group = "users";
        ExecStart = "${ratchetScript}/bin/hermes-ratchet --interval ${toString cfg.interval}";
        Restart = "always";
        RestartSec = 15;
        Nice = 15;
        IOSchedulingClass = "idle";
      };
    };
  };
}
