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

    # Register Wayland session entry for DM session picker (no-reboot switching)
    services.displayManager.sessionPackages = [
      (
        (pkgs.writeTextFile {
          name = "noctalia-umbriel-wayland-session";
          destination = "/share/wayland-sessions/noctalia-umbriel.desktop";
          passthru.providedSessions = [ "noctalia-umbriel" ];
          text = ''
            [Desktop Entry]
            Name=Noctalia (Umbriel)
            Comment=Noctalia Shell v5 on Umbriel compositor
            Exec=uwsm start umbriel-uwsm.desktop
            Type=Application
            DesktopNames=Umbriel
          '';
        })
        // {
          providedSessions = [ "noctalia-umbriel" ];
        }
      )
    ];
  };

  home =
    { lib, ... }:
    {
      config = lib.mkIf (exp == "noctalia-umbriel") {
        # IPC injection — Umbriel uses the same noctalia msg IPC as Hyprland
        wayland.windowManager.hyprland.settings."$ipc" = lib.mkForce "noctalia msg";

        xdg.configFile."umbriel/config.toml".text = osConfig.environment.etc."xdg/umbriel/config.toml".text;

        xdg.configFile."hypr/experiences/wallpaper-hook.sh" = {
          executable = true;
          text = ''
            #!/usr/bin/env bash
            noctalia msg wallpaper-set "$1" 2>/dev/null || true
          '';
        };
      };
    };
}
