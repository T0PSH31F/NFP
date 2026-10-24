# Noctalia Hyprland Desktop Experience Adapter
# Activates when: layers.desktop.experience = "noctalia-hyprland"
#
# Responsibilities:
#   - Enable the Noctalia shell subsystem (layers.layer-40.desktop.noctalia)
#   - Inject $ipc = "noctalia msg" into Hyprland (mkForce overrides keybinds default)
#   - Register noctalia layer rules + keybinds specific to the noctalia shell
#   - Ensure cache/experience directories exist at graphical-session-pre
#
# Nothing here bleeds into other experiences (no-op when exp != "noctalia-hyprland").
{
  config,
  lib,
  pkgs,
  osConfig ? config,
  ...
}:
let
  exp = osConfig.layers.desktop.experience or "none";
  isEnabled = exp == "noctalia" || exp == "noctalia-hyprland";
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

    services.displayManager.sessionPackages = [
      (
        (pkgs.writeTextFile {
          name = "noctalia-hyprland-wayland-session";
          destination = "/share/wayland-sessions/noctalia-hyprland.desktop";
          passthru.providedSessions = [ "noctalia-hyprland" ];
          text = ''
            [Desktop Entry]
            Name=Noctalia (Hyprland)
            Comment=Native Noctalia Shell v5 on Hyprland
            Exec=uwsm start hyprland-uwsm.desktop
            Type=Application
            DesktopNames=Hyprland
          '';
        })
        // {
          providedSessions = [ "noctalia-hyprland" ];
        }
      )
    ];
  };

  home =
    { config, lib, ... }:
    {
      config = lib.mkIf isEnabled {
        # ── IPC injection ────────────────────────────────────────────────
        # Override the neutral default from keybinds.nix so that all $ipc
        # bindings in keybinds.nix use "noctalia msg".
        wayland.windowManager.hyprland.settings."$ipc" = lib.mkForce "noctalia msg";

        xdg.configFile = {
          "hypr/experiences/noctalia.conf".text = ''
            # Noctalia Hyprland Experience Configuration
            $ipc = noctalia msg

            # Decoration — Noctalia Lightsaber Aura Shadow
            decoration {
              shadow {
                enabled = true
                range = 50
                offset = 0 4
                render_power = 10
                color = $primary
                color_inactive = 0x00000000
              }
            }

            # Layer rules
            layerrule = blur 1, match:namespace ^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd)$
            layerrule = blur_popups 1, match:namespace ^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd)$
            layerrule = no_anim 1, match:namespace ^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd)$
            layerrule = ignore_alpha 0.1, match:namespace ^noctalia-(notification|dock|osd)$

            # Keybindings — Noctalia shell actions
            bind = $mod, comma, exec, $ipc settings-toggle
            bind = $mod, A, exec, $ipc panel-toggle launcher
            bind = $mod, X, exec, $ipc panel-toggle control-center
            bind = $mod, Tab, exec, $ipc window-switcher
            bind = $mod SHIFT, L, exec, $ipc session lock
            bind = CTRL ALT, Delete, exec, $ipc panel-toggle session
            bind = $mod SHIFT, N, exec, $ipc notification-dnd-toggle
          '';

          "hypr/experiences/active-experience.conf".text = ''
            source = ${config.home.homeDirectory}/.config/hypr/experiences/noctalia.conf
          '';

          "hypr/experiences/wallpaper-hook.sh" = {
            executable = true;
            text = ''
              #!/usr/bin/env bash
              noctalia msg wallpaper-set "$1" 2>/dev/null || true
            '';
          };
        };
      };
    };
}
