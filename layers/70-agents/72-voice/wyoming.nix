# Tier: 72-voice
# Module: wyoming.nix
# Purpose: Wyoming protocol satellite & server stack (piper, faster-whisper, openwakeword).
# Option Path: services.wyoming-services
# Enabling Host Tags: ai-agent, homelab
# RAM Footprint: medium (300MB-1GB)
{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.services.wyoming-services;
in
{
  options.services.wyoming-services = {
    enable = mkEnableOption "Wyoming protocol voice services";

    faster-whisper = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Faster Whisper STT service";
      };
      model = mkOption {
        type = types.str;
        default = "tiny-int8";
      };
    };

    piper = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Piper TTS service";
      };
      voice = mkOption {
        type = types.str;
        default = "en_US-lessac-medium";
      };
    };

    openwakeword = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable OpenWakeWord service";
      };
    };
  };

  config = mkIf cfg.enable {
    services.wyoming = {
      faster-whisper.servers.local = mkIf cfg.faster-whisper.enable {
        enable = true;
        uri = "tcp://0.0.0.0:10300";
        inherit (cfg.faster-whisper) model;
        language = "en";
        device = "cpu";
        zeroconf.enable = false;
      };

      piper.servers.local = mkIf cfg.piper.enable {
        enable = true;
        uri = "tcp://0.0.0.0:10200";
        inherit (cfg.piper) voice;
        zeroconf.enable = false;
      };

      openwakeword.enable = cfg.openwakeword.enable;
    };

    systemd.services.wyoming-faster-whisper-local = mkIf cfg.faster-whisper.enable {
      serviceConfig.Restart = mkForce "always";
    };
    systemd.services.wyoming-piper-local = mkIf cfg.piper.enable {
      serviceConfig.Restart = mkForce "always";
    };
    systemd.services.wyoming-openwakeword = mkIf cfg.openwakeword.enable {
      serviceConfig.Restart = mkForce "always";
    };

    networking.firewall = {
      allowedTCPPorts = [
        10200 # piper
        10300 # faster-whisper
        10400 # openwakeword
      ];
    };
  };
}
