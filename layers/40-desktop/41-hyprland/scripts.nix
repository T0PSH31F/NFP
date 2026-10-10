{
  osConfig ? config,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = osConfig.layers.layer-40.desktop.hyprland;
  sfxCfg =
    osConfig.layers.layer-30.theming.sfx or {
      sounds = {
        switchFocus = "switch-focus.wav";
        moveWindow = "move-window.wav";
        openWindow = "open-window.wav";
        closeWindow = "close-window.wav";
      };
    };

  # ── IPC Audio Feedback Daemon ────────────────────────────────────
  hypr-sfx = pkgs.writeShellScriptBin "hypr-sfx" ''
    #!/usr/bin/env bash
    # Hyprland IPC Audio Feedback Daemon
    # Listens on Hyprland's socket2 for window events and plays UI sounds
    # via PipeWire's pw-play.

    # Ensure only one instance runs
    LOCK="/tmp/hypr-sfx-$USER.lock"
    exec 200>$LOCK
    flock -n 200 || { echo "hypr-sfx: already running." >&2; exit 0; }

    SOUND_DIR="$HOME/Clan/NFP/layers/00-cyberia/02-assets/SFX"
    SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

    # Wait for socket to exist
    for i in $(seq 1 30); do
      [ -S "$SOCKET" ] && break
      sleep 0.5
    done

    if [ ! -S "$SOCKET" ]; then
      echo "hypr-sfx: Hyprland socket2 not found, exiting." >&2
      exit 1
    fi

    LAST_MOVE=0
    MUTE_FILE="/tmp/hypr-sfx.muted"

    play_sound() {
      if [ -f "$MUTE_FILE" ]; then
        return
      fi
      local file="$SOUND_DIR/$1"
      if [ -f "$file" ]; then
        # Rate-limit movewindow sounds to 5 per second
        if [[ "$1" == "${sfxCfg.sounds.moveWindow}" ]]; then
           local now=$(date +%s%3N)
           if (( now - LAST_MOVE < 200 )); then
              return
           fi
           LAST_MOVE=$now
        fi
        ${pkgs.pipewire}/bin/pw-play "$file" &
      fi
    }

    echo "hypr-sfx: Listening on $SOCKET"

    ${pkgs.socat}/bin/socat -U - UNIX-CONNECT:"$SOCKET" | while IFS= read -r line; do
      case "$line" in
        activewindow\>\>*)  play_sound "${sfxCfg.sounds.switchFocus}"  ;;
        movewindow\>\>*)    play_sound "${sfxCfg.sounds.moveWindow}"   ;;
        openwindow\>\>*)    play_sound "${sfxCfg.sounds.openWindow}"   ;;
        closewindow\>\>*)   play_sound "${sfxCfg.sounds.closeWindow}"  ;;
      esac
    done
  '';

  # ── SFX Mute Toggle Script ─────────────────────────────────────
  hypr-sfx-toggle = pkgs.writeShellScriptBin "hypr-sfx-toggle" ''
    #!/usr/bin/env bash
    MUTE_FILE="/tmp/hypr-sfx.muted"
    if [ -f "$MUTE_FILE" ]; then
      rm -f "$MUTE_FILE"
      ${pkgs.libnotify}/bin/notify-send -t 2000 -i audio-volume-high "UI Sounds" "Unmuted"
      ${pkgs.pipewire}/bin/pw-play "$HOME/Clan/NFP/layers/00-cyberia/02-assets/SFX/${sfxCfg.sounds.openWindow}" &
    else
      touch "$MUTE_FILE"
      ${pkgs.pipewire}/bin/pw-play "$HOME/Clan/NFP/layers/00-cyberia/02-assets/SFX/${sfxCfg.sounds.closeWindow}"
      ${pkgs.libnotify}/bin/notify-send -t 2000 -i audio-volume-muted "UI Sounds" "Muted"
    fi
  '';

  # ── Theme Switch Master Trigger ──────────────────────────────────
  theme-switch = pkgs.writeShellScriptBin "theme-switch" ''
    #!/usr/bin/env bash
    # theme-switch.sh — Master trigger for the Noctalia dynamic theming pipeline
    # Usage: theme-switch <wallpaper_path>
    #        theme-switch --pick   (opens file picker)

    set -euo pipefail

    WALLPAPER="''${1:-}"

    # ── File picker mode ──
    if [ "$WALLPAPER" = "--pick" ] || [ -z "$WALLPAPER" ]; then
      WALLPAPER=$(find "$HOME/.background" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.webp" -o -name "*.gif" \) 2>/dev/null | shuf -n1)
      if [ -z "$WALLPAPER" ]; then
        notify-send -u critical "Theme Switch" "No wallpapers found in ~/.background/"
        exit 1
      fi
    fi

    if [ ! -f "$WALLPAPER" ]; then
      echo "Error: File not found: $WALLPAPER" >&2
      exit 1
    fi

    notify-send -t 3000 "Theme Switch" "Applying: $(basename "$WALLPAPER")"

    # ── Detect compositor ──
    COMPOSITOR="''${XDG_CURRENT_DESKTOP:-unknown}"

    # ── Step 1: Apply wallpaper ──
    # Static/animated image via awww
    if ! pgrep -x awww-daemon >/dev/null; then
      ${pkgs.awww}/bin/awww-daemon &
      disown
      sleep 1
    fi
    ${pkgs.awww}/bin/awww img "$WALLPAPER" \
      --transition-type grow \
      --transition-pos 0.5,0.9 \
      --transition-duration 2 \
      --transition-fps 60

    # ── Step 2: Trigger active experience wallpaper hook ──
    if [ -x "$HOME/.config/hypr/experiences/wallpaper-hook.sh" ]; then
      "$HOME/.config/hypr/experiences/wallpaper-hook.sh" "$WALLPAPER" 2>/dev/null || true
    fi

    # ── Step 3: Wait for theme generation to settle ──
    sleep 2

    # ── Step 4: Live-reload ALL apps (async for speed) ──

    # Hyprland / Niri
    case "$COMPOSITOR" in
      Hyprland|hyprland)
        hyprctl reload &
        # Force GPU shader recompile (toggle off then on)
        hyprctl keyword decoration:screen_shader "" 2>/dev/null
        sleep 0.3
        hyprctl keyword decoration:screen_shader "$HOME/.config/hypr/vibrancy.frag" 2>/dev/null &
        ;;
      niri|Niri)
        niri msg action load-config-file &
        ;;
    esac

    # Kitty — reload colors in all instances
    if command -v kitty >/dev/null 2>&1; then
      kitty +kitten themes --reload-in=all Matugen 2>/dev/null &
    fi

    # Ghostty — SIGUSR2 triggers config reload
    pkill -SIGUSR2 ghostty 2>/dev/null &

    # Pywalfox — update Firefox/LibreWolf theme
    if command -v pywalfox >/dev/null 2>&1; then
      pywalfox update 2>/dev/null &
    fi

    # Spicetify — apply without restart
    if command -v spicetify >/dev/null 2>&1; then
      spicetify apply -n 2>/dev/null &
    fi

    # Neovim — SIGUSR1 reloads colorscheme in all instances
    pkill -SIGUSR1 nvim 2>/dev/null &

    # Btop — SIGUSR2 reloads theme
    pkill -USR2 btop 2>/dev/null &

    # Cava — SIGUSR1 reloads config
    pkill -USR1 cava 2>/dev/null &

    # GTK — toggle theme to force reload
    if command -v gsettings >/dev/null 2>&1; then
      (
        current_theme=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'")
        gsettings set org.gnome.desktop.interface gtk-theme "" 2>/dev/null
        sleep 0.2
        gsettings set org.gnome.desktop.interface gtk-theme "''${current_theme:-adw-gtk3-dark}" 2>/dev/null
      ) &
    fi

    # SwayNC — reload style
    if command -v swaync-client >/dev/null 2>&1; then
      swaync-client -rs 2>/dev/null &
    fi

    wait
    notify-send -t 3000 "Theme Switch" "All apps reloaded!"
  '';

  hypr-keybind-cheatsheet = pkgs.writeShellScriptBin "hypr-keybind-cheatsheet" ''
      #!/usr/bin/env bash
      CHEATSHEET="
    📱 LAUNCHERS & SHELL
    ─────────────────────────────────────────
    Super + A                  Noctalia Launcher
    Super + Space              Vicinae Launcher (Fast)
    Super + Tab                Noctalia Overview
    Super + X                  Control Center
    Super + Comma              Settings
    Super + L                  Lock Screen
    Ctrl + Alt + Del           Session Menu
    Super + Shift + N          Notification Center
    Super + /                  This Cheatsheet

    🪟 WINDOW MANAGEMENT
    ─────────────────────────────────────────
    Super + Q                  Kill Active Window
    Super + V                  Toggle Floating Window
    Super + Shift + V          Toggle Window Pin & Float
    Super + F                  Fullscreen
    Super + Shift + F          Maximize
    Super + Shift + -          1/3 Width Preset
    Super + Shift + =          2/3 Width Preset
    Super + Ctrl + -           1/2 Width Preset
    Super + Ctrl + L           Cycle Workspace Layout
    Super + Arrows             Move Focus
    Super + Shift + Arrows     Move Window
    Super + Mouse (Left)       Move Window
    Super + Mouse (Right)      Resize Window
    Super + -/=                Split Ratio
    Alt + Tab                  Cycle Windows

    🖥️ WORKSPACES
    ─────────────────────────────────────────
    Super + 1-9/0              Switch to Workspace
    Super + Shift + 1-9/0      Move to Workspace
    Super + Alt + 1-9/0        Move Silently
    Super + Ctrl + Left/Right  Previous/Next Workspace
    Super + Mouse Wheel        Scroll Workspaces
    Super + Shift + S          Toggle Special Workspace

    🎮 SCRATCHPADS
    ─────────────────────────────────────────
    Alt + T or Alt + Enter     Ghostty Dropdown Terminal
    Super + H                  Gedit Scratchpad
    Super + Shift + E          nwg-look GTK Themes

    🚀 APPLICATIONS
    ─────────────────────────────────────────
    Super + T or Return        Ghostty Terminal
    Super + Shift + T          Kitty Terminal
    Super + Shift + Return     Warp Terminal
    Super + W                  Brave Browser
    Super + Ctrl + W           LibreWolf Browser
    Super + Shift + W          Mullvad Browser
    Super + E                  Thunar File Manager
    Super + Ctrl + E           SuperFile (Terminal)
    Super + Y                  Yazelix Editor
    Super + Shift + Y          Yazi File Browser
    Super + M                  Spotify

    🎨 YAZELIX EDITOR
    ─────────────────────────────────────────
    Within Yazelix:
    Space                      Command Palette
    Space + f                  Find Files
    Space + /                  Search in Files
    Space + b                  Buffer List
    Space + w                  Save File
    Space + q                  Quit
    Ctrl + h/j/k/l             Navigate Splits
    g + d                      Go to Definition
    g + r                      Find References
    Space + e                  File Explorer Toggle
    Space + g                  Git Status

    📸 SCREENSHOTS
    ─────────────────────────────────────────
    Print                      Noctalia Screenshot
    Shift + Print              Flameshot Full Screen
    Ctrl + Print               Flameshot GUI

    🎵 MEDIA CONTROLS
    ─────────────────────────────────────────
    Alt + 4                    Previous Track
    Alt + 5                    Play/Pause
    Alt + 6                    Next Track
    Alt + 1                    Rewind 2s
    Alt + 3                    Forward 2s
    Alt + 7                    Volume Down
    Alt + 9                    Volume Up
    XF86 Media Keys            Also Supported

    💡 HINTS
    ─────────────────────────────────────────
    • Hyprspace (Super) shows all workspaces
    • Vicinae is faster for app launching
    • Noctalia provides system integration
    • Use scratchpads for quick access
    • Yazelix is Helix-based modal editor
    "
      echo "$CHEATSHEET" | ${pkgs.rofi}/bin/rofi -dmenu \
        -p "Hyprland Keybinds" \
        -theme-str 'window {width: 55%; height: 90%;}' \
        -theme-str 'listview {columns: 1;}' \
        -theme-str 'element-text {font: "monospace 9";}'
  '';

  # hypr-keybind-cheatsheet = pkgs.writeShellScriptBin "hypr-keybind-cheatsheet" ''
  #   #!/usr/bin/env bash
  #   CHEATSHEET="
  #   Mod + Enter      | Open Terminal (Kitty)
  #   Mod + Q          | Close Active Window
  #   Mod + Space      | Toggle Vicinae Search
  #   Mod + A          | Toggle App Launcher
  #   Mod + X          | Toggle Control Center
  #   Mod + Tab        | Toggle Hyprspace Overview
  #   Mod + Shift + P  | Random Theme Switch
  #   Mod + H/J/K/L    | Focus Left/Down/Up/Right
  #   Mod + Shift + H/L| Move Window Left/Right
  #   Mod + Ctrl + Enter/Bksp | Add/Remove Column
  #   "
  #   ${pkgs.libnotify}/bin/notify-send -t 10000 -u low -i preferences-desktop-keyboard "Hyprland Keybinds" "$CHEATSHEET"
  # '';

  # ── Scrolling Layout Resize / Cycle ──────────────────────────────
  #hypr-scrolling-resize = pkgs.writeShellScriptBin "hypr-scrolling-resize" ''
  #  #!/usr/bin/env bash
  #  # Toggles between 33%, 66%, and 100% width for the active window
  #  # Usage: hypr-scrolling-resize toggle

  #  MONITOR_WIDTH=$(hyprctl activeworkspace -j | ${pkgs.jq}/bin/jq -r '.monitorWidth')
  #  CURRENT_WIDTH=$(hyprctl activewindow -j | ${pkgs.jq}/bin/jq -r '.size[0]')

  #  # Calculate current percentage
  #  PCT=$(echo "scale=2; $CURRENT_WIDTH / $MONITOR_WIDTH" | ${pkgs.bc}/bin/bc -l)

  #  # Thresholds for cycle: 0.33 -> 0.5 -> 0.66
  #  if (( $(echo "$PCT < 0.4" | ${pkgs.bc}/bin/bc -l) )); then
  #    NEW_WIDTH=$(echo "$MONITOR_WIDTH * 0.5" | ${pkgs.bc}/bin/bc | cut -d. -f1)
  #  elif (( $(echo "$PCT < 0.6" | ${pkgs.bc}/bin/bc -l) )); then
  #    NEW_WIDTH=$(echo "$MONITOR_WIDTH * 0.66667" | ${pkgs.bc}/bin/bc | cut -d. -f1)
  #  else
  #    NEW_WIDTH=$(echo "$MONITOR_WIDTH * 0.33333" | ${pkgs.bc}/bin/bc | cut -d. -f1)
  #  fi

  #  # Apply resize
  #  hyprctl dispatch resizewindowpixel exact "$NEW_WIDTH" 100%,activewindow
  #'';

  # ── Window Pinning / Floating Toggle ──────────────────────────────
  hypr-window-pin = pkgs.writeShellScriptBin "hypr-window-pin" ''
    #!/usr/bin/env bash
    set -euo pipefail

    WIN_JSON=$(hyprctl activewindow -j 2>/dev/null || echo "{}")
    if [ "$WIN_JSON" = "{}" ] || [ -z "$WIN_JSON" ]; then
      exit 0
    fi

    ADDR=$(echo "$WIN_JSON" | ${pkgs.jq}/bin/jq -r '.address // empty')
    if [ -z "$ADDR" ] || [ "$ADDR" = "null" ]; then
      exit 0
    fi

    FLOATING=$(echo "$WIN_JSON" | ${pkgs.jq}/bin/jq -r '.floating')
    PINNED=$(echo "$WIN_JSON" | ${pkgs.jq}/bin/jq -r '.pinned')

    if [ "$FLOATING" = "false" ]; then
      hyprctl dispatch togglefloating "address:$ADDR"
      hyprctl dispatch pin "address:$ADDR"
      ${pkgs.libnotify}/bin/notify-send -t 1500 -u low -i pin "Window Pinning" "Window floated & pinned"
    elif [ "$FLOATING" = "true" ] && [ "$PINNED" = "false" ]; then
      hyprctl dispatch pin "address:$ADDR"
      ${pkgs.libnotify}/bin/notify-send -t 1500 -u low -i pin "Window Pinning" "Window pinned"
    elif [ "$PINNED" = "true" ]; then
      hyprctl dispatch pin "address:$ADDR"
      ${pkgs.libnotify}/bin/notify-send -t 1500 -u low -i pin "Window Pinning" "Window unpinned (remains floating)"
    fi
  '';

  # ── Layout-Aware Fractional Sizing Presets ───────────────────────
  hypr-fractional-resize = pkgs.writeShellScriptBin "hypr-fractional-resize" ''
    #!/usr/bin/env bash
    set -euo pipefail

    PRESET="''${1:-}"
    case "$PRESET" in
      1/3) RATIO="0.333333" ;;
      2/3) RATIO="0.666667" ;;
      1/2) RATIO="0.5" ;;
      *)
        echo "Usage: hypr-fractional-resize {1/3|2/3|1/2}" >&2
        exit 1
        ;;
    esac

    WIN_JSON=$(hyprctl activewindow -j 2>/dev/null || echo "{}")
    if [ "$WIN_JSON" = "{}" ] || [ -z "$WIN_JSON" ]; then
      exit 0
    fi

    ADDR=$(echo "$WIN_JSON" | ${pkgs.jq}/bin/jq -r '.address // empty')
    if [ -z "$ADDR" ] || [ "$ADDR" = "null" ]; then
      exit 0
    fi

    FLOATING=$(echo "$WIN_JSON" | ${pkgs.jq}/bin/jq -r '.floating')
    MONITOR_ID=$(echo "$WIN_JSON" | ${pkgs.jq}/bin/jq -r '.monitor')
    WIN_X=$(echo "$WIN_JSON" | ${pkgs.jq}/bin/jq -r '.at[0]')
    WIN_Y=$(echo "$WIN_JSON" | ${pkgs.jq}/bin/jq -r '.at[1]')
    WIN_H=$(echo "$WIN_JSON" | ${pkgs.jq}/bin/jq -r '.size[1]')

    WS_JSON=$(hyprctl activeworkspace -j 2>/dev/null || echo "{}")
    TILED_LAYOUT=$(echo "$WS_JSON" | ${pkgs.jq}/bin/jq -r '.tiledLayout // "dwindle"')

    MON_JSON=$(hyprctl monitors -j 2>/dev/null | ${pkgs.jq}/bin/jq -c ".[] | select(.id == $MONITOR_ID)" 2>/dev/null || echo "")
    if [ -z "$MON_JSON" ]; then
      MON_JSON=$(hyprctl monitors -j 2>/dev/null | ${pkgs.jq}/bin/jq -c '.[] | select(.focused == true)' 2>/dev/null || echo "")
    fi

    if [ -z "$MON_JSON" ]; then
      echo "hypr-fractional-resize: could not determine monitor properties" >&2
      exit 1
    fi

    MON_CALC=$(echo "$MON_JSON" | ${pkgs.jq}/bin/jq -r \
      '(.scale // 1.0) as $scale |
       (.width / $scale) as $lw |
       (.height / $scale) as $lh |
       ((.reserved[0] // 0) / $scale) as $rl |
       ((.reserved[1] // 0) / $scale) as $rt |
       ((.reserved[2] // 0) / $scale) as $rr |
       ((.reserved[3] // 0) / $scale) as $rb |
       ($lw - $rl - $rr | round) as $uw |
       ($lh - $rt - $rb | round) as $uh |
       (((.x // 0) + $rl) | round) as $xmin |
       (((.y // 0) + $rt) | round) as $ymin |
       "\($uw) \($uh) \($xmin) \($ymin)"')

    read -r USABLE_W USABLE_H USABLE_XMIN USABLE_YMIN <<< "$MON_CALC"

    if [ "$FLOATING" = "true" ]; then
      TARGET_W=$(echo "$USABLE_W $RATIO" | ${pkgs.jq}/bin/jq -r '(.[0] * .[1]) | round')
      USABLE_XMAX=$(( USABLE_XMIN + USABLE_W ))
      TARGET_XMAX=$(( WIN_X + TARGET_W ))

      NEW_X=$WIN_X
      if [ "$TARGET_XMAX" -gt "$USABLE_XMAX" ]; then
        NEW_X=$(( USABLE_XMAX - TARGET_W ))
      fi
      if [ "$NEW_X" -lt "$USABLE_XMIN" ]; then
        NEW_X=$USABLE_XMIN
      fi

      hyprctl dispatch resizewindowpixel exact "''${TARGET_W}" "''${WIN_H}",address:"''${ADDR}"
      hyprctl dispatch movewindowpixel exact "''${NEW_X}" "''${WIN_Y}",address:"''${ADDR}"
      ${pkgs.libnotify}/bin/notify-send -t 1500 -u low -i preferences-desktop-display "Window Sizing" "Floating window width set to $PRESET (''${TARGET_W}px)"
    else
      case "$TILED_LAYOUT" in
        master)
          hyprctl keyword master:mfact "$RATIO"
          ${pkgs.libnotify}/bin/notify-send -t 1500 -u low -i preferences-desktop-display "Master Layout Preset" "Master area fraction set to $PRESET"
          ;;
        dwindle)
          TARGET_W=$(echo "$USABLE_W $RATIO" | ${pkgs.jq}/bin/jq -r '(.[0] * .[1]) | round')
          hyprctl dispatch resizeactive exact "''${TARGET_W}" "''${WIN_H}"
          ${pkgs.libnotify}/bin/notify-send -t 1500 -u low -i preferences-desktop-display "Dwindle Layout Preset" "Split container width set to $PRESET (''${TARGET_W}px)"
          ;;
        monocle)
          ${pkgs.libnotify}/bin/notify-send -t 1500 -u low -i dialog-information "Monocle Layout" "Fractional sizing is not applicable to tiled windows"
          ;;
        scrolling)
          TARGET_W=$(echo "$USABLE_W $RATIO" | ${pkgs.jq}/bin/jq -r '(.[0] * .[1]) | round')
          hyprctl dispatch resizeactive exact "''${TARGET_W}" "''${WIN_H}"
          ${pkgs.libnotify}/bin/notify-send -t 1500 -u low -i preferences-desktop-display "Scrolling Layout Preset" "Column width set to $PRESET (''${TARGET_W}px)"
          ;;
        *)
          TARGET_W=$(echo "$USABLE_W $RATIO" | ${pkgs.jq}/bin/jq -r '(.[0] * .[1]) | round')
          hyprctl dispatch resizeactive exact "''${TARGET_W}" "''${WIN_H}"
          ;;
      esac
    fi
  '';

  # ── Runtime Active Workspace Layout Switcher ──────────────────────
  hypr-layout-cycle = pkgs.writeShellScriptBin "hypr-layout-cycle" ''
    #!/usr/bin/env bash
    set -euo pipefail

    FOCUSED_MON=$(hyprctl monitors -j 2>/dev/null | ${pkgs.jq}/bin/jq -c '.[] | select(.focused == true)' || echo "")
    SPECIAL_NAME=$(echo "$FOCUSED_MON" | ${pkgs.jq}/bin/jq -r '.specialWorkspace.name // empty')

    if [ -n "$SPECIAL_NAME" ] && [ "$SPECIAL_NAME" != "" ]; then
      WS_TARGET="$SPECIAL_NAME"
    else
      WS_TARGET=$(hyprctl activeworkspace -j 2>/dev/null | ${pkgs.jq}/bin/jq -r '.name // "1"')
    fi

    CURRENT_LAYOUT=$(hyprctl activeworkspace -j 2>/dev/null | ${pkgs.jq}/bin/jq -r '.tiledLayout // "dwindle"')

    SEQUENCE=("dwindle" "master" "monocle" "scrolling")
    NUM_SEQ=''${#SEQUENCE[@]}

    CURRENT_IDX=-1
    for i in "''${!SEQUENCE[@]}"; do
      if [ "''${SEQUENCE[$i]}" = "$CURRENT_LAYOUT" ]; then
        CURRENT_IDX=$i
        break
      fi
    done

    if [ "$CURRENT_IDX" -eq -1 ]; then
      CURRENT_IDX=0
    fi

    NEXT_LAYOUT=""
    for step in $(seq 1 $NUM_SEQ); do
      CAND_IDX=$(( (CURRENT_IDX + step) % NUM_SEQ ))
      CAND_LAYOUT="''${SEQUENCE[$CAND_IDX]}"

      hyprctl keyword workspace "''${WS_TARGET},layout:''${CAND_LAYOUT}" >/dev/null 2>&1 || true
      CHECK_LAYOUT=$(hyprctl activeworkspace -j 2>/dev/null | ${pkgs.jq}/bin/jq -r '.tiledLayout // ""')

      if [ "$CHECK_LAYOUT" = "$CAND_LAYOUT" ]; then
        NEXT_LAYOUT="$CAND_LAYOUT"
        break
      fi
    done

    if [ -n "$NEXT_LAYOUT" ]; then
      ${pkgs.libnotify}/bin/notify-send -t 2000 -u low -i preferences-desktop-workspaces "Workspace Layout" "Workspace $WS_TARGET: $NEXT_LAYOUT"
    else
      ${pkgs.libnotify}/bin/notify-send -t 2000 -u low -i dialog-warning "Workspace Layout" "Could not switch layout for workspace $WS_TARGET"
    fi
  '';
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [
      hypr-sfx
      hypr-sfx-toggle
      theme-switch
      hypr-keybind-cheatsheet
      hypr-window-pin
      hypr-fractional-resize
      hypr-layout-cycle
      #  hypr-scrolling-resize
    ];
  };
}
