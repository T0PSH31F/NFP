# Nixarchy Rise Desktop Experience Adapter
# Activates when: layers.desktop.experience = "nixarchy-rise"
#
# Provides: Omarchy 4.x environment (nixarchy) with HANCORE Quickshell Rise
# as the primary bar/launcher/notification layer, plus nixfred/infomarchy
# live AI agent & fleet wallpaper information desk.
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

  # HANCORE Quickshell Rise modular bar with live-wire particle animations
  hancore-quickshell-rise = pkgs.stdenv.mkDerivation {
    pname = "hancore-quickshell-rise";
    version = "2.8.0";
    src = inputs.quickshell-rise;
    installPhase = ''
      mkdir -p $out/share/quickshell/rise
      cp -r versions/V1/. $out/share/quickshell/rise/
      mkdir -p $out/bin
      cp scripts/qs-barctl $out/bin/qs-barctl
      chmod +x $out/bin/qs-barctl
    '';
  };

  # Infomarchy plugin (https://github.com/nixfred/infomarchy)
  # Live AI agent sessions, 7-day heatmap, rate limits, recent tasks, fleet & machine stats on wallpaper/overlay
  infomarchySrc = pkgs.fetchFromGitHub {
    owner = "nixfred";
    repo = "infomarchy";
    rev = "915585d1ceba7798caa765df9485f0199d015200";
    hash = "sha256-qtAsxo7WhgXJn0xMvRIUn05+RE/BxGsPNl61SKORBn4=";
  };

  #Runtime PATH for omarchy-shell and Infomarchy collector.ts (bun, iw, ip, ping, gh, sqlite3, qrencode, wl-clipboard, grim, imagemagick)
  infomarchyRuntimePath = lib.makeBinPath [
    nixarchyPkg
    pkgs.bun
    pkgs.iw
    pkgs.iproute2
    pkgs.iputils
    pkgs.gh
    pkgs.sqlite
    pkgs.qrencode
    pkgs.wl-clipboard
    pkgs.grim
    pkgs.imagemagick
    pkgs.openssl
    pkgs.python3
    pkgs.openssh
    pkgs.git
    pkgs.util-linux
    pkgs.coreutils
    pkgs.jq
    pkgs.bash
  ];

  # Deterministic IPC wrapper that always sets OMARCHY_PATH to the active nixarchy store path
  # so Hyprland keybindings never fail due to a missing/stale OMARCHY_PATH in Hyprland's environment.
  infomarchy-ctl = pkgs.writeShellScriptBin "infomarchy-ctl" ''
    set -euo pipefail
    export OMARCHY_PATH="${nixarchyPkg}/share/omarchy"
    export PATH="${infomarchyRuntimePath}:$PATH"

    cmd="''${1:-overlay}"
    shift || true

    case "$cmd" in
      overlay|desk)
        exec "${nixarchyPkg}/bin/omarchy-shell" shell toggle nixfred.infomarchy '{}'
        ;;
      toggle|dashboard)
        exec "${nixarchyPkg}/bin/omarchy-shell" infomarchy toggleDashboard
        ;;
      privacy)
        exec "${nixarchyPkg}/bin/omarchy-shell" infomarchy togglePrivacy
        ;;
      refresh|hard-refresh)
        exec "${nixarchyPkg}/bin/omarchy-shell" infomarchy hardRefresh
        ;;
      web|toggle-web)
        exec "${nixarchyPkg}/bin/omarchy-shell" infomarchy toggleWeb
        ;;
      copy-url)
        exec "${nixarchyPkg}/bin/omarchy-shell" infomarchy copyWebUrl
        ;;
      geometry|status)
        exec "${nixarchyPkg}/bin/omarchy-shell" infomarchy geometry
        ;;
      *)
        exec "${nixarchyPkg}/bin/omarchy-shell" infomarchy "$cmd" "$@"
        ;;
    esac
  '';

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
        Comment=Omarchy 4.x with HANCORE Quickshell Rise & Infomarchy
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
      hancore-quickshell-rise
      infomarchy-ctl
      nixarchy-session
      nixarchy-rise-wayland-session
      pkgs.quickshell
      pkgs.bun
      pkgs.iw
      pkgs.iproute2
      pkgs.iputils
      pkgs.gh
      pkgs.sqlite
      pkgs.qrencode
      pkgs.wl-clipboard
      pkgs.grim
      pkgs.imagemagick
      pkgs.inotify-tools
      pkgs.qt6.qtimageformats
      pkgs.xdg-terminal-exec
      pkgs.mako
      pkgs.matugen # Material You color token generator
      pkgs.mpvpaper # Live video wallpaper for Wayland
      pkgs.jq
      # Universal wallpaper switcher for image & mp4/video backgrounds
      (pkgs.writeShellScriptBin "nfp-wallpaper" ''
        set -euo pipefail
        TARGET="''${1:-}"
        if [[ -z "$TARGET" ]]; then
          echo "Usage: nfp-wallpaper <path-to-image-or-video>" >&2
          exit 1
        fi
        TARGET="$(realpath "$TARGET")"
        if [[ ! -f "$TARGET" ]]; then
          echo "File does not exist: $TARGET" >&2
          exit 1
        fi
        EXT="''${TARGET##*.}"
        EXT="''${EXT,,}"
        mkdir -p "$HOME/.local/state/omarchy/current"
        ln -nsf "$TARGET" "$HOME/.local/state/omarchy/current/background"
        if [[ "$EXT" =~ ^(mp4|webm|mkv|mov|avi)$ ]]; then
          pkill -x mpvpaper 2>/dev/null || true
          MONITORS=$(hyprctl monitors -j 2>/dev/null | ${pkgs.jq}/bin/jq -r '.[].name' 2>/dev/null || echo "*")
          for MON in $MONITORS; do
            ${pkgs.mpvpaper}/bin/mpvpaper -p -o "no-audio loop" "$MON" "$TARGET" &
          done
        else
          pkill -x mpvpaper 2>/dev/null || true
          if command -v awww >/dev/null 2>&1; then
            awww img "$TARGET" 2>/dev/null || true
          fi
          if command -v swww >/dev/null 2>&1; then
            swww img "$TARGET" 2>/dev/null || true
          fi
        fi
        if command -v omarchy >/dev/null 2>&1; then
          omarchy theme bg set "$TARGET" >/dev/null 2>&1 || true
        fi
      '')
      # Compatibility wrapper for Omarchy scripts expecting GNOME Nautilus
      (pkgs.writeShellScriptBin "nautilus" ''
        if command -v dolphin >/dev/null 2>&1; then
          exec dolphin "$@"
        else
          exec xdg-open "$@"
        fi
      '')
    ];

    environment.sessionVariables = {
      OMARCHY_PATH = "${nixarchyPkg}/share/omarchy";
      INFOMARCHY_FLEET_HOSTS = "luffy,z0r0,sanji";
    };
  };

  home =
    { config, lib, ... }:
    {
      config = lib.mkIf isEnabled {
        # $ipc uses Quickshell IPC — NOT noctalia msg
        wayland.windowManager.hyprland.settings."$ipc" = lib.mkForce "qs ipc";

        # Deploy configuration files
        xdg.configFile = {
          "quickshell/rise".source = "${hancore-quickshell-rise}/share/quickshell/rise";
          "quickshell/bar".source = "${hancore-quickshell-rise}/share/quickshell/rise";

          # Ensure Ghostty is the default terminal for xdg-terminal-exec
          "xdg-terminals.list".text = "ghostty.desktop\ncom.mitchellh.ghostty.desktop\n";

          # Active experience configuration for standard Hyprland sessions
          "hypr/experiences/nixarchy-rise.conf".text = ''
            # Nixarchy Rise Hyprland Experience Configuration
            $ipc = qs ipc

            # Environment variables for Omarchy & Infomarchy runtime
            env = OMARCHY_PATH,${nixarchyPkg}/share/omarchy
            env = INFOMARCHY_FLEET_HOSTS,luffy,z0r0,sanji
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
            # Only blur opaque surfaces (bar, dock). Transparent full-screen canvases
            # (menu overlay, notifications, osd) must NOT be blurred or they black out the viewport.
            layerrule = blur 1, match:namespace ^omarchy-(bar|dock)$
            layerrule = no_anim 1, match:namespace ^omarchy-(bar|menu|notifications|dock|osd)$

            # Omarchy shortcuts & bindings
            unbind = $mod, Space
            unbind = $mod, SPACE
            bind = $mod, SPACE, exec, omarchy-menu toggle
            bind = $mod, A, exec, omarchy-menu toggle apps
            bind = $mod, comma, exec, omarchy-menu toggle setup
            bind = $mod SHIFT, Space, exec, vicinae toggle

            # Infomarchy AI Info Desk & Wallpaper Dashboard shortcuts
            unbind = $mod, D
            unbind = $mod, I
            unbind = $mod SHIFT, I
            bind = $mod, D, exec, ${infomarchy-ctl}/bin/infomarchy-ctl overlay
            bind = $mod, I, exec, ${infomarchy-ctl}/bin/infomarchy-ctl toggle
            bind = $mod SHIFT, I, exec, ${infomarchy-ctl}/bin/infomarchy-ctl privacy
            bind = $mod ALT, I, exec, ${infomarchy-ctl}/bin/infomarchy-ctl refresh

            # NFP Shared Multi-Agent Todo shortcuts
            unbind = $mod, period
            bind = $mod, period, exec, rofi-todo
            bind = $mod SHIFT, period, exec, rofi-todo --quick-add
          '';

          "hypr/experiences/active-experience.conf".text = ''
            source = ${config.home.homeDirectory}/.config/hypr/experiences/nixarchy-rise.conf
          '';

          # Link Omarchy Hyprland Lua configs + declarative bindings.lua with Infomarchy & Shared Todo
          "hypr/monitors.lua".source = lib.mkDefault "${nixarchyPkg}/share/omarchy/config/hypr/monitors.lua";
          "hypr/input.lua".source = lib.mkDefault "${nixarchyPkg}/share/omarchy/config/hypr/input.lua";
          "hypr/bindings.lua".text = ''
            -- Nixarchy personal & plugin keybindings (managed declaratively by NFP)
            o.bind("SUPER + ALT + N", "Packages", "nixarchy-plugin nixarchy.pkg")
            o.bind("SUPER + ALT + O", "Podman", "nixarchy-plugin nixarchy.podman")
            o.bind("SUPER + ALT + P", "GitLab Pipelines", "nixarchy-plugin olafkfreund.gitlab-pipelines")
            o.bind("SUPER + CTRL + ALT + P", "GitLab Pipelines keybindings", "python3 $HOME/.config/omarchy/plugins/olafkfreund.gitlab-pipelines/menu.py keys")
            o.bind("SUPER + ALT + A", "GitHub Actions", "nixarchy-plugin olafkfreund.github-actions")
            o.bind("SUPER + CTRL + ALT + A", "GitHub Actions keybindings", "python3 $HOME/.config/omarchy/plugins/olafkfreund.github-actions/menu.py keys")
            o.bind("SUPER + ALT + H", "Herdr", "nixarchy-plugin nixarchy.herdr")
            o.bind("SUPER + ALT + V", "MicroVMs", "nixarchy-plugin nixarchy.microvm")
            o.bind("SUPER + ALT + D", "Distrobox", "nixarchy-plugin nixarchy.distrobox")
            o.bind("SUPER + ALT + E", "Dev environments", "nixarchy-plugin nixarchy.devenv")
            o.bind("SUPER + ALT + U", "Plugin browser", "nixarchy-plugin io.github.olafkfreund.nixarchy-plugin-browser")
            o.bind("SUPER + SHIFT + ESCAPE", "ai-mirror: stop agent control", "ai-mirror control off")

            -- Infomarchy: Live AI Info Desk & Wallpaper Dashboard
            hl.unbind("SUPER + D")
            hl.unbind("SUPER + I")
            hl.unbind("SUPER + SHIFT + I")
            o.bind("SUPER + D", "Infomarchy: AI info desk overlay", "${infomarchy-ctl}/bin/infomarchy-ctl overlay")
            o.bind("SUPER + I", "Infomarchy: toggle wallpaper dashboard", "${infomarchy-ctl}/bin/infomarchy-ctl toggle")
            o.bind("SUPER + SHIFT + I", "Infomarchy: stream privacy", "${infomarchy-ctl}/bin/infomarchy-ctl privacy")
            o.bind("SUPER + ALT + I", "Infomarchy: hard refresh collectors", "${infomarchy-ctl}/bin/infomarchy-ctl refresh")

            -- NFP Shared Multi-Agent Todo List
            hl.unbind("SUPER + PERIOD")
            o.bind("SUPER + PERIOD", "Shared Agent Todo List", "rofi-todo")
            o.bind("SUPER + SHIFT + PERIOD", "Quick-Add Shared Todo", "rofi-todo --quick-add")
          '';
          "hypr/looknfeel.lua".source =
            lib.mkDefault "${nixarchyPkg}/share/omarchy/config/hypr/looknfeel.lua";
          "hypr/autostart.lua".source =
            lib.mkDefault "${nixarchyPkg}/share/omarchy/config/hypr/autostart.lua";
        };

        systemd.user.services = {
          # Omarchy Shell background daemon (Menu, OSD, Wallpaper, Infomarchy, Idle)
          omarchy-shell = {
            Unit = {
              Description = "Omarchy Shell service (Menu, OSD, Infomarchy Background)";
              After = [
                "graphical-session.target"
                "nixarchy-state-init.service"
              ];
              PartOf = [ "graphical-session.target" ];
            };
            Install = {
              WantedBy = [ "graphical-session.target" ];
            };
            Service = {
              Environment = [
                "OMARCHY_PATH=${nixarchyPkg}/share/omarchy"
                "INFOMARCHY_FLEET_HOSTS=luffy,z0r0,sanji"
                "PATH=${infomarchyRuntimePath}:/run/current-system/sw/bin:/etc/profiles/per-user/%u/bin"
              ];
              ExecStart = "${nixarchyPkg}/bin/omarchy-launch-shell";
              Restart = "on-failure";
              RestartSec = "2s";
            };
          };

          # HANCORE Quickshell Rise status bar service (single instance)
          quickshell-rise = {
            Unit = {
              Description = "Hancore Quickshell Rise Status Bar";
              After = [
                "graphical-session.target"
                "omarchy-shell.service"
                "nixarchy-state-init.service"
              ];
              PartOf = [ "graphical-session.target" ];
            };
            Install = {
              WantedBy = [ "graphical-session.target" ];
            };
            Service = {
              Environment = "OMARCHY_PATH=${nixarchyPkg}/share/omarchy";
              ExecStart = "${pkgs.quickshell}/bin/quickshell -p %h/.config/quickshell/rise";
              Restart = "on-failure";
              RestartSec = "2s";
            };
          };

          # Ensure default Omarchy theme, Infomarchy plugin, and mutable shell.json state exist on login
          nixarchy-state-init = {
            Unit = {
              Description = "Initialize default theme, Infomarchy plugin, and state for Nixarchy Rise";
              After = [ "graphical-session-pre.target" ];
              PartOf = [ "graphical-session.target" ];
            };
            Install = {
              WantedBy = [ "graphical-session.target" ];
            };
            Service = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = pkgs.writeShellScript "nixarchy-state-init" ''
                set -euo pipefail
                mkdir -p "$HOME/.local/state/omarchy/current" "$HOME/.local/state/infomarchy" "$HOME/.config/omarchy/plugins" "$HOME/.cache"

                # 1. Seed default Omarchy theme & wallpaper if missing
                if [ ! -e "$HOME/.local/state/omarchy/current/theme" ]; then
                  ln -sfn "${nixarchyPkg}/share/omarchy/themes/catppuccin" "$HOME/.local/state/omarchy/current/theme"
                  ln -sfn "${nixarchyPkg}/share/omarchy/themes/catppuccin/backgrounds/2-waves.webp" "$HOME/.local/state/omarchy/current/background"
                  echo "Catppuccin" > "$HOME/.local/state/omarchy/current/theme.name"
                  echo "1" > "$HOME/.local/state/omarchy/current/theme.generation"
                fi
                ln -sfn "$HOME/.local/state/omarchy/current" "$HOME/.config/omarchy/current"

                # 2. Seed nixfred.infomarchy plugin directory if missing
                if [ ! -f "$HOME/.config/omarchy/plugins/nixfred.infomarchy/manifest.json" ]; then
                  mkdir -p "$HOME/.config/omarchy/plugins/nixfred.infomarchy"
                  cp -rf "${infomarchySrc}/." "$HOME/.config/omarchy/plugins/nixfred.infomarchy/"
                  chmod -R u+w "$HOME/.config/omarchy/plugins/nixfred.infomarchy"
                fi

                # 3. Ensure ~/.config/omarchy/shell.json is a mutable JSON file with nixfred.infomarchy enabled
                SHELL_JSON="$HOME/.config/omarchy/shell.json"
                if [ -L "$SHELL_JSON" ]; then
                  rm -f "$SHELL_JSON"
                fi
                if [ ! -f "$SHELL_JSON" ]; then
                  cat > "$SHELL_JSON" <<'EOF_JSON'
                {
                  "version": 1,
                  "plugins": [
                    { "id": "nixfred.infomarchy" }
                  ],
                  "disabledPlugins": [
                    "omarchy.bar",
                    "omarchy.dock",
                    "omarchy.notifications",
                    "omarchy.background"
                  ],
                  "cloneSourceRestores": [
                    "nixfred.infomarchy"
                  ]
                }
                EOF_JSON
                else
                  # Merge nixfred.infomarchy plugin & disabledPlugins idempotently via jq
                  ${pkgs.jq}/bin/jq '
                    .version = (.version // 1)
                    | .plugins = (((.plugins // []) + [{"id": "nixfred.infomarchy"}]) | unique_by(.id))
                    | .disabledPlugins = (((.disabledPlugins // []) + ["omarchy.bar", "omarchy.dock", "omarchy.notifications", "omarchy.background"]) | unique)
                    | .cloneSourceRestores = (((.cloneSourceRestores // []) + ["nixfred.infomarchy"]) | unique)
                  ' "$SHELL_JSON" > "$SHELL_JSON.tmp" && mv "$SHELL_JSON.tmp" "$SHELL_JSON"
                fi

                # 4. Quickshell Rise split defaults
                [ ! -f "$HOME/.cache/quickshell_splits" ] && echo "1 1 1 1 3 color02" > "$HOME/.cache/quickshell_splits" || true
                [ ! -f "$HOME/.cache/quickshell_barsplits" ] && printf "010000|000000|11" > "$HOME/.cache/quickshell_barsplits" || true
              '';
            };
          };

          # Matugen hook — generate color tokens from current wallpaper on login
          nixarchy-matugen-init = {
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

          # Video wallpaper daemon — auto-play mpvpaper when background is an MP4/video
          nfp-video-wallpaper = {
            Unit = {
              Description = "NFP Live Video Wallpaper Manager";
              After = [ "graphical-session.target" ];
              PartOf = [ "graphical-session.target" ];
            };
            Install = {
              WantedBy = [ "graphical-session.target" ];
            };
            Service = {
              Restart = "always";
              RestartSec = "3s";
              ExecStart = pkgs.writeShellScript "nfp-video-wallpaper-daemon" ''
                BG_LINK="$HOME/.local/state/omarchy/current/background"
                LAST_BG=""
                while true; do
                  if [ -L "$BG_LINK" ] || [ -f "$BG_LINK" ]; then
                    CURR_BG="$(readlink -f "$BG_LINK" 2>/dev/null || true)"
                    if [ "$CURR_BG" != "$LAST_BG" ]; then
                      LAST_BG="$CURR_BG"
                      EXT="''${CURR_BG##*.}"
                      EXT="''${EXT,,}"
                      if [[ "$EXT" =~ ^(mp4|webm|mkv|mov|avi)$ ]] && [ -f "$CURR_BG" ]; then
                        ${pkgs.procps}/bin/pkill -x mpvpaper 2>/dev/null || true
                        MONITORS=$(${pkgs.hyprland}/bin/hyprctl monitors -j 2>/dev/null | ${pkgs.jq}/bin/jq -r '.[].name' 2>/dev/null || echo "*")
                        for MON in $MONITORS; do
                          ${pkgs.mpvpaper}/bin/mpvpaper -p -o "no-audio loop" "$MON" "$CURR_BG" &
                        done
                      else
                        ${pkgs.procps}/bin/pkill -x mpvpaper 2>/dev/null || true
                      fi
                    fi
                  fi
                  sleep 2
                done
              '';
            };
          };
        };
      };
    };
}
