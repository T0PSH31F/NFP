{ config, lib, pkgs, inputs, ... }:
with lib;
let
  cfg = config.desktop.noctalia;
in
{
  config = mkIf (cfg.enable && cfg.backend == "niri") {
    programs.niri = {
      enable = true;
      package = inputs.niri.packages.${pkgs.system}.niri-stable or pkgs.niri;
    };

    # Better NixOS-level deps for Niri + Noctalia
    environment.systemPackages = with pkgs; [
      awww
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
      fuzzel  # Menu/launcher
      mako    # Notifications
      swayimg
      swaynotificationcenter
      swaybg  # Wallpaper (Niri native)
      waybar  # Bar (if needed)
      grim    # Screenshots
      slurp   # Screenshot selector
      wl-clipboard
      wl-clipboard-history  # cliphist equiv
    ];

    xdg.portal = {
      enable = true;
      xdgPkgs = [ pkgs.xdg-desktop-portal-gtk ];
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };

    home-manager.users.t0psh31f = {
      imports = [ inputs.niri.homeModules.niri ];

      programs.niri = {
        enable = true;
        settings = {
          # Modern Niri layout (scrolling workspaces, gaps)
          layout = {
            gaps = 12;
            center-focused-column = "never";
          };

          # Input: Keyboard + touchpad
          input = {
            keyboard = {
              xkb = {
                layout = "us";
                options = [ "caps:escape" "ctrl:menu" ];
              };
            };
            touchpad = {
              tap = "enabled";
              natural-scroll = true;
              drag = "two_finger";
            };
          };

          # Screenshot path
          screenshot-path = "~/Pictures/screenshots/%Y-%m-%d_%H-%M-%S.png";

          # Full keybinds matching your Hyprland (SUPER mod)
          binds = mkMerge [
            # Core window management
            {
              "Mod+Return" = [{ action = "spawn"; command = [ "ghostty" ]; }];
              "Mod+Q" = [{ action = "close-window"; }];
              "Mod+F" = [{ action = "toggle-fullscreen"; }];
              "Mod+J" = [{ action = "focus-next"; }];
              "Mod+K" = [{ action = "focus-prev"; }];
              "Mod+H" = [{ action = "focus-left"; }];
              "Mod+L" = [{ action = "focus-right"; }];
              "Mod+Shift+H" = [{ action = "swap-left"; }];
              "Mod+Shift+L" = [{ action = "swap-right"; }];
            }

            # Workspaces (Niri's infinite scrolling workspaces)
            {
              "Mod+1" = [{ action = "go-to-workspace"; workspace = 1; }];
              "Mod+2" = [{ action = "go-to-workspace"; workspace = 2; }];
              # ... up to 10
              "Mod+Shift+1" = [{ action = "move-to-workspace"; workspace = 1; }];
              "Mod+Ctrl+Right" = [{ action = "go-to-workspace"; direction = "next"; }];
              "Mod+Ctrl+Left" = [{ action = "go-to-workspace"; direction = "prev"; }];
            }

            # Noctalia IPC binds (matching Hyprland)
            {
              "Mod+D" = [{ action = "spawn"; command = [ "noctalia-shell" "ipc" "overview" ]; }];
              "Mod+X" = [{ action = "spawn"; command = [ "noctalia-shell" "ipc" "control-center" ]; }];
              "Mod+L" = [{ action = "spawn"; command = [ "noctalia-shell" "ipc" "lock" ]; }];
              "Mod+Shift+E" = [{ action = "spawn"; command = [ "noctalia-shell" "ipc" "session-menu" ]; }];
              "Print" = [{ action = "screenshot"; }];
              "Shift+Print" = [{ action = "screenshot-ui"; }];
            }

            # Media/Brightness (pipe to Noctalia or dbus)
            {
              "XF86AudioRaiseVolume" = [{ action = "spawn"; command = [ "noctalia-shell" "ipc" "volume" "+5" ]; }];
              "XF86AudioLowerVolume" = [{ action = "spawn"; command = [ "noctalia-shell" "ipc" "volume" "-5" ]; }];
              "XF86MonBrightnessUp" = [{ action = "spawn"; command = [ "noctalia-shell" "ipc" "brightness" "+5" ]; }];
            }

            # App launches (uwsm-style)
            {
              "Mod+T" = [{ action = "spawn"; command = [ "uwsm" "app" "--" "ghostty" ]; }];
              "Mod+E" = [{ action = "spawn"; command = [ "uwsm" "app" "--" "nemo-with-extensions" ]; }];
              "Mod+W" = [{ action = "spawn"; command = [ "uwsm" "app" "--" "brave" ]; }];
            }
          ];

          # Startup
          "exec-once" = [
            "systemctl --user start noctalia-shell.service"
            "swaybg -i ~/Pictures/wallpapers/default.jpg --mode fill"
            "mako"  # Notifications
          ];
        };
      };
    };
  };
}
