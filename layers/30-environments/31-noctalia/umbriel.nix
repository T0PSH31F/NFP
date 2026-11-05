# Noctalia Umbriel Desktop Experience Adapter
# Activates when: layers.desktop.experience = "noctalia-umbriel"
#
# Responsibilities:
#   - Enable the Umbriel compositor (layers/40-desktop/41-compositors/umbriel/)
#   - Enable the Noctalia shell bound to Umbriel IPC
#   - Register Umbriel session .desktop file for DM session picker
#   - Inject $ipc = "noctalia msg" for keybind compatibility
#
# All Noctalia-specific env vars, cache paths, and IPC hooks live HERE.
# Switching away from this experience leaves Umbriel and Noctalia both off.
{
  config,
  lib,
  pkgs,
  inputs,
  osConfig ? config,
  ...
}:
let
  exp = osConfig.layers.desktop.experience or "none";
  isEnabled = exp == "noctalia" || exp == "noctalia-umbriel";
in
{
  nixos = lib.mkIf isEnabled {
    # Enable the Noctalia shell subsystem
    layers.layer-40.desktop.noctalia.enable = true;

    environment.systemPackages = [
      inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

    # Enable Umbriel compositor
    layers.desktop.compositors.umbriel.enable = true;
  };

  home =
    { lib, ... }:
    {
      config = lib.mkIf isEnabled {
        # IPC injection — Umbriel uses the same noctalia msg IPC as Hyprland
        wayland.windowManager.hyprland.settings."$ipc" = lib.mkForce "noctalia msg";

        xdg.configFile = {
          "umbriel/config.toml".text = osConfig.environment.etc."xdg/umbriel/config.toml".text;

          "uwsm/env-umbriel".text = ''
            export XDG_CURRENT_DESKTOP=Umbriel
            export XDG_SESSION_TYPE=wayland
            export XDG_SESSION_DESKTOP=Umbriel
            export WLR_NO_HARDWARE_CURSORS=1
            export WLR_DRM_DEVICES=/dev/dri/card1:/dev/dri/card0
          '';

          "hypr/experiences/wallpaper-hook.sh" = {
            executable = true;
            text = ''
              #!/usr/bin/env bash
              noctalia msg wallpaper-set "$1" 2>/dev/null || true
            '';
          };
        }
        // (lib.mapAttrs' (
          n: v:
          lib.nameValuePair (lib.removePrefix "xdg/" n) {
            inherit (v) text;
          }
        ) (lib.filterAttrs (n: _: lib.hasPrefix "xdg/umbriel/presets/" n) osConfig.environment.etc));
      };
    };
}
