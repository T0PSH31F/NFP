# Noctalia Hyprland Desktop Experience Adapter
{
  config,
  lib,
  pkgs,
  osConfig ? config,
  ...
}:
let
  exp = osConfig.layers.desktop.experience or "none";
  isEnabled = exp == "noctalia-hyprland";
in
{
  options.layers.desktop.noctalia-hyprland = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Noctalia Hyprland desktop experience adapter";
    };
  };

  nixos = lib.mkIf isEnabled {
    layers.layer-40.desktop.noctalia.enable = true;
  };

  home =
    { config, lib, ... }:
    {
      config = lib.mkIf isEnabled {
        xdg.configFile."hypr/experiences/noctalia.conf".text = ''
          # Noctalia Hyprland Experience Configuration
          $ipc = noctalia msg

          # Layer rules
          layerrule = blur 1, match:namespace ^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd)$
          layerrule = blur_popups 1, match:namespace ^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd)$
          layerrule = no_anim 1, match:namespace ^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd)$
          layerrule = ignore_alpha 0.1, match:namespace ^noctalia-(notification|dock|osd)$

          # Keybindings
          bind = $mod, comma, exec, $ipc settings-toggle
          bind = $mod, A, exec, $ipc panel-toggle launcher
          bind = $mod, X, exec, $ipc panel-toggle control-center
          bind = $mod, Tab, exec, $ipc window-switcher
          bind = $mod SHIFT, L, exec, $ipc session lock
          bind = CTRL ALT, Delete, exec, $ipc panel-toggle session
          bind = $mod SHIFT, N, exec, $ipc notification-dnd-toggle
        '';

        xdg.configFile."hypr/experiences/active-experience.conf".text = ''
          source = ${config.home.homeDirectory}/.config/hypr/experiences/noctalia.conf
        '';

        xdg.configFile."hypr/experiences/wallpaper-hook.sh" = {
          executable = true;
          text = ''
            #!/usr/bin/env bash
            noctalia msg wallpaper-set "$1" 2>/dev/null || true
          '';
        };

        systemd.user.services.noctalia-experience-dirs = {
          Unit = {
            Description = "Ensure Noctalia HVE cache and experience directories exist";
            Before = [ "graphical-session-pre.target" ];
          };
          Install = {
            WantedBy = [ "graphical-session-pre.target" ];
          };
          Service = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${pkgs.bash}/bin/bash -c 'mkdir -p %h/.config/hypr/experiences %h/.cache/noctalia/HVE'";

          };
        };
      };
    };
}
