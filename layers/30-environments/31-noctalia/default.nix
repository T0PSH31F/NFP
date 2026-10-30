{
  config,
  lib,
  pkgs,
  inputs,
  osConfig ? config,
  ...
}:
let
  inherit ((import ../../80-lib/81-helpers/mkDendriticModule.nix { inherit lib; })) mkDendriticModule;
  cfg = osConfig.layers.layer-40.desktop.noctalia;
in
{
  imports = [
    (mkDendriticModule "noctalia-hyprland" ./hyprland.nix)
    (mkDendriticModule "noctalia-niri" ./niri.nix)
    (mkDendriticModule "noctalia-umbriel" ./umbriel.nix)
  ];

  options.layers.layer-40.desktop.noctalia = {
    enable = lib.mkEnableOption "Noctalia Desktop Shell (v5)";

    backend = lib.mkOption {
      type = lib.types.enum [
        "hyprland"
        "niri"
        "both"
        "all"
      ];
      default = "all";
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
        "ip-monitor"
        "tailscale"
        "tailnet"
        "screen-toolkit"
        "todo"
        "agentik"
        "ai-usagebar"
        "mini-docker"
        "omniroute-quota"
        "9router-control"
        "phone-connect"
        "thunderbird-companion"
        "w-engine"
        "wallhaven"
        "bongocat"
        "notes"
        "umbriel-companion"
      ];
      description = "List of Noctalia plugins to declaratively fetch and link into ~/.config/noctalia/plugins";
    };

    idle = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable hypridle management for Hyprland session";
      };

      dpmsTimeout = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = 600;
        description = "Seconds of inactivity before turning off display via DPMS. Set null to disable.";
      };

      lockTimeout = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = 660;
        description = "Seconds of inactivity before locking session. Set null to disable.";
      };

      dpmsIgnoreAc = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "If true, do not shut off display via DPMS when connected to AC power";
      };

      lockIgnoreAc = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "If true, do not lock session when connected to AC power";
      };
    };
  };

  home =
    { lib, ... }:
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

      noctaliaPluginDoctor = pkgs.writeShellScriptBin "noctalia-plugin-doctor" ''
        set -euo pipefail
        PLUGINS_DIR="$HOME/.config/noctalia/plugins"

        echo "=========================================================================="
        echo " 🩺 NOCTALIA PLUGIN DOCTOR — COMPATIBILITY AUDIT"
        echo "=========================================================================="
        echo "Pinned Shell: ${cfg.package.name or "noctalia"}"
        echo "Expected Manifest Protocol: plugin_api (Supported Range: 3 .. 32)"
        echo "Configured Official Plugins Rev: ${inputs.noctalia-official-plugins.rev or "flake.lock"}"
        echo "Configured Community Plugins Rev: ${inputs.noctalia-community-plugins.rev or "flake.lock"}"
        echo "UI Plugins Directory: $PLUGINS_DIR"
        echo "--------------------------------------------------------------------------"

        if [ ! -d "$PLUGINS_DIR" ]; then
          echo "No plugins directory found at $PLUGINS_DIR."
          exit 0
        fi

        TOTAL=0
        PASSED=0
        FAILED=0

        for pdir in "$PLUGINS_DIR"/*; do
          [ -d "$pdir" ] || continue
          TOTAL=$((TOTAL + 1))
          pname=$(basename "$pdir")

          manifest="$pdir/plugin.toml"
          if [ ! -f "$manifest" ]; then
            echo "❌ [$pname]: MISSING plugin.toml manifest"
            FAILED=$((FAILED + 1))
            continue
          fi

          if grep -q "min_noctalia" "$manifest"; then
            echo "❌ [$pname]: DEPRECATED LEGACY PROTOCOL ('min_noctalia' key instead of 'plugin_api')"
            FAILED=$((FAILED + 1))
            continue
          fi

          api_val=$(grep -E "^plugin_api[[:space:]]*=" "$manifest" | awk -F '=' '{print $2}' | tr -d ' "')
          if [ -z "$api_val" ]; then
            echo "❌ [$pname]: MISSING MANDATORY KEY 'plugin_api'"
            FAILED=$((FAILED + 1))
            continue
          fi

          if ! [[ "$api_val" =~ ^[0-9]+$ ]]; then
            echo "❌ [$pname]: MALFORMED 'plugin_api' value ($api_val)"
            FAILED=$((FAILED + 1))
            continue
          fi

          if [ "$api_val" -lt 3 ] || [ "$api_val" -gt 32 ]; then
            echo "❌ [$pname]: INCOMPATIBLE plugin_api=$api_val (supported range: 3..32)"
            FAILED=$((FAILED + 1))
            continue
          fi

          echo "✅ [$pname]: COMPATIBLE (plugin_api=$api_val)"
          PASSED=$((PASSED + 1))
        done

        echo "--------------------------------------------------------------------------"
        echo "Results: $PASSED / $TOTAL plugins compatible."
        if [ "$FAILED" -gt 0 ]; then
          echo ""
          echo "⚠️ DETECTED $FAILED INCOMPATIBLE PLUGINS IN $PLUGINS_DIR"
          echo ""
          echo "Safe Cache Cleanup Procedure:"
          echo "  1. Backup existing plugins:"
          echo "     cp -r ~/.config/noctalia/plugins ~/.config/noctalia/plugins.bak-\$(date +%Y%m%d%H%M%S)"
          echo "  2. Remove stale unmanaged downloaded community plugins (preserving Nix symlinks):"
          echo "     find ~/.config/noctalia/plugins/ -mindepth 1 -maxdepth 1 ! -type l -exec rm -rf {} +"
          echo "  3. Restart Noctalia desktop session:"
          echo "     systemctl --user restart noctalia"
          exit 1
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
              if builtins.pathExists "${officialPluginsSrc}/${pluginName}" then
                "${officialPluginsSrc}/${pluginName}"
              else
                "${communityPluginsSrc}/${pluginName}";
          }) cfg.plugins
          ++ [
            {
              ".face".source = ../../../layers/00-cyberia/02-assets/user_profile/cloud.gif;
              ".face.icon".source = ../../../layers/00-cyberia/02-assets/user_profile/cloud.gif;
            }
          ]
        );
        home.packages = with pkgs; [
          noctaliaPluginDoctor
          gst_all_1.gst-plugins-base
          gst_all_1.gst-plugins-good
          evtest
          gpu-screen-recorder
          mpvpaper
          libsecret
          python3
          ai-usagebar

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

            # Sync Spicetify / Spotify colors
            noctalia-spicetify-sync 2>/dev/null || true

            # Sync Rofi theme/colors
            pkill -USR2 rofi 2>/dev/null || true

            # Sync Starship prompt palette
            noctalia-starship-sync 2>/dev/null || true
          '')

          # Starship sync helper — enriches Noctalia starship palette with color_* aliases
          # and keeps ~/.cache/starship/starship.toml in sync with live Noctalia colors.
          (pkgs.writeShellScriptBin "noctalia-starship-sync" ''
            set -euo pipefail

            PALETTE_FILE="''${XDG_CACHE_HOME:-$HOME/.cache}/noctalia/starship-palette.toml"
            BASE_CONFIG="''${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml"
            CACHE_DIR="''${XDG_CACHE_HOME:-$HOME/.cache}/starship"
            TARGET_CONFIG="$CACHE_DIR/starship.toml"
            MARKER_BEGIN="# >>> NOCTALIA STARSHIP PALETTE >>>"
            MARKER_END="# <<< NOCTALIA STARSHIP PALETTE <<<"

            mkdir -p "$CACHE_DIR"

            if [ ! -f "$BASE_CONFIG" ]; then
              exit 0
            fi

            if [ ! -f "$PALETTE_FILE" ]; then
              if [ ! -f "$TARGET_CONFIG" ] || [ "$BASE_CONFIG" -nt "$TARGET_CONFIG" ]; then
                cp "$BASE_CONFIG" "$TARGET_CONFIG"
              fi
              exit 0
            fi

            # 1. Parse Noctalia palette and generate enriched palette definitions
            ENRICHED_PALETTE=$(awk '
              BEGIN { FS = "=" }
              /^[[:space:]]*[a-zA-Z0-9_]+[[:space:]]*=[[:space:]]*"[^"]+"/ {
                k = $1; v = $2
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", k)
                gsub(/^[[:space:]]*"|"[[:space:]]*$/, "", v)
                c[k] = v
              }
              END {
                fg0 = (c["text"] != "" ? c["text"] : (c["white"] != "" ? c["white"] : "#f3f3f2"))
                bg1 = (c["base"] != "" ? c["base"] : (c["surface0"] != "" ? c["surface0"] : "#292614"))
                bg3 = (c["surface1"] != "" ? c["surface1"] : (c["overlay0"] != "" ? c["overlay0"] : "#37331b"))
                blue = (c["blue"] != "" ? c["blue"] : "#88fe73")
                aqua = (c["teal"] != "" ? c["teal"] : (c["cyan"] != "" ? c["cyan"] : "#d3fe80"))
                green = (c["green"] != "" ? c["green"] : "#fee973")
                orange = (c["peach"] != "" ? c["peach"] : (c["rosewater"] != "" ? c["rosewater"] : "#cefe73"))
                purple = (c["mauve"] != "" ? c["mauve"] : (c["magenta"] != "" ? c["magenta"] : "#feeb80"))
                red = (c["red"] != "" ? c["red"] : "#fd4663")
                yellow = (c["yellow"] != "" ? c["yellow"] : "#cefe73")

                print "[palettes.noctalia]"
                for (k in c) {
                  if (k !~ /^color_/) {
                    print k " = \"" c[k] "\""
                  }
                }
                print "color_fg0 = \"" fg0 "\""
                print "color_bg1 = \"" bg1 "\""
                print "color_bg3 = \"" bg3 "\""
                print "color_blue = \"" blue "\""
                print "color_aqua = \"" aqua "\""
                print "color_green = \"" green "\""
                print "color_orange = \"" orange "\""
                print "color_purple = \"" purple "\""
                print "color_red = \"" red "\""
                print "color_yellow = \"" yellow "\""
              }
            ' "$PALETTE_FILE")

            # 2. Enrich PALETTE_FILE itself so if Noctalia builtin hook runs, it preserves color_* aliases
            TMP_PALETTE=$(mktemp)
            echo "$ENRICHED_PALETTE" > "$TMP_PALETTE"
            if ! cmp -s "$PALETTE_FILE" "$TMP_PALETTE"; then
              cat "$TMP_PALETTE" > "$PALETTE_FILE"
            fi
            rm -f "$TMP_PALETTE"

            # 3. Strip old noctalia block and palette = line from BASE_CONFIG
            TMP_BASE=$(mktemp)
            FINAL_FILE=$(mktemp)
            cleanup() {
              rm -f "$TMP_BASE" "$FINAL_FILE"
            }
            trap cleanup EXIT

            awk -v begin="$MARKER_BEGIN" -v end="$MARKER_END" '
              $0 == begin { in_block = 1; next }
              in_block {
                if ($0 == end) {
                  in_block = 0
                }
                next
              }
              /^[[:space:]]*palette[[:space:]]*=/ { next }
              { print }
            ' "$BASE_CONFIG" > "$TMP_BASE"

            # 4. Assemble merged file with palette = "noctalia"
            {
              if grep -qE '^"\$schema"' "$TMP_BASE"; then
                awk '
                  /^"\$schema"/ {
                    print
                    if (!inserted) {
                      print "palette = \"noctalia\""
                      inserted = 1
                    }
                    next
                  }
                  { print }
                ' "$TMP_BASE"
              else
                echo 'palette = "noctalia"'
                cat "$TMP_BASE"
              fi
              echo ""
              echo "$MARKER_BEGIN"
              echo "$ENRICHED_PALETTE"
              echo "$MARKER_END"
            } > "$FINAL_FILE"

            # 5. Atomic write if content changed
            if [ ! -f "$TARGET_CONFIG" ] || ! cmp -s "$TARGET_CONFIG" "$FINAL_FILE"; then
              mv "$FINAL_FILE" "$TARGET_CONFIG"
            fi
          '')
        ];

        programs = {
          noctalia = {
            enable = true;
            systemd.enable = true;
            inherit (cfg) package;
            checkConfig = true;

            settings = {
              # ── Shell ────────────────────────────────────────────────
              shell = {
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
                app_icon_colorize = false;
              };
              shell.animation = {
                speed = 0.75;
              };
              shell.greeter_sync = {
                auto_sync = true;
              };
              shell.launcher = {
                categories = true;
                default_view = "all";
                show_icons = true;
                sort_by_usage = true;
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
                directory = "/home/t0psh31f/Pictures";
                directory_dark = "/home/t0psh31f/Pictures";
                transition = [
                  "honeycomb"
                  "fade"
                ];
                transition_duration = 17600;
                transition_on_startup = true;
              };
              wallpaper.automation = {
                enabled = false;
                interval_seconds = 900;
                order = "random";
              };
              wallpaper.default = {
                path = "/home/t0psh31f/Pictures/one-piece-season-15-3840x2160-22127.jpg";
              };
              wallpaper.last = {
                path = "/home/t0psh31f/Pictures/one-piece-season-15-3840x2160-22127.jpg";
              };
              wallpaper.monitor = {
                "eDP-1" = {
                  directory = "/home/t0psh31f/Pictures";
                };
                "DP-1" = {
                  directory = "/home/t0psh31f/Pictures";
                };
                "HDMI-A-1" = {
                  directory = "/home/t0psh31f/Pictures";
                };
                "HDMI-A-2" = {
                  directory = "/home/t0psh31f/Pictures";
                };
              };
              wallpaper.monitors = {
                "eDP-1" = {
                  path = "/home/t0psh31f/Pictures/one-piece-season-15-3840x2160-22127.jpg";
                };
                "HDMI-A-2" = {
                  path = "/home/t0psh31f/Pictures/one-piece-season-15-3840x2160-22127.jpg";
                };
                "DP-2" = {
                  path = "/home/t0psh31f/Pictures/one-piece-season-15-3840x2160-22127.jpg";
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
              };

              # ── Four-Bar Cockpit Geometry & Theming ─────────────────
              bar = {
                order = [
                  "default"
                  "bottom-bar"
                  "left-bar"
                  "right-bar"
                ];
              };

              # 1. Top Bar: Always visible primary system cockpit
              bar.default = {
                enabled = true;
                position = "top";
                layer = "overlay";
                thickness = 44;
                scale = 1.15;
                padding = 14;
                panel_overlap = -2;
                margin_edge = 0;
                margin_ends = 36;
                margin_opposite_edge = 0;
                reserve_space = true;
                background_opacity = 0.82;
                border = "primary";
                border_width = 1.5;
                capsule = true;
                capsule_border = "secondary";
                capsule_border_width = 1.5;
                capsule_opacity = 0.85;
                capsule_padding = 9.0;
                concave_edge_corners = true;
                radius = 28;
                radius_top_left = 0;
                radius_top_right = 0;
                radius_bottom_left = 28;
                radius_bottom_right = 28;
                font_family = "Symbols Nerd Font Mono";
                widget_spacing = 4;
                color = "primary";
                icon_color = "secondary";
                start = [
                  "launcher"
                  "workspaces"
                ];
                center = [
                  "media"
                  "cat"
                ];
                end = [
                  "tailnet"
                  "battery"
                  "clock"
                  "control-center"
                ];
                dead_zone.actions = {
                  scroll_up = "volume-up";
                  scroll_down = "volume-down";
                  middle = "volume-mute";
                };
              };

              # 2. Bottom Bar: Always visible dock & taskbar hybrid
              bar.bottom-bar = {
                enabled = true;
                position = "bottom";
                layer = "overlay";
                thickness = 44;
                scale = 1.15;
                padding = 14;
                panel_overlap = -2;
                margin_edge = 0;
                margin_ends = 36;
                margin_opposite_edge = 0;
                reserve_space = true;
                background_opacity = 0.82;
                border = "primary";
                border_width = 1.5;
                capsule = true;
                capsule_border = "secondary";
                capsule_border_width = 1.5;
                capsule_opacity = 0.85;
                capsule_padding = 9.0;
                concave_edge_corners = true;
                radius = 28;
                radius_bottom_left = 0;
                radius_bottom_right = 0;
                radius_top_left = 28;
                radius_top_right = 28;
                font_family = "Symbols Nerd Font Mono";
                widget_spacing = 4;
                color = "primary";
                icon_color = "secondary";
                dead_zone.actions = {
                  scroll_up = "volume-up";
                  scroll_down = "volume-down";
                  middle = "volume-mute";
                };
                start = [
                  "session"
                  "notes"
                  "herdr"
                ];
                center = [
                  "taskbar"
                ];
                end = [
                  "cpu"
                  "gpu"
                  "ram"
                  "disk"
                  "clipboard"
                  "tray"
                  "notifications"
                ];
              };

              # 3. Left Bar: Auto-hiding AI fleet, containers & telemetry
              bar.left-bar = {
                enabled = true;
                position = "left";
                layer = "overlay";
                thickness = 44;
                scale = 1.15;
                padding = 14;
                panel_overlap = -2;
                margin_edge = 0;
                margin_ends = 36;
                margin_opposite_edge = 0;
                reserve_space = false;
                auto_hide = true;
                smart_auto_hide = true;
                auto_hide_delay_ms = 250;
                show_on_workspace_switch = true;
                background_opacity = 0.82;
                border = "hover";
                border_width = 1.5;
                capsule = true;
                capsule_border = "secondary";
                capsule_border_width = 1.5;
                capsule_opacity = 0.85;
                capsule_padding = 9.0;
                concave_edge_corners = true;
                radius = 28;
                radius_top_left = 0;
                radius_bottom_left = 0;
                radius_top_right = 28;
                radius_bottom_right = 28;
                font_family = "Symbols Nerd Font Mono";
                widget_spacing = 4;
                color = "primary";
                icon_color = "primary";
                start = [
                  "agents"
                  "herdr"
                ];
                center = [
                  "containers"
                  "ai-usage"
                  "router"
                ];
                end = [
                  "neuralwatt"
                  "ai-triage"
                ];
              };

              # 4. Right Bar: Auto-hiding quick tools & productivity
              bar.right-bar = {
                enabled = true;
                position = "right";
                layer = "overlay";
                thickness = 44;
                scale = 1.15;
                padding = 14;
                panel_overlap = -2;
                margin_edge = 0;
                margin_ends = 36;
                margin_opposite_edge = 0;
                reserve_space = false;
                auto_hide = true;
                smart_auto_hide = true;
                auto_hide_delay_ms = 250;
                show_on_workspace_switch = true;
                background_opacity = 0.82;
                border = "hover";
                border_width = 1.5;
                capsule = true;
                capsule_border = "secondary";
                capsule_border_width = 1.5;
                capsule_opacity = 0.85;
                capsule_padding = 9.0;
                concave_edge_corners = true;
                radius = 28;
                radius_top_right = 0;
                radius_bottom_right = 0;
                radius_top_left = 28;
                radius_bottom_left = 28;
                font_family = "Symbols Nerd Font Mono";
                widget_spacing = 4;
                color = "primary";
                icon_color = "primary";
                start = [
                  "screen-toolkit"
                  "screen_recorder"
                ];
                center = [
                  "todo"
                  "phone"
                  "mail"
                ];
                end = [
                  "wallhaven"
                  "theme-switcher"
                  "w-engine"
                ];
              };

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
                launcher_icon = "brand-nixos";
                launcher_position = "start";
                launcher_custom_image = "/home/t0psh31f/.icons/nixos-logo.png";
                margin_edge = 2;
                pinned = [ "Brave" ];
                radius = 23;
                reserve_space = false;
                show_dots = true;
              };

              # ── Hot Corners ──────────────────────────────────────────
              hot_corners = {
                enabled = true;
                top_left.action = "launcher";
                top_right.action = "control_center";
                bottom_left.action = "window_switcher";
              };

              # ── Idle ─────────────────────────────────────────────────
              # DISABLED: noctalia's native idle system causes Wayland
              # "Broken pipe" crashes on Intel Iris Xe when the display
              # wakes from DPMS screen-off. hypridle handles this instead.
              idle = {
                behavior_order = [ ];
                behavior = {
                  lock = {
                    action = "lock";
                    enabled = false;
                    timeout = 600.0;
                  };
                  screen-off = {
                    action = "screen_off";
                    enabled = false;
                    timeout = 660.0;
                  };
                  lock-and-suspend = {
                    action = "lock_and_suspend";
                    enabled = false;
                    timeout = 900.0;
                  };
                };
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
                "community/tailnet"
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
                }
                {
                  name = "community";
                  kind = "git";
                  location = "https://github.com/noctalia-dev/community-plugins";
                }
              ];

              # ── System Monitor (Low-Overhead Polling) ────────────────
              system.monitor = {
                cpu_poll_seconds = 5;
                gpu_poll_seconds = 30;
                memory_poll_seconds = 5;
                network_poll_seconds = 5;
                disk_poll_seconds = 60;
              };

              # ── Weather ──────────────────────────────────────────────
              weather = {
                unit = "imperial";
              };

              # ── Battery Device ───────────────────────────────────────
              battery.device."/org/freedesktop/UPower/devices/mouse_dev_4E_B6_4B_9A_28_22" = {
                warning_threshold = 10;
              };

              # ── Widget Definitions & Styling ─────────────────────────
              widget = {
                battery = {
                  capsule = true;
                  capsule_border = "primary";
                  capsule_fill = "on_primary";
                  capsule_foreground = "on_primary";
                  capsule_opacity = 0.92;
                  display_mode = "graphic";
                  scale = 1.1;
                };
                bluetooth = {
                  enabled = true;
                  capsule = true;
                  capsule_border = "primary";
                  capsule_fill = "on_primary";
                  capsule_foreground = "on_primary";
                  capsule_opacity = 0.90;
                };
                brightness = {
                  enabled = true;
                  show_label = false;
                  capsule = true;
                  capsule_border = "primary";
                  capsule_fill = "on_primary";
                  capsule_foreground = "on_primary";
                  capsule_opacity = 0.90;
                };
                clipboard = {
                  capsule = true;
                  capsule_border = "primary";
                  capsule_fill = "on_primary";
                  capsule_foreground = "on_primary";
                  capsule_opacity = 0.91;
                };
                clock = {
                  capsule = true;
                  capsule_border = "primary";
                  capsule_fill = "on_primary";
                  capsule_foreground = "on_primary";
                  capsule_opacity = 0.90;
                  format = "{:%a, %b %d %H:%M:%S}";
                  scale = 1.1;
                };
                tailnet = {
                  type = "rylos/tailnet:bar";
                  capsule = true;
                  capsule_border = "primary";
                  capsule_fill = "on_primary";
                  capsule_foreground = "secondary";
                  capsule_opacity = 0.90;
                };
                control-center = {
                  capsule = true;
                  capsule_border = "primary";
                  capsule_fill = "on_primary";
                  capsule_foreground = "secondary";
                  capsule_opacity = 0.91;
                  custom_image = "/home/t0psh31f/.icons/Anime/1P/one-piece-jolly-roger-icons-by-crountch/png/256x256/Luffys flag.png";
                };
                launcher = {
                  capsule = true;
                  capsule_border = "primary";
                  capsule_fill = "on_primary";
                  capsule_foreground = "secondary";
                  capsule_opacity = 0.89;
                  custom_image = "/home/t0psh31f/.icons/nixos-logo.png";
                  glyph = "brand-nixos";
                  scale = 1.25;
                };
                media = {
                  capsule = true;
                  capsule_border = "primary";
                  capsule_fill = "on_primary";
                  capsule_foreground = "secondary";
                  capsule_opacity = 0.93;
                  color = "primary";
                  hide_when_no_media = true;
                  min_length = 116;
                  title_scroll = "always";
                };
                network = {
                  capsule = true;
                  capsule_border = "primary";
                  capsule_fill = "on_primary";
                  capsule_foreground = "on_primary";
                  capsule_opacity = 0.90;
                  color = "primary";
                  enabled = true;
                  icon_color = "primary";
                };
                notifications = {
                  capsule = true;
                  hide_when_no_unread = true;
                };
                session = {
                  enabled = true;
                  capsule = true;
                  capsule_border = "primary";
                  capsule_fill = "on_primary";
                  capsule_foreground = "secondary";
                  capsule_opacity = 0.90;
                };
                tray = {
                  capsule = true;
                  capsule_border = "primary";
                  capsule_fill = "on_primary";
                  capsule_foreground = "secondary";
                  capsule_opacity = 0.93;
                  color = "secondary";
                  drawer = true;
                  icon_color = "secondary";
                };
                volume = {
                  capsule = true;
                  capsule_border = "primary";
                  capsule_fill = "on_primary";
                  capsule_foreground = "tertiary";
                  capsule_opacity = 0.86;
                  capsule_padding = 11;
                  scale = 1.1;
                };
                wallpaper = {
                  capsule = true;
                  capsule_border = "primary";
                  capsule_fill = "on_primary";
                  capsule_foreground = "secondary";
                  capsule_opacity = 0.88;
                  color = "primary";
                  icon_color = "primary";
                };
                workspaces = {
                  capsule = true;
                  capsule_border = "primary";
                  capsule_fill = "on_primary";
                  capsule_foreground = "secondary";
                  capsule_opacity = 0.90;
                  color = "primary";
                  label_source = "name";
                  show_labels = true;
                  empty_color = "tertiary";
                  icon_color = "primary";
                  labels_only_when_occupied = false;
                };
                taskbar = {
                  capsule = true;
                  capsule_border = "primary";
                  capsule_fill = "on_primary";
                  capsule_foreground = "secondary";
                  capsule_opacity = 0.90;
                  show_running = true;
                };
                cat = {
                  type = "noctalia/bongocat:cat";
                };
                notes = {
                  type = "noctalia/notes:notes";
                };
                agents = {
                  type = "notfinaldev/agentik:agents";
                };
                herdr = {
                  type = "hy4ri/herdr:bar";
                };
                containers = {
                  type = "davinci13/containers:bar";
                };
                ai-usage = {
                  type = "felipeartur/ai-usagebar:bar";
                };
                router = {
                  type = "weinguyen/9router-control:widget";
                };
                neuralwatt = {
                  type = "omertahaoztop/neuralwatt:bar";
                };
                ai-triage = {
                  type = "miguelfm/ai-triage:bar";
                };
                screen-toolkit = {
                  type = "alexander/screen-toolkit:widget";
                };
                todo = {
                  type = "nightwatch75/todo:todo";
                };
                phone = {
                  type = "icefish/phone-connect:bar";
                };
                mail = {
                  type = "mdj2812/thunderbird-companion:mail";
                };
                wallhaven = {
                  type = "noctalia/wallhaven:wallhaven";
                };
                theme-switcher = {
                  type = "theblackdon/theme-switcher:theme-switcher";
                };
                w-engine = {
                  type = "tadomika_ari/w-engine:w-engine-widget";
                };
                cpu = {
                  type = "sysmon";
                  stat = "cpu_usage";
                  show_value = true;
                  show_glyph = true;
                  visualization = "gauge";
                  capsule = true;
                  capsule_border = "primary";
                  capsule_fill = "on_primary";
                  capsule_foreground = "primary";
                  capsule_opacity = 0.85;
                };
                gpu = {
                  type = "sysmon";
                  stat = "gpu_usage";
                  show_value = true;
                  show_glyph = true;
                  visualization = "gauge";
                  capsule = true;
                  capsule_border = "primary";
                  capsule_fill = "on_primary";
                  capsule_foreground = "primary";
                  capsule_opacity = 0.85;
                };
                ram = {
                  type = "sysmon";
                  stat = "ram_pct";
                  show_value = true;
                  show_glyph = true;
                  visualization = "gauge";
                  capsule = true;
                  capsule_border = "primary";
                  capsule_fill = "on_primary";
                  capsule_foreground = "primary";
                  capsule_opacity = 0.85;
                };
                swap = {
                  type = "sysmon";
                  stat = "swap_pct";
                  show_value = true;
                  show_glyph = true;
                  visualization = "gauge";
                  capsule = true;
                  capsule_border = "primary";
                  capsule_fill = "on_primary";
                  capsule_foreground = "primary";
                  capsule_opacity = 0.85;
                };
                disk = {
                  type = "sysmon";
                  stat = "disk_free_pct";
                  path = "/";
                  show_value = true;
                  show_glyph = true;
                  visualization = "gauge";
                  capsule = true;
                  capsule_border = "primary";
                  capsule_fill = "on_primary";
                  capsule_foreground = "primary";
                  capsule_opacity = 0.85;
                };

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

          zsh.initContent = lib.mkAfter ''
            if command -v noctalia-starship-sync >/dev/null 2>&1; then
              noctalia-starship-sync
            fi
          '';

          bash.initExtra = lib.mkAfter ''
            if command -v noctalia-starship-sync >/dev/null 2>&1; then
              noctalia-starship-sync
            fi
          '';
        };

        systemd.user = {
          services = {
            # Noctalia v5 is statically linked and dlopen's libEGL.so at runtime.
            # Two vars are required for eglGetDisplay to succeed:
            #   1. LD_LIBRARY_PATH — so dlopen("libEGL.so") finds the GLVND dispatcher
            #      (/run/opengl-driver/lib only has libEGL_mesa.so, not the dispatcher)
            #   2. __EGL_VENDOR_LIBRARY_DIRS — so GLVND can locate the Mesa ICD
            #      vendor JSON (50_mesa.json) and back the dispatcher with a real driver.
            # Without both, eglGetDisplay returns NULL and noctalia crashes on startup.
            noctalia = {
              Service = {
                Environment = [
                  "LD_LIBRARY_PATH=${pkgs.libglvnd}/lib:/run/opengl-driver/lib"
                  "__EGL_VENDOR_LIBRARY_DIRS=/run/opengl-driver/share/glvnd/egl_vendor.d"
                ];
              };
            };

            noctalia-experience-dirs = {
              Unit = {
                Description = "Ensure Noctalia HVE cache and experience directories exist";
                Before = [ "graphical-session-pre.target" ];
              };
              Install = {
                WantedBy = [ "graphical-session-pre.target" ];
              };
              Service = {
                Type = "oneshot";
                RemainAfterExit = true;
                ExecStart = "${pkgs.bash}/bin/bash -c 'mkdir -p %h/.config/hypr/experiences %h/.cache/noctalia/HVE'";
              };
            };

            # Sync Noctalia colors → Hyprland borders, Zellij, and Starship on login.
            # Runs noctalia-hypr-reload which regenerates noctalia-colors.conf
            # from the current wallpaper and reloads the compositor.
            noctalia-colors-sync = {
              Unit = {
                Description = "Sync Noctalia colors to Hyprland, Zellij, and Starship";
                After = [
                  "graphical-session.target"
                  "noctalia.service"
                ];
                Requires = [ "noctalia.service" ];
              };
              Service = {
                Type = "oneshot";
                ExecStart = "${pkgs.bash}/bin/bash -c 'sleep 3 && noctalia-hypr-reload && noctalia-starship-sync'";
              };
              Install = {
                WantedBy = [ "graphical-session.target" ];
              };
            };
          };

          # Re-sync colors every 15 min (wallpaper auto-regenerates on this cycle)
          timers.noctalia-colors-sync = {
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
    };
}
