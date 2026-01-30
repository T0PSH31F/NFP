{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
let
  cfg = config.desktop.caelestia;
in
{
  config = lib.mkIf (cfg.enable && (cfg.backend == "hyprland" || cfg.backend == "both")) {
    # Use with-cli package for full caelestia functionality (CLI commands)
    environment.systemPackages = [
      inputs.caelestia-shell.packages.${pkgs.system}.with-cli
    ];

    home-manager.users.t0psh31f = {
      imports = [
        inputs.caelestia-shell.homeManagerModules.default
      ];

      # Caelestia shell with CLI and custom wallpaper directory
      programs.caelestia = {
        enable = true;
        cli.enable = true;
        settings = {
          # Use our wallpaper directory instead of default ~/Pictures/Wallpapers
          paths.wallpaperDir = "~/.background/wallpaper";
        };
      };

      # Overrides for T0psh31f's preferences
      wayland.windowManager.hyprland = {
        enable = true; # REQUIRED: Enable home-manager to generate hyprland.conf

        settings = {
          # Custom keybinds
          bind = lib.mkAfter [
            "SUPER, Q, killactive," # Close/kill active window
            "SUPER, T, exec, ghostty" # Terminal
            "SUPER, Return, exec, ghostty" # Terminal (alternate)
            "SUPER SHIFT, T, exec, kitty" # Kitty terminal
            "SUPER SHIFT, Return, exec, warp-terminal" # Warp terminal
            "SUPER, E, exec, dolphin" # File Manager
            "SUPER, Y, exec, ghostty -e yazi" # TUI File Manager
            "SUPER, S, exec, spotify" # Music
            "SUPER, F, exec, firefox" # Browser (User requested)
            # Wallpaper
            "SUPER, W, exec, caelestia wallpaper set $(find ~/.background/wallpaper -type f \\( -iname '*.jpg' -o -iname '*.png' -o -iname '*.webp' \\) 2>/dev/null | shuf -n 1)" # Random wallpaper
            # Caelestia shell controls
            "Ctrl+Alt, Delete, global, caelestia:session" # Session menu
            "Ctrl+Super+Alt, R, exec, qs -c caelestia kill; caelestia shell -d" # Restart shell
            # Caelestia launcher via global shortcuts
            "Super, Super_L, global, caelestia:launcher"
          ];

          # Note: bindin with catchall removed - only valid in submaps

          # Wallpaper rotation handled by systemd timer using caelestia CLI
          # No need for swww-daemon here - Caelestia handles it
          exec-once = [
            # Run initial wallpaper set after login
            "sleep 5 && caelestia wallpaper set $(find ~/.background/wallpaper -type f \\( -iname '*.jpg' -o -iname '*.png' \\) 2>/dev/null | shuf -n 1) 2>/dev/null || true"
          ];

          # Ensure window borders and layout are standard (for visibility/control)
          general = {
            border_size = 2;
            "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
            "col.inactive_border" = "rgba(595959aa)";
            layout = "dwindle";
          };
        };
      };

      # Ensure XDG directories are set properly for "Open with..." menus
      xdg.enable = true;
    };
  };
}
