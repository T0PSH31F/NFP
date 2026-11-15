# Tier: 70-agents / jev
# Module: recovery-organizer.nix
# Purpose: Non-destructive post-recovery file organizer, local SLM/Jev classifier, and AES-256 PII Canary Vault monitor.
# Option Path: services.recovery-organizer
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.recovery-organizer;
  organizerCli = pkgs.writeShellScriptBin "nfp-recovery-organize" ''
    export PATH="${
      lib.makeBinPath [
        pkgs.p7zip
        pkgs.exiftool
        pkgs.poppler-utils
        pkgs.inotify-tools
        pkgs.coreutils
      ]
    }:$PATH"
    export JEV_ENGINE_URL="${cfg.jevEngineUrl}"
    export OLLAMA_URL="${cfg.ollamaUrl}"
    export OLLAMA_MODEL="${cfg.ollamaModel}"
    export NFP_CANARY_PORT="${toString cfg.canaryPort}"
    exec ${pkgs.python3}/bin/python3 ${./recovery_organizer.py} organize \
      --source "${cfg.sourceDir}" \
      --dest "${cfg.destDir}" \
      --vault-dir "${cfg.vaultDir}" \
      --password-file "${cfg.passwordFile}" \
      --canary-host "${cfg.canaryHost}" \
      "$@"
  '';
in
{
  options.services.recovery-organizer = {
    enable = lib.mkEnableOption "NFP Post-Recovery File Organizer and PII Canary Vault";

    sourceDir = lib.mkOption {
      type = lib.types.str;
      default = "/run/media/t0psh31f/NATE DRIVE/Recovered_Hitachi_2TB";
      description = "Source directory containing raw recovered files (read-only/non-destructive).";
    };

    destDir = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/drives/backup-1/Recovered_Organized";
      description = "Destination root for categorized, renamed, metadata-tagged files.";
    };

    vaultDir = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/drives/backup-1/PII_Vault";
      description = "Directory holding password-protected PII ZIP archive and canary traps.";
    };

    passwordFile = lib.mkOption {
      type = lib.types.str;
      default = "/persist/secrets/pii_vault.pass";
      description = "Path to root/owner-readable file holding AES-256 PII vault password.";
    };

    canaryHost = lib.mkOption {
      type = lib.types.str;
      default = "luffy.nfp.nix";
      description = "Host address embedded in canary token beacons.";
    };

    canaryPort = lib.mkOption {
      type = lib.types.port;
      default = 20139;
      description = "HTTP listener port for PII canary beacons.";
    };

    jevEngineUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://127.0.0.1:20130";
      description = "Jev Decision Engine endpoint.";
    };

    ollamaUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://127.0.0.1:11434";
      description = "Local Ollama SLM endpoint.";
    };

    ollamaModel = lib.mkOption {
      type = lib.types.str;
      default = "huihui_ai/qwen2.5-abliterate:7b";
      description = "Local Ollama model used to classify/title ambiguous recovered documents.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      organizerCli
      pkgs.inotify-tools
    ];

    systemd.tmpfiles.rules = [
      "d ${cfg.vaultDir} 0700 t0psh31f users -"
      "d ${cfg.destDir} 0775 t0psh31f media -"
    ];

    systemd.services.nfp-canary-watch = {
      description = "NFP PII Vault Filesystem & HTTP Canary Alert Daemon";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "local-fs.target"
      ];
      unitConfig.RequiresMountsFor = [ cfg.vaultDir ];
      path = [
        pkgs.inotify-tools
        pkgs.coreutils
      ];
      environment = {
        NFP_CANARY_PORT = toString cfg.canaryPort;
        GLADOS_ALERT_BIN = "/home/t0psh31f/.local/bin/glados-alert.sh";
      };
      serviceConfig = {
        ExecStart = "${pkgs.python3}/bin/python3 ${./recovery_organizer.py} watch-canary --vault-dir ${lib.escapeShellArg cfg.vaultDir} --port ${toString cfg.canaryPort}";
        Restart = "always";
        RestartSec = "5s";
      };
    };

    networking.firewall.allowedTCPPorts = [ cfg.canaryPort ];
  };
}
