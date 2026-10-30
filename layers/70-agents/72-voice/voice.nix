# Tier: 72-voice
# Module: voice.nix
# Purpose: Unified local STT (whisper.cpp) and TTS (Piper/XTTSv2) service stack.
# Option Path: layers.layer-72.voice.voice
# Enabling Host Tags: ai-agent, homelab, desktop
# RAM Footprint: heavy (>1GB)
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  imports = [
    (lib.mkRenamedOptionModule
      [ "services" "ai-services" "voice" "enable" ]
      [ "layers" "layer-72" "voice" "voice" "enable" ]
    )
  ];

  options.layers.layer-72.voice.voice = {
    enable = lib.mkEnableOption "Local STT and TTS services (Whisper, Piper, XTTSv2)";

    sttPort = lib.mkOption {
      type = lib.types.port;
      default = 8097;
      description = "Port for local whisper.cpp server";
    };

    ttsPort = lib.mkOption {
      type = lib.types.port;
      default = 8098;
      description = "Port for local Piper TTS wrapper or XTTSv2 server";
    };

    useXTTSv2 = lib.mkEnableOption "deploying XTTSv2-UI via OCI containers alongside Piper";
  };

  config =
    let
      cfg = config.layers.layer-72.voice.voice;
    in
    lib.mkIf cfg.enable {
      environment.systemPackages = with pkgs; [
        piper-tts
        whisper-cpp
      ];

      # Whisper.cpp HTTP Server
      systemd.services.whisper-server = {
        description = "Local STT Server using whisper.cpp";
        wantedBy = [ "multi-user.target" ];
        after = [
          "network-online.target"
          "nss-lookup.target"
        ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          ExecStart = "${pkgs.whisper-cpp}/bin/whisper-server -m /var/lib/whisper/ggml-base.en.bin --port ${toString cfg.sttPort}";
          Restart = "always";
          RestartSec = 5;
          StateDirectory = "whisper";
        };
        preStart = ''
          mkdir -p /var/lib/whisper
          if [ ! -f /var/lib/whisper/ggml-base.en.bin ] || [ ! -s /var/lib/whisper/ggml-base.en.bin ]; then
            echo "Downloading Whisper model (ggml-base.en.bin)..."
            for i in 1 2 3 4 5; do
              if ${pkgs.curl}/bin/curl -L -f --retry 3 --retry-delay 5 -o /var/lib/whisper/ggml-base.en.bin "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin"; then
                break
              fi
              echo "Attempt $i failed, retrying in 5s..." >&2
              sleep 5
            done
          fi
          if [ ! -f /var/lib/whisper/ggml-base.en.bin ] || [ ! -s /var/lib/whisper/ggml-base.en.bin ]; then
            echo "Failed to verify ggml-base.en.bin (missing or empty)" >&2
            rm -f /var/lib/whisper/ggml-base.en.bin
            exit 1
          fi
        '';
      };

      virtualisation.oci-containers.containers.xttsv2 = lib.mkIf cfg.useXTTSv2 {
        image = "ghcr.io/coqui-ai/xtts-streaming-server:latest";
        ports = [ "${toString cfg.ttsPort}:8020" ];
        volumes = [ "xttsv2-models:/models" ];
        environment = {
          MODEL_PATH = "/models";
        };
      };

      networking.firewall.allowedTCPPorts = [ cfg.sttPort ] ++ (lib.optional cfg.useXTTSv2 cfg.ttsPort);

      environment.persistence."/persist" =
        lib.mkIf (config.layers.layer-10.system.config.impermanence.enable or false)
          {
            directories = [
              {
                directory = "/var/lib/whisper";
                mode = "0750";
              }
            ];
          };
    };
}
