{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Wallpaper rotation script and timer
  # Rotates wallpapers from ~/.background/wallpaper/ every 15 minutes
  # Uses Caelestia CLI for integrated theme generation (Option A)

  home.packages = with pkgs; [
    matugen # Dynamic Material Design theme generator (backup)
  ];

  # Enable Home Manager to start/stop user services
  systemd.user.startServices = "sd-switch";

  # Wallpaper manager script
  home.file.".local/bin/wallpaper-manager" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Generic Wallpaper Manager
      # Usage: wallpaper-manager [random|select|set <path>]

      WALLPAPER_DIR="$HOME/.background/wallpaper"
      MATUGEN_TEMPLATE="${config.home.homeDirectory}/Clan/Grandlix-Gang/modules/Home-Manager/matugen-templates/hyprland-colors.conf"
      tmux_template="${config.home.homeDirectory}/Clan/Grandlix-Gang/modules/Home-Manager/matugen-templates/tmux-colors.conf"
      HYPR_COLORS="${config.home.homeDirectory}/.config/hypr/colors.conf"
      tmux_colors="${config.home.homeDirectory}/.config/tmux/colors.conf"

      # Ensure directories exist
      mkdir -p "$(dirname "$HYPR_COLORS")"
      mkdir -p "$(dirname "$tmux_colors")"

      function set_wallpaper() {
        local img="$1"
        echo "Setting wallpaper: $img"

        # 1. Set wallpaper with swww
        if ! pgrep -x swww-daemon > /dev/null; then
          swww-daemon &
          sleep 1
        fi
        swww img "$img" \
          --transition-type random \
          --transition-duration 2 \
          --transition-fps 60

        # 2. Generate colors with Matugen
        if command -v matugen &> /dev/null; then
          echo "Generating colors..."
          matugen image "$img" -t "$MATUGEN_TEMPLATE" -o "$HYPR_COLORS"
          matugen image "$img" -t "$tmux_template" -o "$tmux_colors"

          # Reload Hyprland to apply new colors
          hyprctl reload
          # Reload tmux if running
          tmux source-file ~/.config/tmux/tmux.conf 2>/dev/null || true
        else
          echo "Matugen not found, skipping color generation."
        fi
      }

      case "$1" in
        random)
          if [[ ! -d "$WALLPAPER_DIR" ]]; then
            echo "Wallpaper directory not found: $WALLPAPER_DIR"
            exit 1
          fi
          IMG=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.webp" \) 2>/dev/null | shuf -n 1)
          if [[ -n "$IMG" ]]; then
            set_wallpaper "$IMG"
          else
            echo "No wallpapers found."
          fi
          ;;
        select)
          if [[ ! -d "$WALLPAPER_DIR" ]]; then
            echo "Wallpaper directory not found."
            exit 1
          fi
          # Use Rofi to select wallpaper
          IMG=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.webp" \) | \
            sed "s|$WALLPAPER_DIR/||" | \
            rofi -dmenu -i -p "Select Wallpaper" -theme-str 'window {width: 50%;}')

          if [[ -n "$IMG" ]]; then
            set_wallpaper "$WALLPAPER_DIR/$IMG"
          fi
          ;;
        set)
          if [[ -f "$2" ]]; then
            set_wallpaper "$2"
          else
            echo "File not found: $2"
            exit 1
          fi
          ;;
        *)
          echo "Usage: $0 [random|select|set <path>]"
          exit 1
          ;;
      esac
    '';
  };

  # Systemd user service for wallpaper rotation
  systemd.user.services.rotate-wallpaper = {
    Unit = {
      Description = "Rotate wallpaper from ~/.background/wallpaper";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${config.home.homeDirectory}/.local/bin/wallpaper-manager random";
      Environment = [
        "DISPLAY=:0"
        "WAYLAND_DISPLAY=wayland-1"
        "PATH=/run/current-system/sw/bin:${config.home.homeDirectory}/.nix-profile/bin"
      ];
    };
  };

  # Systemd user timer - runs every 15 minutes and on startup
  systemd.user.timers.rotate-wallpaper = {
    Unit = {
      Description = "Rotate wallpaper every 15 minutes";
    };
    Timer = {
      OnCalendar = "*:0/15"; # Every 15 minutes
      OnStartupSec = "1min"; # Also run 1 minute after login
      Persistent = true;
      Unit = "rotate-wallpaper.service";
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };
}
