{
  osConfig ? config,
  config,
  lib,
  ...
}:
let
  cfg = osConfig.layers.layer-40.desktop.hyprland;
in
{
  config = lib.mkIf cfg.enable {
    wayland.windowManager.hyprland.settings = {

      # ── Monitor Configuration ──────────────────────────────────────────
      # Sourced from nwg-displays (managed manually via GUI)
      # This sources ~/.config/hypr/monitors.conf

      # Monitor configuration defaults:
      # Explicit 1:1 scale on eDP-1 prevents Hyprland from guessing 1.5 fractional scaling
      # which clips the viewport to 1280x800 on a 1920x1200 panel.
      monitor = lib.mkDefault [
        "eDP-1,1920x1200@60,0x0,1"
        ",preferred,auto,1"
      ];

      # We leave 'monitor' and 'workspace' assignments empty here to allow
      # nwg-displays to take full control via the sourced file.
    };
  };
}
