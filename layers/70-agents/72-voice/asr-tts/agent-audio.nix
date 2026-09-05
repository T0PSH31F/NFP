# Tier: 72-voice
# Module: asr-tts/agent-audio.nix
# Purpose: Home-Manager package collection for CLI audio tooling and voice engines.
# Option Path: layers.layer-70.agent.asr-tts
# Enabling Host Tags: ai-agent, desktop
# RAM Footprint: light (<300MB)
{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    (lib.mkAliasOptionModule
      [ "layers" "layer-70" "agent" "asr-tts" ]
      [ "layers" "layer-72" "voice" "agent-audio" ]
    )
  ];

  options.layers.layer-72.voice.agent-audio = {
    enable = lib.mkEnableOption "local ASR/TTS voice agent packages";
  };

  home = lib.mkIf config.layers.layer-72.voice.agent-audio.enable {
    home.packages = with pkgs; [
      piper-tts
      whisper-cpp
      wyoming-openwakeword
      espeak-ng
      portaudio
      alsa-lib

      (python3.withPackages (
        ps: with ps; [
          kokoro
          pyaudio
          sounddevice
          numpy
          requests
          openai
          wyoming
        ]
      ))
    ];
  };
}
