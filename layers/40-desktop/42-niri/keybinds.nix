{
  osConfig ? config,
  config,
  lib,
  ...
}:
let
  cfg = osConfig.layers.layer-40.desktop.noctalia;
in
{
  config = lib.mkIf (cfg.enable && (cfg.backend == "niri" || cfg.backend == "both")) {
    programs.niri.settings.binds = with config.lib.niri.actions; {
      "Mod+T" = {
        action = spawn "uwsm" "app" "--" "ghostty";
      };
      "Mod+SHIFT+Return" = {
        action = spawn "uwsm" "app" "--" "warp-terminal";
      };
      "Mod+D" = {
        action = spawn "noctalia" "msg" "panel-toggle" "launcher";
      };
      "Mod+A" = {
        action = spawn "noctalia" "msg" "panel-toggle" "launcher";
      };
      "Mod+E" = {
        action = spawn "uwsm" "app" "--" "nemo";
      };
      "Mod+Y" = {
        action = spawn "uwsm" "app" "--" "ghostty" "-e" "yazi";
      };
      "Mod+B" = {
        action = spawn "uwsm" "app" "--" "brave";
      };
      "Mod+W" = {
        action = spawn "uwsm" "app" "--" "librewolf";
      };
      "Mod+M" = {
        action = spawn "uwsm" "app" "--" "spotify";
      };
      "Mod+SHIFT+Y" = {
        action =
          spawn "ghostty" "-e" "nu" "/home/t0psh31f/.config/yazelix/nushell/scripts/core/start_yazelix.nu"
            "launch";
      };
      "Mod+SHIFT+P" = {
        action = spawn "theme-switch" "--pick";
      };
      "Mod+Q" = {
        action = close-window;
      };
      "Mod+F" = {
        action = maximize-column;
      };
      "Mod+Alt+F" = {
        action = maximize-column;
      };
      "Mod+Shift+F" = {
        action = fullscreen-window;
      };
      "Mod+C" = {
        action = center-column;
      };
      "Mod+Equal" = {
        action = set-column-width "+10%";
      };
      "Mod+Minus" = {
        action = set-column-width "-10%";
      };
      "Mod+Shift+R" = {
        action = switch-preset-column-width;
      };

      # Navigation
      "Mod+H" = {
        action = focus-column-left;
      };
      "Mod+L" = {
        action = focus-column-right;
      };
      "Mod+J" = {
        action = focus-window-down;
      };
      "Mod+K" = {
        action = focus-window-up;
      };
      "Mod+Left" = {
        action = focus-column-left;
      };
      "Mod+Right" = {
        action = focus-column-right;
      };
      "Mod+Down" = {
        action = focus-window-down;
      };
      "Mod+Up" = {
        action = focus-window-up;
      };

      # Swapping/Moving
      "Mod+Shift+H" = {
        action = move-column-left;
      };
      "Mod+Shift+L" = {
        action = move-column-right;
      };
      "Mod+Ctrl+H" = {
        action = move-column-left;
      };
      "Mod+Ctrl+L" = {
        action = move-column-right;
      };
      "Mod+Shift+K" = {
        action = move-window-up;
      };
      "Mod+Shift+J" = {
        action = move-window-down;
      };

      # Workspaces
      "Mod+1" = {
        action = focus-workspace 1;
      };
      "Mod+2" = {
        action = focus-workspace 2;
      };
      "Mod+3" = {
        action = focus-workspace 3;
      };
      "Mod+4" = {
        action = focus-workspace 4;
      };
      "Mod+5" = {
        action = focus-workspace 5;
      };
      "Mod+6" = {
        action = focus-workspace 6;
      };
      "Mod+7" = {
        action = focus-workspace 7;
      };
      "Mod+8" = {
        action = focus-workspace 8;
      };
      "Mod+9" = {
        action = focus-workspace 9;
      };

      "Mod+Shift+1" = {
        action.move-column-to-workspace = 1;
      };
      "Mod+Shift+2" = {
        action.move-column-to-workspace = 2;
      };
      "Mod+Shift+3" = {
        action.move-column-to-workspace = 3;
      };
      "Mod+Shift+4" = {
        action.move-column-to-workspace = 4;
      };
      "Mod+Shift+5" = {
        action.move-column-to-workspace = 5;
      };

      # Noctalia IPC
      "Mod+X" = {
        action = spawn "noctalia" "msg" "panel-toggle" "control-center";
      };
      "Mod+Shift+E" = {
        action = spawn "noctalia" "msg" "panel-toggle" "session";
      };
      "Mod+O" = {
        action = spawn "noctalia" "msg" "window-switcher";
      };
      "Mod+Space" = {
        action = spawn "vicinae" "toggle";
      };
      "Mod+Slash" = {
        action = spawn "cheatsheet";
      };
      "Mod+Return" = {
        action = spawn "wlr-which-key";
      };
      "Mod+Shift+T" = {
        action = spawn "kitty";
      };
      "Mod+Shift+A" = {
        action = spawn "wlr-which-key" "agents";
      };

      # Monitor Movement (Parity with Hyprland binds)
      "Mod+Alt+H" = {
        action = move-column-to-monitor "HDMI-A-1";
      };
      "Mod+Alt+J" = {
        action = move-column-to-monitor "eDP-1";
      };
      "Mod+Alt+K" = {
        action = move-column-to-monitor "eDP-1";
      };
      "Mod+Alt+L" = {
        action = move-column-to-monitor "DP-2";
      };
      "Mod+Ctrl+Shift+Left" = {
        action = move-column-to-monitor-left;
      };
      "Mod+Ctrl+Shift+Right" = {
        action = move-column-to-monitor-right;
      };

      # Screenshots
      "Print" = {
        action = spawn "uwsm" "app" "--" "sh" "-c" "grim -g \"$(slurp)\" - | swappy -f -";
      };
      "Shift+Print" = {
        action = spawn "uwsm" "app" "--" "sh" "-c" "grim - | swappy -f -";
      };
      "XF86AudioEject" = {
        action = spawn "uwsm" "app" "--" "sh" "-c" "grim -g \"$(slurp)\" - | swappy -f -";
      };
      "Shift+XF86AudioEject" = {
        action = spawn "uwsm" "app" "--" "sh" "-c" "grim - | swappy -f -";
      };
      "Ctrl+Shift+S" = {
        action = spawn "uwsm" "app" "--" "sh" "-c" "grim -g \"$(slurp)\" - | swappy -f -";
      };

      # Media
      "XF86AudioRaiseVolume" = {
        action = spawn "noctalia" "msg" "volume-up";
      };
      "XF86AudioLowerVolume" = {
        action = spawn "noctalia" "msg" "volume-down";
      };
      "XF86MonBrightnessUp" = {
        action = spawn "noctalia" "msg" "brightness-up";
      };
      "XF86MonBrightnessDown" = {
        action = spawn "noctalia" "msg" "brightness-down";
      };

      # Media Keys (Non-repeating fallback)
      "XF86AudioPlay" = {
        action = spawn "noctalia" "msg" "media" "toggle";
      };
      "XF86AudioNext" = {
        action = spawn "noctalia" "msg" "media" "next";
      };
      "XF86AudioPrev" = {
        action = spawn "noctalia" "msg" "media" "previous";
      };
      "Alt+4" = {
        action = spawn "noctalia" "msg" "media" "previous";
      };
      "Alt+5" = {
        action = spawn "noctalia" "msg" "media" "toggle";
      };
      "Alt+6" = {
        action = spawn "noctalia" "msg" "media" "next";
      };
    };
  };
}
