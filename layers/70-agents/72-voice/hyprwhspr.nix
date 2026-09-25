# Tier: 72-voice
# Module: hyprwhspr.nix
# Purpose: Hyprland / Wayland voice-to-text daemon via hyprwhspr
# Option Path: layers.layer-72.voice.hyprwhspr
# Enabling Host Tags: desktop, ai-agent
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.layers.layer-72.voice.hyprwhspr;
in
{
  options.layers.layer-72.voice.hyprwhspr = {
    enable = mkEnableOption "hyprwhspr — Wayland push-to-talk speech-to-text service";
  };

  config = mkIf cfg.enable {
    services.hyprwhspr-rs.enable = true;
    environment.systemPackages = [ pkgs.hyprwhspr-rs ];
  };
}
