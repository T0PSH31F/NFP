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
      decoration = {
        rounding = 18;
        rounding_power = 2;
        active_opacity = 0.9;
        inactive_opacity = 0.8;
        fullscreen_opacity = 1.0;
        blur = {
          enabled = true;
          xray = true;
          special = false;
          ignore_opacity = true;
          new_optimizations = true;
          size = 8;
          passes = 3;
          brightness = 1;
          noise = 0.05;
          contrast = 0.89;
          vibrancy = 0.1696;
          vibrancy_darkness = 0.5;
          popups = false;
          popups_ignorealpha = 0.6;
          input_methods = true;
          input_methods_ignorealpha = 0.8;
        };

        # ── Window Shadow (Subtle Neutral Shadow by Default) ──
        shadow = {
          enabled = lib.mkDefault false;
          range = lib.mkDefault 20;
          offset = lib.mkDefault "0 2";
          render_power = lib.mkDefault 3;
          color = lib.mkDefault "rgba(00000044)";
          color_inactive = lib.mkDefault "0x00000000";
        };

      };

      animations = {
        enabled = true;
        bezier = [
          "liner, 1, 1, 1, 1"
          "wind, 0.05, 0.85, 0.03, 0.97"
          "winIn, 0.07, 0.88, 0.04, 0.99"
          "winOut, 0.20, -0.15, 0, 1"
          "md3_standard, 0.12, 0, 0, 1"
          "md3_decel, 0.05, 0.80, 0.10, 0.97"
          "md3_accel, 0.20, 0, 0.80, 0.08"
          "md2, 0.30, 0, 0.15, 1"
          "menu_decel, 0.05, 0.82, 0, 1"
          "menu_accel, 0.20, 0, 0.82, 0.10"
          "easeInOutCirc, 0.75, 0, 0.15, 1"
          "easeOutCirc, 0, 0.48, 0.38, 1"
          "easeInOutCircAlt, 0.78, 0, 0.15, 1"
          "easeOutExpo, 0.10, 0.94, 0.23, 0.98"
          "softAcDecel, 0.20, 0.20, 0.15, 1"
          "OutBack, 0.28, 1.40, 0.58, 1"
          "overshot, 0.05, 0.85, 0.07, 1.04"
          "crazyshot, 0.1, 1.22, 0.68, 0.98"
          "hyprnostretch, 0.05, 0.82, 0.03, 0.94"
          "myBezier, 0.05, 0.9, 0.1, 1.05"
          # Persona / SekaiPop / Liquify kinetic spring curves
          "popBouncy, 0.175, 0.885, 0.32, 1.275"
          "elasticOut, 0.34, 1.56, 0.64, 1"
          "fluidDecel, 0.05, 0.90, 0.10, 1.05"
        ];
        animation = [
          "border, 1, 8, liner"
          "borderangle, 1, 82, liner, loop"
          "windows, 1, 4.5, popBouncy"
          "windowsIn, 1, 3.6, popBouncy, popin 75%"
          "windowsOut, 1, 3.0, winOut, popin 80%"
          "windowsMove, 1, 3.4, fluidDecel, slide"
          "fade, 1, 4.0, md3_decel"
          "layersIn, 1, 2.5, popBouncy, slide"
          "layersOut, 1, 1.8, menu_accel"
          "fadeLayersIn, 1, 2.0, menu_decel"
          "fadeLayersOut, 1, 1.8, menu_accel"
          "workspaces, 1, 5.0, popBouncy, slide"
          "specialWorkspace, 1, 3.0, elasticOut, slidefadevert 20%"
        ];
      };

      input = {
        numlock_by_default = true;
        repeat_delay = 250;
        repeat_rate = 35;

        follow_mouse = 1;
        off_window_axis_events = 2;

        touchpad = lib.mkIf cfg.isLaptop {
          natural_scroll = true;
          disable_while_typing = true;
          clickfinger_behavior = true;
          scroll_factor = 0.7;
        };
      };

      misc = {
        enable_swallow = true;
        swallow_regex = "^(mpv|foot|kitty|wezterm|alacritty|Alacritty|ghostty|warp-terminal)$";
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        vrr = if cfg.isNvidia then 0 else 1; # NVIDIA legacy drivers lack adaptive sync
        focus_on_activate = true;
        mouse_move_enables_dpms = true;
        key_press_enables_dpms = true;
        animate_manual_resizes = true;
        animate_mouse_windowdragging = true;
        allow_session_lock_restore = true;
        session_lock_xray = true;
        initial_workspace_tracking = false;
      };
    };
  };
}
