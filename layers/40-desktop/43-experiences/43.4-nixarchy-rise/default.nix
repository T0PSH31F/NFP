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

  # Nixarchy package from flake input (omarchy 4.5.x)
  nixarchyPkgs = inputs.nixarchy.packages.${pkgs.stdenv.hostPlatform.system} or { };
  nixarchyPkg = nixarchyPkgs.default or pkgs.hello; # fallback: build will error clearly if missing

  # Launcher for the Nixarchy Rise Hyprland session
  nixarchy-session = pkgs.writeShellScriptBin "nixarchy-session" ''
    export OMARCHY_PATH="${nixarchyPkg}/share/omarchy"
    export LUA_PATH="${nixarchyPkg}/share/omarchy/config/?.lua;${nixarchyPkg}/share/omarchy/?.lua;;$LUA_PATH"
    exec ${pkgs.uwsm}/bin/uwsm start -N "Nixarchy Rise" -D Hyprland -- \
      ${pkgs.hyprland}/bin/start-hyprland
  '';

  nixarchy-rise-wayland-session =
    (pkgs.writeTextFile {
      name = "nixarchy-rise-wayland-session";
      destination = "/share/wayland-sessions/nixarchy-rise.desktop";
      passthru.providedSessions = [ "nixarchy-rise" ];
      text = ''
        [Desktop Entry]
        Name=Nixarchy Rise
        Comment=Omarchy 4.x with HANCORE Quickshell Rise
        Exec=${nixarchy-session}/bin/nixarchy-session
        Type=Application
        DesktopNames=Hyprland
      '';
    })
    // {
      providedSessions = [ "nixarchy-rise" ];
    };
in
{
  nixos = lib.mkIf isEnabled {
    # Register Wayland session for DM session picker (no-reboot switching)
    services.displayManager.sessionPackages = [ nixarchy-rise-wayland-session ];

    environment.systemPackages = [
      nixarchyPkg
      nixarchy-session
      nixarchy-rise-wayland-session
      pkgs.quickshell
      pkgs.inotify-tools
      pkgs.qt6.qtimageformats
      pkgs.xdg-terminal-exec
      pkgs.matugen # Material You color token generator
    ];

    environment.sessionVariables = {
      OMARCHY_PATH = "${nixarchyPkg}/share/omarchy";
    };
  };

  home =
    { config, lib, ... }:
    {
      config = lib.mkIf isEnabled {
        # $ipc uses Quickshell IPC — NOT noctalia msg
        wayland.windowManager.hyprland.settings."$ipc" = lib.mkForce "qs ipc";

        # Deploy Rise shell config to ~/.config/quickshell/rise
        xdg.configFile."quickshell/rise".source = "${nixarchyPkg}/share/omarchy/shell";

        # Ensure Ghostty is the default terminal for xdg-terminal-exec
        xdg.configFile."xdg-terminals.list".text = "ghostty.desktop\ncom.mitchellh.ghostty.desktop\n";

        # Active experience configuration for standard Hyprland sessions
        xdg.configFile."hypr/experiences/nixarchy-rise.conf".text = ''
          # Nixarchy Rise Hyprland Experience Configuration
          $ipc = qs ipc

          # Environment variables for Omarchy runtime
          env = OMARCHY_PATH,${nixarchyPkg}/share/omarchy
          env = LUA_PATH,${nixarchyPkg}/share/omarchy/config/?.lua;${nixarchyPkg}/share/omarchy/?.lua;;

          # Theme color definitions for Hyprland borders and lightsaber aura
          $primary = rgb(89b4fa)
          $surface = rgb(1e1e2e)
          $secondary = rgb(b4befe)
          $surfaceContainer = rgb(313244)
          $error = rgb(f38ba8)
          $tertiary = rgb(f5c2e7)
          $surface_lowest = rgb(11111b)

          general {
            col.active_border = $primary
            col.inactive_border = $surface
          }

          # Quickshell Rise layer rules
          layerrule = blur 1, match:namespace ^omarchy-(bar|menu|notifications|dock|osd)$
          layerrule = no_anim 1, match:namespace ^omarchy-(bar|menu|notifications|dock|osd)$

          # Omarchy shortcuts & bindings
          bind = $mod, SPACE, exec, omarchy-menu toggle
          bind = $mod, A, exec, omarchy-menu toggle apps
          bind = $mod, comma, exec, omarchy-menu toggle setup

          # Autostart Quickshell Rise bar
          exec-once = OMARCHY_PATH=${nixarchyPkg}/share/omarchy quickshell -p ~/.config/quickshell/rise
        '';

        xdg.configFile."hypr/experiences/active-experience.conf".text = ''
          source = ${config.home.homeDirectory}/.config/hypr/experiences/nixarchy-rise.conf
        '';

        # Link Omarchy Hyprland Lua configs so both standalone and standard Hyprland sessions work
        xdg.configFile."hypr/monitors.lua".source =
          lib.mkDefault "${nixarchyPkg}/share/omarchy/config/hypr/monitors.lua";
        xdg.configFile."hypr/input.lua".source =
          lib.mkDefault "${nixarchyPkg}/share/omarchy/config/hypr/input.lua";
        xdg.configFile."hypr/bindings.lua".source =
          lib.mkDefault "${nixarchyPkg}/share/omarchy/config/hypr/bindings.lua";
        xdg.configFile."hypr/looknfeel.lua".source =
          lib.mkDefault "${nixarchyPkg}/share/omarchy/config/hypr/looknfeel.lua";
        xdg.configFile."hypr/autostart.lua".source =
          lib.mkDefault "${nixarchyPkg}/share/omarchy/config/hypr/autostart.lua";

        # Ensure default Omarchy theme and background state exist on login
        systemd.user.services.nixarchy-state-init = {
          Unit = {
            Description = "Initialize default theme and wallpaper state for Nixarchy Rise";
            After = [ "graphical-session-pre.target" ];
            PartOf = [ "graphical-session.target" ];
          };
          Install = {
            WantedBy = [ "graphical-session.target" ];
          };
          Service = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${pkgs.bash}/bin/bash -c 'mkdir -p %h/.local/state/omarchy/current && if [ ! -e %h/.local/state/omarchy/current/theme ]; then ln -sfn ${nixarchyPkg}/share/omarchy/themes/catppuccin %h/.local/state/omarchy/current/theme && ln -sfn ${nixarchyPkg}/share/omarchy/themes/catppuccin/backgrounds/2-waves.webp %h/.local/state/omarchy/current/background && echo Catppuccin > %h/.local/state/omarchy/current/theme.name && echo 1 > %h/.local/state/omarchy/current/theme.generation; fi'";
          };
        };

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
