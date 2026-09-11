{
  config,
  lib,
  pkgs,
  inputs,
  osConfig ? config,
  ...
}:
let
  cfg = osConfig.layers.layer-40.desktop.noctalia;
in
{
  options.layers.layer-40.desktop.noctalia = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Noctalia Desktop Shell (v5)";
    };

    backend = lib.mkOption {
      type = lib.types.enum [
        "hyprland"
        "niri"
        "both"
      ];
      default = "hyprland";
      description = "Which compositor backend to use with Noctalia";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
      description = "The noctalia v5 package to use";
    };

    plugins = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "assistant-panel"
        "ip-monitor"
        "tailscale"
        "workspace-overview"
        "screen-toolkit"
        "todo"
        "model-usage"
      ];
      description = "List of Noctalia plugins to declaratively fetch and link into ~/.config/noctalia/plugins";
    };
  };

  home =
    { config, lib, ... }:
    let
      communityPluginsSrc =
        inputs.noctalia-community-plugins or (pkgs.fetchFromGitHub {
          owner = "noctalia-dev";
          repo = "community-plugins";
          rev = "caed21ab081948435cd770d2e954c99b8bbb72cf";
          hash = "sha256-3mFoSMTkfR2W7qVsV4MaM8s1pX5cjucu9UXLI88qv0s=";
        });
      officialPluginsSrc =
        inputs.noctalia-official-plugins or (pkgs.fetchFromGitHub {
          owner = "noctalia-dev";
          repo = "official-plugins";
          rev = "8cb833c3e2502f57e49d34fa64386b4d66794b77";
          hash = "sha256-gb4YgbRAismjl3Cur4ERFDfU2pR33ynRw0/CCAFw+Pw=";
        });

      patchPlugin =
        pluginName: rawSrc:
        pkgs.runCommand "noctalia-plugin-${builtins.replaceStrings [ "/" ] [ "-" ] pluginName}"
          {
            nativeBuildInputs = [ pkgs.jq ];
          }
          ''
            cp -r "${rawSrc}" $out
            chmod -R u+w $out
            if [ -f "$out/plugin.json" ]; then
              if ! jq -e 'has("min_noctalia")' "$out/plugin.json" >/dev/null 2>&1; then
                jq '. + {"min_noctalia": "5.0.0"}' "$out/plugin.json" > "$out/plugin.json.tmp"
                mv "$out/plugin.json.tmp" "$out/plugin.json"
              fi
            elif [ -f "$out/manifest.json" ]; then
              if ! jq -e 'has("min_noctalia")' "$out/manifest.json" >/dev/null 2>&1; then
                jq '. + {"min_noctalia": "5.0.0"}' "$out/manifest.json" > "$out/manifest.json.tmp"
                mv "$out/manifest.json.tmp" "$out/manifest.json"
              fi
            fi
          '';
    in
    {
      imports = [
        inputs.noctalia.homeModules.default
      ]
      ++ lib.optionals cfg.enable [
        ./ipc.nix
        ./mutable-includes.nix
        ./hypridle.nix
      ];

      config = lib.mkIf cfg.enable {
        home.file = lib.mkMerge (
          map (pluginName: {
            ".config/noctalia/plugins/${pluginName}".source =
              let
                raw =
                  if builtins.pathExists "${officialPluginsSrc}/${pluginName}" then
                    "${officialPluginsSrc}/${pluginName}"
                  else if builtins.pathExists "${communityPluginsSrc}/${pluginName}" then
                    "${communityPluginsSrc}/${pluginName}"
                  else
                    "${communityPluginsSrc}/${pluginName}";
              in
              patchPlugin pluginName raw;
          }) cfg.plugins
          ++ [
            {
              ".face".source = ../../../layers/00-cyberia/02-assets/user_profile/cloud.gif;
              ".face.icon".source = ../../../layers/00-cyberia/02-assets/user_profile/cloud.gif;
            }
          ]
        );
        home.packages = with pkgs; [
          gst_all_1.gst-plugins-base
          gst_all_1.gst-plugins-good

          # Color generation helper — extracts colors from noctalia theme JSON
          (pkgs.writeShellScriptBin "noctalia-regen-colors" ''
            set -euo pipefail
            WALLPAPER=$(noctalia msg wallpaper-get 2>/dev/null || echo "")
            [ -z "$WALLPAPER" ] || [ ! -f "$WALLPAPER" ] && exit 0
            # Get the active scheme source and name
            SCHEME_RAW=$(noctalia msg color-scheme-get 2>/dev/null || echo "")
            SCHEME_SOURCE=$(echo "$SCHEME_RAW" | awk '{print $1}')
            SCHEME_NAME=$(echo "$SCHEME_RAW" | awk '{print $2}')
            # noctalia theme CLI only supports Material You / custom scheme names,
            # not builtin themes (e.g. "Ayu"). Fall back to m3-content for builtin.
            if [ "$SCHEME_SOURCE" = "builtin" ] || [ -z "$SCHEME_NAME" ]; then
              SCHEME="m3-content"
            else
              SCHEME="$SCHEME_NAME"
            fi
            noctalia theme "$WALLPAPER" --scheme "$SCHEME" --dark 2>/dev/null | ${pkgs.python3}/bin/python3 -c '
            import json, sys
            d = json.load(sys.stdin)
            p = d["primary"].lstrip("#")
            s = d["surface"].lstrip("#")
            sc = d["secondary"].lstrip("#")
            t = d["tertiary"].lstrip("#")
            e = d["error"].lstrip("#")
            sl = d.get("surface_lowest", d.get("surface", "#000000")).lstrip("#")
            print(f"$primary = rgb({p})")
            print(f"$surface = rgb({s})")
            print(f"$secondary = rgb({sc})")
            print(f"$error = rgb({e})")
            print(f"$tertiary = rgb({t})")
            print(f"$surface_lowest = rgb({sl})")
            print()
            print("general {")
            print(f"    col.active_border = $primary")
            print(f"    col.inactive_border = $surface")
            print("}")
            print()
            print("group {")
            print(f"    col.border_active = $secondary")
            print(f"    col.border_inactive = $surface")
            print(f"    col.border_locked_active = $error")
            print(f"    col.border_locked_inactive = $surface")
            print()
            print("    groupbar {")
            print(f"        col.active = $secondary")
            print(f"        col.inactive = $surface")
            print(f"        col.locked_active = $error")
            print(f"        col.locked_inactive = $surface")
            print("    }")
            print("}")
            ' > ~/.config/hypr/noctalia/noctalia-colors.conf
          '')

          # Hook script — reloads compositor config when Noctalia changes wallpaper/colors
          (pkgs.writeShellScriptBin "noctalia-hypr-reload" ''
            set -euo pipefail

            # Regenerate noctalia-colors.conf from current wallpaper
            noctalia-regen-colors 2>/dev/null || true

            # Reload Hyprland config to pick up new colors from noctalia-colors.conf
            hyprctl reload 2>/dev/null || true

            # Force GPU shader recompile (toggle off then on)
            hyprctl keyword decoration:screen_shader "" 2>/dev/null || true
            sleep 0.3
            hyprctl keyword decoration:screen_shader "$HOME/.config/hypr/vibrancy.frag" 2>/dev/null || true

            # Sync Zellij colors
            zellij-colors-sync 2>/dev/null || true

            # Sync Rofi theme/colors
            pkill -USR2 rofi 2>/dev/null || true
          '')
        ];

        programs.noctalia = {
          enable = true;
          systemd.enable = true;
          inherit (cfg) package;
          validateConfig = true;

          settings = {
            # ── Shell ────────────────────────────────────────────────
            shell = {
              ui_scale = 1.1;
              corner_radius_scale = 1.0;
              font_family = "JetBrainsMono NF Medium";
              lang = "";
              time_format = "{:%H:%M:%S}";
              date_format = "";
              polkit_agent = true;
              password_style = "random";
              launch_apps_as_systemd_services = true;
              telemetry_enabled = true;
              screen_time_enabled = true;
              avatar_path = "/home/t0psh31f/Clan/NFP/layers/00-cyberia/02-assets/png-ico/Zoro.png";
              external_ip_enabled = true;
            };
            shell.animation = {
              speed = 0.75;
            };
            shell.greeter_sync = {
              auto_sync = true;
            };
            shell.launcher = {
              categories = true;
              show_icons = true;
              sort_by_usage = true;
              session_search = true;
              app_grid = true;
              compact = true;
            };
            shell.panel = {
              launcher_placement = "attached";
              open_near_click_clipboard = true;
              transparency_mode = "glass";
            };
            shell.screen_corners = {
              enabled = true;
            };
            shell.screenshot = {
              confirm_region = true;
            };

            # ── Theme ────────────────────────────────────────────────
            theme = {
              mode = "dark";
              source = "wallpaper";
              wallpaper_scheme = "m3-content";
              # community_palette removed — use wallpaper-based color generation
              # To restore a fixed palette, uncomment and set: community_palette = "Palette Name";
            };
            theme.templates = {
              builtin_ids = [
                "btop"
                "cava"
                "gtk3"
                "gtk4"
                "ghostty"
                "helix"
                "hyprland"
                "kcolorscheme"
                "kitty"
                "qt"
                "starship"
                "wezterm"
              ];
              community_ids = [
                "pi-agent"
                "spicetify"
                "pywalfox"
                "neovim"
                "obsidian"
                "vscode"
                "zed"
                "rofi"
                "vicinae"
                "discord"
                "papirus-icons"
                "telegram"
                "yazi"
                "zathura"
                "snappy-switcher"
                "hyprtoolkit"
                "opencode"
              ];
            };

            # ── Wallpaper ────────────────────────────────────────────
            wallpaper = {
              enabled = true;
              fill_mode = "crop";
              fill_color = "surface";
              directory = "$HOME/.background/4k Background";
              directory_dark = "$HOME/.background/4k Background";
              transition = [
                "random"
                "honeycomb"
              ];
              transition_duration = 17600;
              transition_on_startup = true;
            };
            wallpaper.automation = {
              enabled = true;
              interval_seconds = 900;
              order = "random";
            };
            wallpaper.default = {
              path = "/home/t0psh31f/.background/4k Background/blue-one-piece-zoro-4k-82429jb4apj2vznp.jpg";
            };
            wallpaper.last = {
              path = "/home/t0psh31f/.background/4k Background/blue-one-piece-zoro-4k-82429jb4apj2vznp.jpg";
            };
            wallpaper.monitor = {
              "eDP-1" = {
                directory = "$HOME/.background/4k Background";
              };
              "DP-1" = {
                directory = "$HOME/.background/4k Background";
              };
              "HDMI-A-1" = {
                directory = "$HOME/.background/4k Background";
              };
            };
            wallpaper.monitors = {
              "eDP-1" = {
                path = "/home/t0psh31f/.background/4k Background/blue-one-piece-zoro-4k-82429jb4apj2vznp.jpg";
              };
              "DP-2" = {
                path = "/home/t0psh31f/.background/4k Background/blue-one-piece-zoro-4k-82429jb4apj2vznp.jpg";
              };
            };

            # ── Backdrop ─────────────────────────────────────────────
            backdrop = {
              enabled = false; # Disabled: oversized blur regions behind notifications/dock/OSD
              blur_intensity = 0.4;
              tint_intensity = 0.6;
            };

            # ── Audio ────────────────────────────────────────────────
            audio = {
              enable_overdrive = true;
              enable_sounds = true;
              notification_sound = "/home/t0psh31f/Clan/NFP/layers/00-cyberia/02-assets/SFX/Navi(Extra)/446.wav";
              volume_change_sound = "/home/t0psh31f/Clan/NFP/layers/00-cyberia/02-assets/SFX/volume-feedback.wav";
            };

            # ── Bar ──────────────────────────────────────────────────
            bar = {
              position = "top";
              density = "comfortable";
              show_outline = true;
              show_capsule = true;
              background_opacity = 0.89;
              display_mode = "always_visible";
              frame_thickness = 7;
              frame_radius = 16;
              outer_corners = true;
              mouse_wheel_action = "workspace";
              right_click_action = "control_center";
            };
            bar.default = {
              background_opacity = 0.58;
              border = "primary";
              border_width = 2.0;
              capsule = true;
              capsule_border = "primary";
              capsule_opacity = 0.0;
              center = [
                "media"
                "cat"
              ];
              color = "primary";
              contact_shadow = true;
              end = [
                "tray"
                "notifications"
                "clipboard"
                "network"
                "bluetooth"
                "volume"
                "brightness"
                "battery"
                "clock"
                "session"
                "control-center"
              ];
              icon_color = "secondary";
              margin_edge = 0;
              margin_ends = 30;
              padding = 13;
              panel_overlap = 2;
              radius_bottom_left = 25;
              radius_bottom_right = 0;
              radius_top_left = 26;
              radius_top_right = 9;
              scale = 1.15;
              shadow = false;
              thickness = 44;
              widget_spacing = 3;
            };
            bar.left = [
              {
                id = "Launcher";
                icon = "rocket";
                enable_colorization = true;
                colorize_system_icon = "secondary";
                use_distro_logo = true;
              }
              {
                id = "SystemMonitor";
                compact_mode = false;
                show_cpu_usage = true;
                show_cpu_cores = true;
                show_cpu_freq = true;
                show_cpu_temp = true;
                show_memory_usage = true;
                show_memory_as_percent = true;
                show_disk_usage = true;
                show_disk_usage_as_percent = true;
                show_network_stats = true;
                show_swap_usage = true;
                use_monospace_font = true;
              }
              { id = "plugin:ip-monitor"; }
              { id = "plugin:tailscale"; }
            ];
            bar.center = [
              {
                id = "MediaMini";
                compact_mode = false;
                show_album_art = true;
                show_progress_ring = true;
                show_visualizer = true;
                visualizer_type = "wave";
                scrolling_mode = "always";
                hide_when_idle = true;
                hide_mode = "transparent";
              }
              { id = "plugin:workspace-overview"; }
            ];
            bar.right = [
              { id = "plugin:screen-toolkit"; }
              { id = "plugin:todo"; }
              { id = "plugin:model-usage"; }
              {
                id = "Battery";
                display_mode = "graphic";
                show_power_profiles = true;
                hide_if_idle = true;
                hide_if_not_detected = true;
              }
              {
                id = "Volume";
                display_mode = "onhover";
                middle_click_command = "pwvucontrol || pavucontrol";
              }
              {
                id = "Clock";
                format_horizontal = "HH:mm ddd, MMM dd";
                format_vertical = "HH mm - dd MM";
                tooltip_format = "HH:mm ddd, MMM dd";
              }
              {
                id = "ControlCenter";
                icon = "bomb";
                enable_colorization = true;
                colorize_system_icon = "secondary";
              }
            ];

            # ── Brightness ────────────────────────────────────────────
            brightness = {
              sync_all_monitors = true;
            };

            # ── Calendar ─────────────────────────────────────────────
            calendar = {
              enabled = true;
              refresh_minutes = 240;
            };
            calendar.account.personal_google = {
              color = "primary";
              name = "WE77";
              type = "google";
            };
            calendar.account.secondary_google = {
              color = "secondary";
              name = "LL";
              type = "google";
            };

            # ── Control Center ────────────────────────────────────────
            control_center = {
              sidebar = "full";
              sidebar_section = "full";
              width = 920;
            };
            control_center.shortcuts = [
              { type = "wifi"; }
              { type = "bluetooth"; }
              { type = "nightlight"; }
              { type = "keyboard_layout"; }
              { type = "wallpaper"; }
              { type = "power_profile"; }
            ];

            # ── Dock ─────────────────────────────────────────────────
            dock = {
              enabled = false;
              position = "bottom";
              auto_hide = false;
              active_monitor_only = false;
              show_running = true;
              magnification = true;
              magnification_scale = 1.35;
              background_opacity = 0.81;
              launcher_icon = "yin-yang-filled";
              launcher_position = "start";
              launcher_custom_image = "/home/t0psh31f/.icons/Anime/1P/one-piece-jolly-roger-icons-by-crountch/png/256x256/Zoro.png";
              margin_edge = 2;
              monitors = [
                "eDP-1"
                "DP-2"
              ];
              pinned = [ "Brave" ];
              radius = 23;
              reserve_space = false;
              show_dots = true;
            };

            # ── Hot Corners ──────────────────────────────────────────
            hot_corners = {
              enabled = true;
            };
            hot_corners.top_left = {
              action = "launcher";
            };
            hot_corners.top_right = {
              action = "control_center";
            };
            hot_corners.bottom_left = {
              action = "window_switcher";
            };

            # ── Idle ─────────────────────────────────────────────────
            # DISABLED: noctalia's native idle system causes Wayland
            # "Broken pipe" crashes on Intel Iris Xe when the display
            # wakes from DPMS screen-off. hypridle handles this instead.
            idle.behavior_order = [ ];
            idle.behavior.lock = {
              action = "lock";
              enabled = false;
              timeout = 600.0;
            };
            idle.behavior.screen-off = {
              action = "screen_off";
              enabled = false;
              timeout = 660.0;
            };
            idle.behavior.lock-and-suspend = {
              action = "lock_and_suspend";
              enabled = false;
              timeout = 900.0;
            };

            # ── Keybinds ─────────────────────────────────────────────
            keybinds = {
              cancel = [ "Escape" ];
              up = [
                "Up"
                "Alt+j"
              ];
              down = [
                "Down"
                "Alt+k"
              ];
              left = [
                "Left"
                "Alt+h"
              ];
              right = [
                "Right"
                "Alt+l"
              ];
            };

            # ── Location ──────────────────────────────────────────────
            location = {
              address = "Los Angeles, CA";
              auto_locate = true;
            };

            # ── Lockscreen Widgets ────────────────────────────────────
            lockscreen_widgets = {
              enabled = true;
              schema_version = 2;
              widget_order = [
                "lockscreen-login-box@DP-2"
                "lockscreen-login-box@eDP-1"
              ];
            };
            lockscreen_widgets.grid = {
              cell_size = 16;
              major_interval = 4;
              visible = true;
            };
            lockscreen_widgets.widget."lockscreen-login-box@eDP-1" = {
              box_height = 70.0;
              box_width = 400.0;
              cx = 800.0;
              cy = 881.0;
              output = "eDP-1";
              rotation = 0.0;
              type = "login_box";
            };
            lockscreen_widgets.widget."lockscreen-login-box@eDP-1".settings = {
              background_color = "surface_variant";
              background_opacity = 0.88;
              background_radius = 12.0;
              input_opacity = 1.0;
              input_radius = 6.0;
              show_caps_lock = true;
              show_keyboard_layout = true;
              show_login_button = true;
              show_password_hint = true;
            };
            lockscreen_widgets.widget."lockscreen-login-box@DP-2" = {
              box_height = 70.0;
              box_width = 400.0;
              cx = 960.0;
              cy = 961.0;
              output = "DP-2";
              rotation = 0.0;
              type = "login_box";
            };
            lockscreen_widgets.widget."lockscreen-login-box@DP-2".settings = {
              background_color = "surface_variant";
              background_opacity = 0.88;
              background_radius = 12.0;
              input_opacity = 1.0;
              input_radius = 6.0;
              show_caps_lock = true;
              show_keyboard_layout = true;
              show_login_button = true;
              show_password_hint = true;
            };

            # ── Night Light ──────────────────────────────────────────
            night_light = {
              enabled = true;
              auto_schedule = true;
              night_temp = "4000";
              day_temp = "6500";
              manual_sunrise = "06:30";
              manual_sunset = "18:30";
            };

            # ── Notifications ─────────────────────────────────────────
            notification = {
              enable_daemon = true;
              position = "top_right";
              layer = "overlay";
              background_opacity = 0.94;
            };

            # ── OSD ──────────────────────────────────────────────────
            osd = {
              position = "bottom_center";
              position_vertical = "center_right";
              orientation = "horizontal";
              scale = 1.0;
              background_opacity = 0.97;
            };

            # ── Plugins ──────────────────────────────────────────────
            plugins.enabled = [
              # Official plugins
              "noctalia/bongocat"
              "noctalia/screen_recorder"
              "noctalia/notes"
              "noctalia/wallhaven"
              # Community plugins
              "community/9router-control"
              "community/anilist"
              "community/audio-switcher"
              "community/bookmarks"
              "community/calculator"
              "community/claude-companion"
              "community/config-swap"
              "community/dns-switcher"
              "community/drive-health"
              "community/ds4-color"
              "community/eyecare"
              "community/file-search"
              "community/game-launcher"
              "community/gamer-mode"
              "community/gslapper"
              "community/hassio"
              "community/hypr-layout-switcher"
              "community/imagemagick-clock"
              "community/ip-monitor"
              "community/keybind-cheatsheet"
              "community/keymap"
              "community/llamanager"
              "community/lyrics"
              "community/mimir"
              "community/mini-docker"
              "community/niri-active-workspace"
              "community/niri-animations"
              "community/nix-monitor"
              "community/noctwhspr"
              "community/obsidian"
              "community/phone-connect"
              "community/portctl"
              "community/procmon"
              "community/screen-toolkit"
              "community/special-workspaces"
              "community/spotify-lyrics"
              "community/ssh-launcher"
              "community/tailscale"
              "community/todo"
              "community/topgrade-wrapper"
              "community/udiskie"
              "community/web-launcher"
              "community/w-engine"
            ];
            plugins.source = [
              {
                name = "official";
                kind = "git";
                location = "https://github.com/noctalia-dev/official-plugins";
                auto_update = false;
              }
              {
                name = "community";
                kind = "git";
                location = "https://github.com/noctalia-dev/community-plugins";
                auto_update = false;
              }
            ];

            # ── Session ──────────────────────────────────────────────
            session_menu = {
              enable_countdown = true;
              countdown_duration = 10000;
              position = "center";
              show_header = true;
              show_keybinds = true;
              large_buttons_style = true;
              large_buttons_layout = "single-row";
            };

            # ── System Monitor ───────────────────────────────────────
            system.monitor = {
              gpu_poll_seconds = 60;
            };

            # ── Weather ──────────────────────────────────────────────
            weather = {
              unit = "imperial";
            };

            # ── Battery Device ───────────────────────────────────────
            battery.device."/org/freedesktop/UPower/devices/mouse_dev_4E_B6_4B_9A_28_22" = {
              warning_threshold = 10;
            };

            # ── Widget Styling ───────────────────────────────────────
            widget.battery = {
              capsule = true;
              capsule_border = "primary";
              capsule_fill = "on_primary";
              capsule_foreground = "on_primary";
              capsule_opacity = 0.92;
              display_mode = "graphic";
              scale = 1.1;
            };
            widget.bluetooth = {
              enabled = false;
            };
            widget.brightness = {
              enabled = false;
              show_label = false;
            };
            widget.cat = {
              audio_spectrum = true;
              capsule = true;
              capsule_border = "primary";
              capsule_fill = "on_primary";
              capsule_foreground = "secondary";
              capsule_opacity = 0.92;
              color = "primary";
              icon_color = "on_primary";
              rave_mode = true;
              scale = 1.4;
              tappy_mode = true;
              type = "noctalia/bongocat:cat";
            };
            widget.clipboard = {
              capsule = true;
              capsule_border = "primary";
              capsule_fill = "on_primary";
              capsule_foreground = "on_primary";
              capsule_opacity = 0.91;
            };
            widget.clock = {
              capsule = true;
              capsule_border = "primary";
              capsule_fill = "on_primary";
              capsule_foreground = "on_primary";
              capsule_opacity = 0.90;
              format = "{:%H:%M:%S}";
              scale = 1.1;
            };
            widget.control-center = {
              capsule = true;
              capsule_border = "primary";
              capsule_fill = "on_primary";
              capsule_foreground = "secondary";
              capsule_opacity = 0.91;
              custom_image = "/home/t0psh31f/.icons/Anime/1P/one-piece-jolly-roger-icons-by-crountch/png/256x256/Luffys flag.png";
            };
            widget.launcher = {
              capsule = true;
              capsule_border = "primary";
              capsule_fill = "on_primary";
              capsule_foreground = "secondary";
              capsule_opacity = 0.89;
              custom_image = "/home/t0psh31f/Pictures/png_ico/logo.png";
              glyph = "brand-xbox";
              scale = 1.25;
            };
            widget.media = {
              capsule = true;
              capsule_border = "primary";
              capsule_fill = "on_primary";
              capsule_foreground = "secondary";
              capsule_opacity = 0.93;
              color = "primary";
              hide_when_no_media = true;
              icon_color = "primary";
              max_length = 235;
              min_length = 116;
              title_scroll = "always";
            };
            widget.network = {
              capsule = true;
              capsule_border = "primary";
              capsule_fill = "on_primary";
              capsule_foreground = "on_primary";
              capsule_opacity = 0.90;
              color = "primary";
              enabled = true;
              icon_color = "primary";
            };
            widget.notifications = {
              capsule = true;
              hide_when_no_unread = true;
            };
            widget.session = {
              enabled = false;
            };
            widget.tray = {
              capsule = true;
              capsule_border = "primary";
              capsule_fill = "on_primary";
              capsule_foreground = "secondary";
              capsule_opacity = 0.93;
              color = "secondary";
              drawer = true;
              icon_color = "secondary";
            };
            widget.volume = {
              capsule = true;
              capsule_border = "primary";
              capsule_fill = "on_primary";
              capsule_foreground = "tertiary";
              capsule_opacity = 0.86;
              capsule_padding = 11;
              scale = 1.1;
            };
            widget.wallpaper = {
              capsule = true;
              capsule_border = "primary";
              capsule_fill = "on_primary";
              capsule_foreground = "secondary";
              capsule_opacity = 0.88;
              color = "primary";
              icon_color = "primary";
            };
            widget.workspaces = {
              capsule = true;
              capsule_border = "primary";
              capsule_fill = "on_primary";
              capsule_foreground = "secondary";
              capsule_opacity = 0.90;
              color = "primary";
              display = "name";
              empty_color = "tertiary";
              icon_color = "primary";
              labels_only_when_occupied = true;
            };

            # ── Hooks ─────────────────────────────────────────────────
            # Auto-reload Hyprland (and the GPU shader) whenever Noctalia
            # changes the wallpaper or regenerates the color palette.
            # This keeps borders, active/inactive colors, and the vibrancy
            # shader in sync without requiring a compositor restart.
            # NOTE: hooks are not yet supported in v5.0.0 — using systemd
            # service + noctalia-hypr-reload script instead.
            # hooks = {
            #   enabled = true;
            #   wallpaperChange = "noctalia-hypr-reload";
            #   colorGeneration = "noctalia-hypr-reload && zellij-colors-sync";
            # };
          };
        };

        # Sync Noctalia colors → Hyprland borders + Zellij on login.
        # Runs noctalia-hypr-reload which regenerates noctalia-colors.conf
        # from the current wallpaper and reloads the compositor.
        systemd.user.services.noctalia-colors-sync = {
          Unit = {
            Description = "Sync Noctalia colors to Hyprland and Zellij";
            After = [
              "graphical-session.target"
              "noctalia.service"
            ];
            Requires = [ "noctalia.service" ];
          };
          Service = {
            Type = "oneshot";
            ExecStart = "${pkgs.bash}/bin/bash -c 'sleep 3 && noctalia-hypr-reload'";
          };
          Install = {
            WantedBy = [ "graphical-session.target" ];
          };
        };

        # Re-sync colors every 15 min (wallpaper auto-regenerates on this cycle)
        systemd.user.timers.noctalia-colors-sync = {
          Unit = {
            Description = "Periodic Noctalia color sync";
          };
          Timer = {
            OnBootSec = "30s";
            OnUnitActiveSec = "15min";
            Unit = "noctalia-colors-sync.service";
          };
          Install = {
            WantedBy = [ "timers.target" ];
          };
        };
      };
    };
}
