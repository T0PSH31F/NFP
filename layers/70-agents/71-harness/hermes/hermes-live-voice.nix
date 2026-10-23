# Hermes Live Voice — Durable 24/7 Voice Agent Layer (Hermes Front Door + Pi A2A Worker)
#
# Provides:
# - Continuous low-latency voice gateway (:8880) with sentence-chunked Piper TTS (< 1.5s budget)
# - Watchdog heartbeat service & timer (notifies on failure via GLaDOS TTS + journald)
# - Nightly golden-path verification service & timer (models, streaming chat, tool call, STT->LLM->TTS)
# - Persistent state in /persist and user linger for 24/7 operation
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.layers.layer-76.hermes-live-voice;
  voiceDaemon = ../../72-voice/hermes-voice-daemon.py;
  kongBaseUrl =
    if (config.services.ai-services.kong-gateway.enable or false) then
      "http://127.0.0.1:${toString (config.services.ai-services.kong-gateway.proxyPort or 8090)}"
    else
      "http://sanji.nfp.nix:8090";
  jevBaseUrl = "http://127.0.0.1:${
    toString (config.layers.layer-78.llm-routers.jev-router-plugin.port or 20127)
  }";
in
{
  options.layers.layer-76.hermes-live-voice = {
    enable = mkEnableOption "Hermes 24/7 Durable Voice Agent (Hermes front door + Pi worker)";

    port = mkOption {
      type = types.port;
      default = 8880;
      description = "Port for Hermes Live Voice gateway";
    };
  };

  config = mkIf cfg.enable {
    # Ensure user units survive logout on 24/7 hosts
    users.users.t0psh31f.linger = mkDefault true;
    users.users.hermes.linger = mkDefault true;

    environment.systemPackages = [
      (pkgs.writeShellScriptBin "hermes-live" ''
        exec ${pkgs.python3}/bin/python3 ${voiceDaemon} --serve --port ${toString cfg.port} "$@"
      '')
      (pkgs.writeShellScriptBin "nfp-voice-demo" ''
        exec ${pkgs.python3}/bin/python3 ${voiceDaemon} --demo --jev-url "${jevBaseUrl}" --kong-url "${kongBaseUrl}" "$@"
      '')
      (pkgs.writeShellScriptBin "nfp-voice-golden-test" ''
        exec ${pkgs.python3}/bin/python3 ${voiceDaemon} --golden-test --jev-url "${jevBaseUrl}" --kong-url "${kongBaseUrl}" "$@"
      '')
    ];

    systemd = {
      tmpfiles.rules = [
        "d /var/lib/hermes-voice 0750 hermes hermes -"
      ];

      services = {
        # 1. Durable 24/7 Voice Gateway Service
        hermes-live-gateway = {
          description = "Hermes + Pi 24/7 Durable Voice Agent Gateway";
          after = [
            "network-online.target"
            "hermes-agent.service"
            "jev-router-plugin.service"
          ];
          wants = [
            "network-online.target"
            "hermes-agent.service"
          ];
          wantedBy = [ "multi-user.target" ];
          path = with pkgs; [
            python3
            piper-tts
            espeak-ng
            curl
            coreutils
          ];

          serviceConfig = {
            ExecStart = "${pkgs.python3}/bin/python3 ${voiceDaemon} --serve --port ${toString cfg.port}";
            Restart = "always";
            RestartSec = 3;
            StateDirectory = "hermes-voice";
            StateDirectoryMode = "0750";
            EnvironmentFile = optional (
              config.sops ? templates && config.sops.templates ? "hermes-env"
            ) config.sops.templates."hermes-env".path;
            Environment = [
              "HERMES_HOME=/var/lib/hermes/.hermes"
              "HERMES_LIVE_PORT=${toString cfg.port}"
              "HERMES_VOICE_STATE_DIR=/var/lib/hermes-voice"
              "KONG_BASE_URL=${kongBaseUrl}"
              "JEV_BASE_URL=${jevBaseUrl}"
            ];
          };
        };

        # 2. Watchdog Heartbeat Service & Timer (notifies on failure)
        hermes-voice-watchdog = {
          description = "Hermes 24/7 Voice Agent & Router Stack Watchdog Heartbeat";
          after = [ "hermes-live-gateway.service" ];
          path = with pkgs; [
            curl
            jq
            coreutils
            util-linux
            systemd
          ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = pkgs.writeShellScript "hermes-voice-watchdog" ''
              set -euo pipefail
              STATE_FILE="/var/lib/hermes-voice/heartbeat.json"
              mkdir -p /var/lib/hermes-voice
              FAILURES=()

              if ! curl -sf --max-time 3 "http://127.0.0.1:${toString cfg.port}/health" >/dev/null 2>&1; then
                FAILURES+=("hermes-live-gateway:${toString cfg.port}")
              fi
              if ! curl -sf --max-time 3 "${jevBaseUrl}/health" >/dev/null 2>&1; then
                FAILURES+=("jev-router:${jevBaseUrl}")
              fi
              if ! curl -sf --max-time 3 "${kongBaseUrl}/health" >/dev/null 2>&1; then
                FAILURES+=("kong-gateway:${kongBaseUrl}")
              fi
              if ! curl -sf --max-time 3 "http://127.0.0.1:8089/healthz" >/dev/null 2>&1; then
                FAILURES+=("pi-durable-daemon:8089")
                systemctl restart pi-durable-daemon.service >/dev/null 2>&1 || true
              fi

              TS="$(date -Iseconds)"
              if [ "''${#FAILURES[@]}" -eq 0 ]; then
                printf '{"timestamp":"%s","status":"healthy","failures":[]}\n' "$TS" > "$STATE_FILE"
              else
                FAIL_STR="''${FAILURES[*]}"
                printf '{"timestamp":"%s","status":"degraded","failures":"%s"}\n' "$TS" "$FAIL_STR" > "$STATE_FILE"
                logger -t hermes-voice-watchdog -p daemon.err "[APERTURE SCIENCE ADVISORY] Voice/Router stack degraded: $FAIL_STR"
                if [ -x /home/t0psh31f/.local/bin/glados-tts-cli ]; then
                  /home/t0psh31f/.local/bin/glados-tts-cli "Advisory. A voice or router subsystem has failed its heartbeat check." >/dev/null 2>&1 || true
                fi
                exit 1
              fi
            '';
          };
        };

        # 3. Nightly Golden-Path E2E Verification Service & Timer
        nfp-voice-golden-test = {
          description = "Nightly Golden-Path Test (Models, Streaming Chat, Tool Call, STT->LLM->TTS)";
          after = [
            "network-online.target"
            "hermes-live-gateway.service"
            "jev-router-plugin.service"
          ];
          wants = [
            "network-online.target"
          ];
          path = with pkgs; [
            python3
            piper-tts
            espeak-ng
            curl
            coreutils
          ];
          serviceConfig = {
            Type = "oneshot";
            EnvironmentFile = optional (
              config.sops ? templates && config.sops.templates ? "hermes-env"
            ) config.sops.templates."hermes-env".path;
            ExecStart = "${pkgs.python3}/bin/python3 ${voiceDaemon} --golden-test --jev-url ${jevBaseUrl} --kong-url ${kongBaseUrl}";
          };
        };
      };

      timers = {
        hermes-voice-watchdog = {
          description = "Periodic Watchdog Heartbeat Timer for 24/7 Voice Agent";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnBootSec = "2m";
            OnUnitActiveSec = "2m";
            Unit = "hermes-voice-watchdog.service";
          };
        };

        nfp-voice-golden-test = {
          description = "Nightly Golden-Path Voice & Router Test Timer";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "*-*-* 03:15:00";
            Persistent = true;
            Unit = "nfp-voice-golden-test.service";
          };
        };
      };
    };

    # 4. Impermanence /persist state binding
    environment.persistence."/persist" =
      mkIf (config.layers.layer-10.system.config.impermanence.enable or false)
        {
          directories = [
            {
              directory = "/var/lib/hermes-voice";
              user = "hermes";
              group = "hermes";
              mode = "0750";
            }
          ];
        };

    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
