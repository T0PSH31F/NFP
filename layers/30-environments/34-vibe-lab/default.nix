# Custom Vibe-Coding Quickshell Lab Experience Adapter
# Activates when: layers.desktop.experience = "custom-vibe-quickshell"
#
# Purpose: Live QML hot-reload workspace for building custom bars, widgets,
# and launchers without switching to a full pre-defined shell.
#
# Compositor: whatever layers.desktop.compositor resolves to (defaults to hyprland).
# IPC: Quickshell IPC ("qs ipc").
# Theming: User-managed via ~/.config/quickshell/active/theme.qml (no noctalia deps).
#
# Zero bleed: no Noctalia cache or socket references.
{
  config,
  lib,
  pkgs,
  osConfig ? config,
  ...
}:
let
  exp = osConfig.layers.desktop.experience or "none";
  isEnabled = exp == "custom-vibe-quickshell";
in
{
  nixos = lib.mkIf isEnabled {
    # Register session for DM session picker (no-reboot switching)
    services.displayManager.sessionPackages = [
      (
        (pkgs.writeTextFile {
          name = "custom-vibe-quickshell-wayland-session";
          destination = "/share/wayland-sessions/custom-vibe-quickshell.desktop";
          passthru.providedSessions = [ "custom-vibe-quickshell" ];
          text = ''
            [Desktop Entry]
            Name=Vibe Quickshell Lab
            Comment=Live QML hot-reload workspace on Hyprland
            Exec=${pkgs.uwsm}/bin/uwsm start -F -N "Vibe Quickshell Lab" -D Hyprland -C "Live QML hot-reload workspace on Hyprland" -- /run/current-system/sw/bin/Hyprland
            Type=Application
            DesktopNames=Hyprland
          '';
        })
        // {
          providedSessions = [ "custom-vibe-quickshell" ];
        }
      )
    ];

    environment.systemPackages = [
      pkgs.quickshell # Quickshell QML compositor shell
      pkgs.qt6.qtdeclarative # QML runtime + qmlls LSP
      pkgs.qt6.qttools # Qt6 tools (qmlformat, qmllint)
    ];
  };

  home =
    { lib, ... }:
    {
      config = lib.mkIf isEnabled {
        # Quickshell IPC
        wayland.windowManager.hyprland.settings."$ipc" = lib.mkForce "qs ipc";

        # Scaffold the live-reload workspace
        home.activation.vibeQuickshellScaffold = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                    mkdir -p $HOME/.config/quickshell/active
                    if [ ! -f "$HOME/.config/quickshell/active/shell.qml" ]; then
                      cat > "$HOME/.config/quickshell/active/shell.qml" << 'EOF'
          // Vibe Quickshell Lab — starter shell.qml
          // Edit this file; quickshell will hot-reload on save.
          import Quickshell
          import Quickshell.Wayland
          import QtQuick

          ShellRoot {
              PanelWindow {
                  anchors {
                      top: true; left: true; right: true
                  }
                  implicitHeight: 32
                  color: "#cc1e1e2e"
                  Text {
                      anchors.centerIn: parent
                      text: "🚀 Vibe Quickshell Lab — edit ~/.config/quickshell/active/shell.qml"
                      color: "#cdd6f4"
                      font.pixelSize: 13
                  }
              }
          }
          EOF
                    fi
        '';

        # qmlls LSP config so editors find the Quickshell QML modules
        xdg.configFile."qtcreator/qmlls.ini".text = ''
          [Environment]
          QML_IMPORT_PATH=${pkgs.quickshell}/lib/qml
        '';

        # Hot-reload watcher: restart quickshell when active/ changes
        systemd.user.services.quickshell-hot-reload = {
          Unit = {
            Description = "Quickshell hot-reload watcher";
            After = [ "graphical-session.target" ];
            PartOf = [ "graphical-session.target" ];
          };
          Install = {
            WantedBy = [ "graphical-session.target" ];
          };
          Service = {
            ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.inotify-tools}/bin/inotifywait -m -r -e close_write %h/.config/quickshell/active/ | while read; do systemctl --user restart quickshell.service; done'";
            Restart = "on-failure";
          };
        };
      };
    };
}
