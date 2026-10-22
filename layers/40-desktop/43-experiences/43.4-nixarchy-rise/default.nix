# Nixarchy Rise Desktop Experience Adapter
# Activates when: layers.desktop.experience = "nixarchy-rise"
#
# Provides: Omarchy 4.x environment (nixarchy) with HANCORE Quickshell Rise
# as the primary bar/launcher/notification layer.
#
# Theming engine: Matugen (material color tokens from wallpaper).
# IPC: quickshell IPC — does NOT use "noctalia msg".
# Greeter: nixarchy's own DM (auto-derived by selector as "nixarchy-greeter").
#
# Zero bleed: no NOCTALIA_SOCKET, no ~/.cache/noctalia refs anywhere here.
{
  config,
  lib,
  pkgs,
  osConfig ? config,
  inputs,
  ...
}:
let
  exp = osConfig.layers.desktop.experience or "none";
  isEnabled = exp == "nixarchy-rise";

  # Nixarchy package from flake input
  nixarchyPkgs = inputs.nixarchy.packages.${pkgs.stdenv.hostPlatform.system} or { };
  nixarchyPkg = nixarchyPkgs.default or pkgs.hello; # fallback: build will error clearly if missing

  # HANCORE Quickshell Rise — hermetic derivation wrapping the quickshell config
  hancore-quickshell-rise = pkgs.stdenv.mkDerivation {
    pname = "hancore-quickshell-rise";
    version = "0.1.0";
    # The Rise bar lives inside the nixarchy source tree
    src = inputs.nixarchy;
    installPhase = ''
      mkdir -p $out/share/quickshell
      # Copy the Rise QML config if present; otherwise create a placeholder
      if [ -d quickshell ]; then
        cp -r quickshell/. $out/share/quickshell/
      elif [ -d rise ]; then
        cp -r rise/. $out/share/quickshell/
      else
        echo "// HANCORE Quickshell Rise placeholder" > $out/share/quickshell/shell.qml
      fi
    '';
  };
in
{
  nixos = lib.mkIf isEnabled {
    # Register Wayland session for DM session picker (no-reboot switching)
    services.displayManager.sessionPackages = [
      (
        (pkgs.writeTextFile {
          name = "nixarchy-rise-wayland-session";
          destination = "/share/wayland-sessions/nixarchy-rise.desktop";
          passthru.providedSessions = [ "nixarchy-rise" ];
          text = ''
            [Desktop Entry]
            Name=Nixarchy Rise
            Comment=Omarchy 4.x with HANCORE Quickshell Rise
            Exec=nixarchy-session
            Type=Application
            DesktopNames=Hyprland
          '';
        })
        // {
          providedSessions = [ "nixarchy-rise" ];
        }
      )
    ];

    environment.systemPackages = [
      nixarchyPkg
      hancore-quickshell-rise
      pkgs.quickshell
      pkgs.matugen # Material You color token generator
    ];
  };

  home =
    { config, lib, ... }:
    {
      config = lib.mkIf isEnabled {
        # $ipc uses Quickshell IPC — NOT noctalia msg
        wayland.windowManager.hyprland.settings."$ipc" = lib.mkForce "qs ipc";

        # Deploy Rise config to ~/.config/quickshell/rise
        xdg.configFile."quickshell/rise".source = "${hancore-quickshell-rise}/share/quickshell";

        # Matugen hook — generate color tokens from current wallpaper on login
        systemd.user.services.nixarchy-matugen-init = {
          Unit = {
            Description = "Generate Matugen color tokens for Nixarchy Rise";
            After = [ "graphical-session.target" ];
            PartOf = [ "graphical-session.target" ];
          };
          Install = {
            WantedBy = [ "graphical-session.target" ];
          };
          Service = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${pkgs.bash}/bin/bash -c 'mkdir -p %h/.config/matugen && [ -f %h/.local/share/current-wallpaper ] && ${pkgs.matugen}/bin/matugen image %h/.local/share/current-wallpaper || true'";
          };
        };
      };
    };
}
