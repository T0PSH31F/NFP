# Umbriel Compositor Module
# Provides: layers.desktop.compositors.umbriel.enable
#
# Umbriel is an independent Wayland compositor with:
#   scrolling, dwindle + master layouts, blur, shadows, fluid animations.
#
# Source: github:noctalia-dev/umbriel
# Cache:  noctalia.cachix.org (already in nixConfig)
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.layers.desktop.compositors.umbriel;
  umbrielPkgs = inputs.umbriel.packages.${pkgs.stdenv.hostPlatform.system} or { };
  umbrielPkg =
    umbrielPkgs.default or (throw "umbriel: no default package for ${pkgs.stdenv.hostPlatform.system}");

  presets = rec {
    kzzzt = {
      name = "kzzzt";
      description = "Glitch CRT & Circuit Traces (kzzzt-open, kzzzt-close, kzzzt-ring, kzzzt window & glitch phase)";
      effects = ''
        [effects]
        border = "kzzzt-ring"
        window = "kzzzt"
        cursor = "cursor.comet"
        screen = "vignette"
        max_fps = 120

        [animation]
        enabled = true

        [animation.workspaces]
        enabled = true
        style = "reveal"
        effect = "workspace-glitch-phase"
        duration_ms = 1000
        curve = "linear"

        [animation.windows_in]
        enabled = true
        effect = "kzzzt-open"
        duration_ms = 900
        curve = "linear"

        [animation.windows_out]
        enabled = true
        effect = "kzzzt-close"
        duration_ms = 700
        curve = "linear"

        [animation.windows_move]
        enabled = true
        effect = "wobbly-move"
        curve = "easeout"
        duration_ms = 650
      '';
    };

    psychedelic = {
      name = "psychedelic";
      description = "Psychedelic Fractal Flow & Veil (Fractal Bloom & Iris)";
      effects = ''
        [effects]
        border = "psychedelic.fractal-flow"
        window = "psychedelic.fractal-veil"
        cursor = "cursor.rainbow-tunnel"
        screen = "vignette"
        max_fps = 120

        [animation]
        enabled = true

        [animation.workspaces]
        enabled = true
        style = "reveal"
        effect = "psychedelic.fractal-iris"
        duration_ms = 1100
        curve = "linear"

        [animation.windows_in]
        enabled = true
        effect = "psychedelic.fractal-bloom"
        duration_ms = 700
        curve = "linear"

        [animation.windows_out]
        enabled = true
        effect = "psychedelic.fractal-bloom"
        duration_ms = 450
        curve = "linear"

        [animation.windows_move]
        enabled = true
        effect = "wobbly-move"
        curve = "easeout"
        duration_ms = 650
      '';
    };

    after-dark = {
      name = "after-dark";
      description = "Halloween After Dark (somethings-watching, witchfire, midnight-fog, witching-hour)";
      effects = ''
        [effects]
        border = "after-dark.somethings-watching"
        window = "after-dark.somethings-watching-overlay"
        cursor = "after-dark.witchfire"
        screen = "after-dark.midnight-fog"
        max_fps = 120

        [animation]
        enabled = true

        [animation.workspaces]
        enabled = true
        style = "reveal"
        effect = "workspace-dust-cloud"
        duration_ms = 1000
        curve = "linear"

        [animation.windows_in]
        enabled = true
        effect = "witching-hour"
        duration_ms = 800
        curve = "linear"

        [animation.windows_out]
        enabled = true
        effect = "ghostly-tear"
        duration_ms = 600
        curve = "linear"

        [animation.windows_move]
        enabled = true
        effect = "wobbly-move"
        curve = "easeout"
        duration_ms = 650
      '';
    };

    flame-lava = {
      name = "flame-lava";
      description = "Molten Lava & Fire (portal-lava, fire-tendrils, flame-grilled, workspace-burn)";
      effects = ''
        [effects]
        border = "portal-lava"
        window = "window.fire-tendrils"
        cursor = "after-dark.witchfire"
        screen = "vignette"
        max_fps = 120

        [animation]
        enabled = true

        [animation.workspaces]
        enabled = true
        style = "reveal"
        effect = "workspace-burn"
        duration_ms = 1000
        curve = "linear"

        [animation.windows_in]
        enabled = true
        effect = "flame-grilled"
        duration_ms = 750
        curve = "linear"

        [animation.windows_out]
        enabled = true
        effect = "heat-melt-close"
        duration_ms = 600
        curve = "linear"

        [animation.windows_move]
        enabled = true
        effect = "wobbly-move"
        curve = "easeout"
        duration_ms = 650
      '';
    };

    beach-surf = {
      name = "beach-surf";
      description = "Coastal Surf & Oceanic Foam (beach-surf, beach-surf-overlay, water-splash, pond-wake)";
      effects = ''
        [effects]
        border = "beach-surf"
        window = "beach-surf-overlay"
        cursor = "cursor.pond-wake"
        screen = "vignette"
        max_fps = 120

        [animation]
        enabled = true

        [animation.workspaces]
        enabled = true
        style = "reveal"
        effect = "workspace-noctalia-wave"
        duration_ms = 1000
        curve = "linear"

        [animation.windows_in]
        enabled = true
        effect = "beach-surf-animation"
        duration_ms = 700
        curve = "linear"

        [animation.windows_out]
        enabled = true
        effect = "water-splash"
        duration_ms = 600
        curve = "linear"

        [animation.windows_move]
        enabled = true
        effect = "wobbly-move"
        curve = "easeout"
        duration_ms = 650
      '';
    };

    paper-craft = {
      name = "paper-craft";
      description = "Origami & Stationery Paper (paper border, paper-content, paper-animation, sand-collapse)";
      effects = ''
        [effects]
        border = "paper"
        window = "paper-content"
        cursor = "cursor-sparkle"
        screen = "vignette"
        max_fps = 120

        [animation]
        enabled = true

        [animation.workspaces]
        enabled = true
        style = "reveal"
        effect = "workspace-sand-collapse"
        duration_ms = 1000
        curve = "linear"

        [animation.windows_in]
        enabled = true
        effect = "paper-animation"
        duration_ms = 750
        curve = "linear"

        [animation.windows_out]
        enabled = true
        effect = "paper-animation"
        duration_ms = 600
        curve = "linear"

        [animation.windows_move]
        enabled = true
        effect = "wobbly-move"
        curve = "easeout"
        duration_ms = 650
      '';
    };

    rainbow-neon = {
      name = "rainbow-neon";
      description = "Rainbow Border & RGB Shimmer (rainbow border, rgb-shimmer, rainbow-tunnel, plasma-flow)";
      effects = ''
        [effects]
        border = "rainbow"
        window = "window.rgb-shimmer"
        cursor = "cursor.rainbow-tunnel"
        screen = "vignette"
        max_fps = 120

        [animation]
        enabled = true

        [animation.workspaces]
        enabled = true
        style = "reveal"
        effect = "workspace-noctalia-wave"
        duration_ms = 1000
        curve = "linear"

        [animation.windows_in]
        enabled = true
        effect = "plasma-flow-open"
        duration_ms = 700
        curve = "linear"

        [animation.windows_out]
        enabled = true
        effect = "plasma-flow-close"
        duration_ms = 500
        curve = "linear"

        [animation.windows_move]
        enabled = true
        effect = "wobbly-move"
        curve = "easeout"
        duration_ms = 650
      '';
    };

    rainbow-smoke = {
      name = "rainbow-smoke";
      description = "Audio-Reactive Rainbow Smoke (spectrum border, rainbow-smoke, music-radiance, smoke-open/close)";
      effects = ''
        [effects]
        border = "spectrum"
        window = "window.rainbow-smoke"
        cursor = "cursor.music-radiance"
        screen = "vignette"
        max_fps = 120

        [animation]
        enabled = true

        [animation.workspaces]
        enabled = true
        style = "reveal"
        effect = "workspace-noctalia-wave"
        duration_ms = 1000
        curve = "linear"

        [animation.windows_in]
        enabled = true
        effect = "smoke-open"
        duration_ms = 800
        curve = "linear"

        [animation.windows_out]
        enabled = true
        effect = "smoke-close"
        duration_ms = 600
        curve = "linear"

        [animation.windows_move]
        enabled = true
        effect = "wobbly-move"
        curve = "easeout"
        duration_ms = 650
      '';
    };

    sentient-matrix = {
      name = "sentient-matrix";
      description = "Sentient AI Motherboard (sentient-runner, sentient-circuit-v2, glitch-open/close, transporter)";
      effects = ''
        [effects]
        border = "sentient-runner"
        window = "window.sentient-circuit-v2"
        cursor = "glow"
        screen = "vignette"
        max_fps = 120

        [animation]
        enabled = true

        [animation.workspaces]
        enabled = true
        style = "reveal"
        effect = "workspace-transporter"
        duration_ms = 1000
        curve = "linear"

        [animation.windows_in]
        enabled = true
        effect = "glitch-open"
        duration_ms = 800
        curve = "linear"

        [animation.windows_out]
        enabled = true
        effect = "glitch-close"
        duration_ms = 600
        curve = "linear"

        [animation.windows_move]
        enabled = true
        effect = "wobbly-move"
        curve = "easeout"
        duration_ms = 650
      '';
    };

    lightning-shatter = {
      name = "lightning-shatter";
      description = "Lightning & Kinetic Shatter (lightning border, liquid-glass, shockwave, shattered-glass, workspace-shatter)";
      effects = ''
        [effects]
        border = "lightning"
        window = "window.liquid-glass"
        cursor = "cursor.shockwave"
        screen = "vignette"
        max_fps = 120

        [animation]
        enabled = true

        [animation.workspaces]
        enabled = true
        style = "reveal"
        effect = "workspace-shatter"
        duration_ms = 900
        curve = "linear"

        [animation.windows_in]
        enabled = true
        effect = "shattered-glass"
        duration_ms = 750
        curve = "linear"

        [animation.windows_out]
        enabled = true
        effect = "voronoi-shatter-close"
        duration_ms = 600
        curve = "linear"

        [animation.windows_move]
        enabled = true
        effect = "wobbly-move"
        curve = "easeout"
        duration_ms = 650
      '';
    };

    vampire-blood = {
      name = "vampire-blood";
      description = "Gothic Blood & Vampire Wake (heartbeat border, parchment-dark, blood-drip-in/out, midnight-fog)";
      effects = ''
        [effects]
        border = "heartbeat"
        window = "window.parchment-dark"
        cursor = "vampire-wake"
        screen = "after-dark.midnight-fog"
        max_fps = 120

        [animation]
        enabled = true

        [animation.workspaces]
        enabled = true
        style = "reveal"
        effect = "workspace-dust-cloud"
        duration_ms = 1000
        curve = "linear"

        [animation.windows_in]
        enabled = true
        effect = "blood-drip-in"
        duration_ms = 800
        curve = "linear"

        [animation.windows_out]
        enabled = true
        effect = "blood-drain-out"
        duration_ms = 600
        curve = "linear"

        [animation.windows_move]
        enabled = true
        effect = "wobbly-move"
        curve = "easeout"
        duration_ms = 650
      '';
    };

    diwali-festival = {
      name = "diwali-festival";
      description = "Diwali Festival of Lights (diya-lights, diya-glow-overlay, festival-sparks, rangoli-iris)";
      effects = ''
        [effects]
        border = "diwali.diya-lights"
        window = "diwali.diya-glow-overlay"
        cursor = "diwali.festival-sparks"
        screen = "vignette"
        max_fps = 120

        [animation]
        enabled = true

        [animation.workspaces]
        enabled = true
        style = "reveal"
        effect = "diwali.rangoli-iris"
        duration_ms = 1100
        curve = "linear"

        [animation.windows_in]
        enabled = true
        effect = "diwali.cloud-puff"
        duration_ms = 700
        curve = "linear"

        [animation.windows_out]
        enabled = true
        effect = "diwali.cloud-puff"
        duration_ms = 500
        curve = "linear"

        [animation.windows_move]
        enabled = true
        effect = "wobbly-move"
        curve = "easeout"
        duration_ms = 650
      '';
    };

    flowering-vine = {
      name = "flowering-vine";
      description = "Botanical Flowering Vine (flowering-vine, flowering-vine-overlay, fairy-tail cursor, iris reveal)";
      effects = ''
        [effects]
        border = "flowering-vine"
        window = "flowering-vine-overlay"
        cursor = "cursor.fairy-tail"
        screen = "vignette"
        max_fps = 120

        [animation]
        enabled = true

        [animation.workspaces]
        enabled = true
        style = "reveal"
        effect = "workspace-iris"
        duration_ms = 1000
        curve = "linear"

        [animation.windows_in]
        enabled = true
        effect = "ripple-open"
        duration_ms = 700
        curve = "linear"

        [animation.windows_out]
        enabled = true
        effect = "ripple-close"
        duration_ms = 500
        curve = "linear"

        [animation.windows_move]
        enabled = true
        effect = "wobbly-move"
        curve = "easeout"
        duration_ms = 650
      '';
    };

    ghostly-tear = {
      name = "ghostly-tear";
      description = "Spectral Ghostly Tear (dual-orbit border, mercury-sheen, ghost-thread, ghostly-tear in/out)";
      effects = ''
        [effects]
        border = "dual-orbit"
        window = "window.mercury-sheen"
        cursor = "ghost-thread"
        screen = "after-dark.midnight-fog"
        max_fps = 120

        [animation]
        enabled = true

        [animation.workspaces]
        enabled = true
        style = "reveal"
        effect = "workspace-iris"
        duration_ms = 1000
        curve = "linear"

        [animation.windows_in]
        enabled = true
        effect = "ghostly-tear"
        duration_ms = 850
        curve = "linear"

        [animation.windows_out]
        enabled = true
        effect = "ghostly-tear"
        duration_ms = 650
        curve = "linear"

        [animation.windows_move]
        enabled = true
        effect = "wobbly-move"
        curve = "easeout"
        duration_ms = 650
      '';
    };

    cyberpunk-crt = {
      name = "cyberpunk-crt";
      description = "Retro Arcade CRT (window.crt, neon-bleed, old-tv/tv-glitch, workspace-crt-scanline)";
      effects = ''
        [effects]
        border = "neon-bleed"
        window = "window.crt"
        cursor = "cursor.rainbow-tunnel-bare"
        screen = "vignette"
        max_fps = 120

        [animation]
        enabled = true

        [animation.workspaces]
        enabled = true
        style = "reveal"
        effect = "workspace-crt-scanline"
        duration_ms = 900
        curve = "linear"

        [animation.windows_in]
        enabled = true
        effect = "old-tv"
        duration_ms = 700
        curve = "linear"

        [animation.windows_out]
        enabled = true
        effect = "tv-glitch"
        duration_ms = 450
        curve = "linear"

        [animation.windows_move]
        enabled = true
        effect = "wobbly-move"
        curve = "easeout"
        duration_ms = 650
      '';
    };

    minimal-glass = {
      name = "minimal-glass";
      description = "Pure Frosted Glass Blur (accent-pulse border, clean windows, reveal/fade-close, workspace-wipe)";
      effects = ''
        [effects]
        border = "accent-pulse"
        cursor = "cursor-ring"
        screen = "vignette"
        max_fps = 120

        [animation]
        enabled = true

        [animation.workspaces]
        enabled = true
        style = "reveal"
        effect = "workspace-wipe"
        duration_ms = 700
        curve = "linear"

        [animation.windows_in]
        enabled = true
        effect = "reveal"
        duration_ms = 500
        curve = "linear"

        [animation.windows_out]
        enabled = true
        effect = "fade-close"
        duration_ms = 400
        curve = "linear"

        [animation.windows_move]
        enabled = true
        effect = "wobbly-move"
        curve = "easeout"
        duration_ms = 650
      '';
    };

    # Aliases preserving original preset names alongside canonical family names
    matrix-sentient = sentient-matrix;
    glass-shatter = lightning-shatter;
    ocean-waves = beach-surf;
    gothic-blood = vampire-blood;
  };

  mkConfigFile =
    { includePath, presetEffects }:
    ''
      # ==============================================================================
      # General
      # ==============================================================================
      [general]
      autostart = ["noctalia"]
      xwayland = true

      # ==============================================================================
      # Includes — Shaders & Effect Presets
      # ==============================================================================
      # Includes all 189+ curated GLSL shader effect presets from:
      # • Community Shaders: https://github.com/noctalia-dev/community-umbriel-shaders
      # • Prometheaus Shaders: https://github.com/prometheaus/umbriel-shaders
      [include]
      files = [
        "${includePath}"
      ]

      ${presetEffects}

      # ==============================================================================
      # Appearance & Frosted Glass Blur (macOS Vibrancy & Brilliance)
      # ==============================================================================
      [appearance]
      border_width = 5
      corner_radius = 14
      drag_opacity = 0.85

      [appearance.blur]
      enabled = true
      radius = 8
      passes = 4
      brightness = 1.05
      contrast = 0.98
      saturation = 1.25
      noise = 0.015

      [animation.windows_drag]
      physics = true

      [animation.dim_unfocused]
      enabled = true
      dim = 0.12
      duration_ms = 250
      curve = "ease-out"

      [animation.scratchpad]
      enabled = true
      effect = "panel-scroll"
      dim = 0.0
      blur = false
      duration_ms = 280
      curve = "easeout"

      # ==============================================================================
      # Input
      # ==============================================================================
      [input.keyboard]
      numlock_toggle = true

      [input.focus]
      follows_mouse = true

      [input.cursor]
      size = 24
      hardware_cursor = false

      # ==============================================================================
      # Keybinds
      # ==============================================================================
      [keybinds]
      "Mod+Return" = { action = "spawn:ghostty", repeat = false }
      "Mod" = { action = "overview-toggle", repeat = false }
      "Mod+Space" = "spawn:noctalia msg panel-toggle launcher"
      "Mod+A" = "spawn:noctalia msg panel-toggle launcher"
      "Mod+X" = "spawn:noctalia msg panel-toggle control-center"
      "Mod+N" = { action = "spawn:noctalia msg panel-toggle noctalia/notes:panel", repeat = false }
      "Mod+Shift+N" = { action = "spawn:noctalia msg panel-toggle noctalia/notes:panel", repeat = false }
      "Mod+period" = { action = "spawn:rofi-todo", repeat = false }
      "Mod+Shift+period" = { action = "spawn:rofi-todo --quick-add", repeat = false }
      "Mod+Comma" = "spawn:noctalia msg settings-toggle"
      "Mod+Shift+Comma" = { action = "spawn:umbriel-config gui", repeat = false }
      "Mod+Shift+G" = { action = "spawn:umbriel-theme next", repeat = false }
      "Mod+Alt+G" = { action = "spawn:umbriel-theme prev", repeat = false }
      "Mod+Tab" = "spawn:noctalia msg window-switcher"
      "Mod+Q" = { action = "window-close", repeat = false }
      "Mod+Escape" = "session-quit"
      "Mod+Shift+Escape" = { action = "shortcuts-inhibit-toggle", allow_when_inhibited = true, repeat = false }
      "Ctrl+Alt+Delete" = "spawn:noctalia msg panel-toggle session"

      # Window navigation & focus (Hyprland arrows + Vim keys)
      "Mod+Left" = "window-focus-left"
      "Mod+Down" = "window-focus-down"
      "Mod+Up" = "window-focus-up"
      "Mod+Right" = "window-focus-right"
      "Mod+H" = "window-focus-left"
      "Mod+J" = "window-focus-down"
      "Mod+K" = "window-focus-up"
      "Mod+L" = "window-focus-right"
      "Alt+Tab" = "window-focus-next"
      "Alt+Shift+Tab" = "window-focus-previous"

      # Window movement & swapping (Hyprland Shift + arrows / Vim keys)
      "Mod+Shift+Left" = "window-move-left"
      "Mod+Shift+Down" = "window-move-down"
      "Mod+Shift+Up" = "window-move-up"
      "Mod+Shift+Right" = "window-move-right"
      "Mod+Shift+H" = "window-move-left"
      "Mod+Shift+J" = "window-move-down"
      "Mod+Shift+K" = "window-move-up"
      "Mod+Shift+L" = "window-move-right"

      # Voice Assistant & Window states
      "Mod+V" = { action = "spawn:/home/t0psh31f/.local/bin/glados-ptt", repeat = false }
      "Mod+Shift+V" = { action = "spawn:uwsm app -- ghostty -e /home/t0psh31f/.local/bin/glados-voice --tui", repeat = false }
      "Mod+Shift+F" = { action = "window-toggle-floating", repeat = false }

      # Screenshots (Region by default, Fullscreen with Shift, quick copy, annotate menu)
      "Print" = { action = "spawn:/home/t0psh31f/.local/bin/hypr-screenshot region", repeat = false }
      "Shift+Print" = { action = "spawn:/home/t0psh31f/.local/bin/hypr-screenshot full", repeat = false }
      "Ctrl+Print" = { action = "spawn:/home/t0psh31f/.local/bin/hypr-screenshot copy-region", repeat = false }
      "Ctrl+Shift+Print" = { action = "spawn:/home/t0psh31f/.local/bin/hypr-screenshot copy-full", repeat = false }
      "Mod+Print" = { action = "spawn:/home/t0psh31f/.local/bin/hypr-screenshot menu", repeat = false }
      "Mod+Ctrl+S" = { action = "spawn:/home/t0psh31f/.local/bin/hypr-screenshot region", repeat = false }
      "Mod+T" = { action = "scratchpad-toggle:terminal", repeat = false }
      "Mod+Y" = { action = "scratchpad-toggle:yazelix", repeat = false }
      "Mod+Shift+Y" = { action = "scratchpad-toggle:yazelix", repeat = false }
      "Mod+F" = { action = "window-toggle-fullscreen", repeat = false }
      "Mod+M" = { action = "window-toggle-maximize-to-edges", repeat = false }
      "Mod+O" = { action = "overview-toggle", repeat = false }
      "Mod+Ctrl+L" = "workspace-set-layout:toggle:scrolling,dwindle,master"

      # Extent resizing & tab groups
      "Mod+equal" = "window-modify-primary-extent:0.05"
      "Mod+minus" = "window-modify-primary-extent:-0.05"
      "Mod+Shift+equal" = "window-cycle-primary-extent"
      "Mod+Shift+minus" = "window-cycle-primary-extent-back"
      "Mod+Ctrl+equal" = "window-modify-secondary-extent:0.05"
      "Mod+Ctrl+minus" = "window-modify-secondary-extent:-0.05"
      "Mod+R" = "window-cycle-primary-extent"
      "Mod+Shift+R" = "window-cycle-primary-extent-back"
      "Mod+W" = "column-toggle-tabbed"

      # Scratchpad / Special Workspace
      "Mod+Shift+S" = "scratchpad-toggle:terminal"
      "Mod+Alt+S" = "window-move-to-scratchpad:terminal"

      # Workspaces 1-9
      "Mod+1" = "workspace-switch:1"
      "Mod+2" = "workspace-switch:2"
      "Mod+3" = "workspace-switch:3"
      "Mod+4" = "workspace-switch:4"
      "Mod+5" = "workspace-switch:5"
      "Mod+6" = "workspace-switch:6"
      "Mod+7" = "workspace-switch:7"
      "Mod+8" = "workspace-switch:8"
      "Mod+9" = "workspace-switch:9"

      # Move window to workspace
      "Mod+Shift+1" = "window-move-to-workspace:1"
      "Mod+Shift+2" = "window-move-to-workspace:2"
      "Mod+Shift+3" = "window-move-to-workspace:3"
      "Mod+Shift+4" = "window-move-to-workspace:4"
      "Mod+Shift+5" = "window-move-to-workspace:5"
      "Mod+Shift+6" = "window-move-to-workspace:6"
      "Mod+Shift+7" = "window-move-to-workspace:7"
      "Mod+Shift+8" = "window-move-to-workspace:8"
      "Mod+Shift+9" = "window-move-to-workspace:9"

      # Move window to workspace (silent)
      "Mod+Alt+1" = "window-move-to-workspace-silent:1"
      "Mod+Alt+2" = "window-move-to-workspace-silent:2"
      "Mod+Alt+3" = "window-move-to-workspace-silent:3"
      "Mod+Alt+4" = "window-move-to-workspace-silent:4"
      "Mod+Alt+5" = "window-move-to-workspace-silent:5"
      "Mod+Alt+6" = "window-move-to-workspace-silent:6"
      "Mod+Alt+7" = "window-move-to-workspace-silent:7"
      "Mod+Alt+8" = "window-move-to-workspace-silent:8"
      "Mod+Alt+9" = "window-move-to-workspace-silent:9"

      # Relative workspace navigation (bracket, page up/down, ctrl+arrows)
      "Mod+BracketRight" = "workspace-next"
      "Mod+BracketLeft" = "workspace-previous"
      "Mod+Ctrl+Right" = "workspace-next"
      "Mod+Ctrl+Left" = "workspace-previous"
      "Mod+Page_Down" = "workspace-next"
      "Mod+Page_Up" = "workspace-previous"

      "Mod+Shift+BracketRight" = "window-move-to-workspace-next"
      "Mod+Shift+BracketLeft" = "window-move-to-workspace-previous"
      "Mod+Shift+Page_Down" = "window-move-to-workspace-next"
      "Mod+Shift+Page_Up" = "window-move-to-workspace-previous"
      "Mod+Ctrl+Shift+Right" = "window-move-to-workspace-next"
      "Mod+Ctrl+Shift+Left" = "window-move-to-workspace-previous"

      # Mouse wheel workspace switching
      "Mod+WheelDown" = "workspace-next"
      "Mod+WheelUp" = "workspace-previous"
      "Mod+Shift+WheelDown" = "window-move-to-workspace-next"
      "Mod+Shift+WheelUp" = "window-move-to-workspace-previous"

      # Media & hardware keys
      "XF86AudioRaiseVolume" = { action = "spawn:noctalia msg volume-up", allow_when_locked = true }
      "XF86AudioLowerVolume" = { action = "spawn:noctalia msg volume-down", allow_when_locked = true }
      "XF86AudioMute" = { action = "spawn:noctalia msg volume-mute", allow_when_locked = true, repeat = false }
      "XF86AudioPlay" = { action = "spawn:noctalia msg media toggle", allow_when_locked = true, repeat = false }
      "XF86AudioNext" = { action = "spawn:noctalia msg media next", allow_when_locked = true }
      "XF86AudioPrev" = { action = "spawn:noctalia msg media previous", allow_when_locked = true }
      "XF86MonBrightnessUp" = { action = "spawn:noctalia msg brightness-up", allow_when_locked = true }
      "XF86MonBrightnessDown" = { action = "spawn:noctalia msg brightness-down", allow_when_locked = true }

      # ==============================================================================
      # Overview
      # ==============================================================================
      [overview]
      zoom = 0.5
      scroll_factor_horizontal = 1.0
      scroll_factor_vertical = 1.0
      background_blur = true
      workspace_wallpaper = true
      shortcuts = true
      shortcut_keys = "1234567890"

      # ==============================================================================
      # Layout
      # ==============================================================================
      [layout]
      extent_presets = [0.333, 0.5, 0.667, 1.0]

      [layout.scrolling]
      default_extent_fraction = 1.0

      # ==============================================================================
      # Scratchpads (Drop-Down Quake Terminal & Leftside Yazelix)
      # ==============================================================================
      [[scratchpad]]
      name = "terminal"
      spawn_when_empty = "ghostty --title='Dropdown Terminal'"

      [[scratchpad]]
      name = "yazelix"
      spawn_when_empty = "ghostty --title='Yazelix Workspace' -e yazelix-workspace"

      # ==============================================================================
      # Window Rules
      # ==============================================================================
      [[window_rule]]
      blur = true
      opacity = 0.94
      border_width = 5

      [[window_rule]]
      match.title = "^Dropdown Terminal$"
      default_scratchpad = "terminal"
      default_floating = true
      default_floating_size_px = { width = 1600, height = 560 }
      default_position = { anchor = "top", x = 0, y = -4 }
      border_effect = "off"
      window_effect = "off"
      border_width = 0
      corner_radius = 20
      opacity = 0.90
      blur = true

      [[window_rule]]
      match.title = "^Yazelix Workspace$"
      default_scratchpad = "yazelix"
      default_floating = true
      default_floating_size_px = { width = 860, height = 1026 }
      default_position = { anchor = "left", x = 0, y = 0 }
      border_effect = "off"
      window_effect = "off"
      border_width = 0
      corner_radius = 20
      opacity = 0.90
      blur = true

      [[window_rule]]
      match.app_id = "^dev.noctalia.Noctalia$"
      default_floating = true
      default_floating_size_px = { width = 1020, height = 900 }

      [[window_rule]]
      match.app_id = "^(opencode|oh-my-opencode|hermes|agy)$"
      default_workspace = "1"

      [[window_rule]]
      match.app_id = "^(zen.*|brave-browser|firefox|chromium|google-chrome)$"
      default_workspace = "2"

      [[window_rule]]
      match.app_id = "^(code|cursor|dev\\.zed\\.Zed|neovim)$"
      default_workspace = "3"

      [[window_rule]]
      match.app_id = "^(spotify|steam|mpv)$"
      default_workspace = "4"

      [[window_rule]]
      match.app_id = "^(thunar|org\\.gnome\\.Nautilus|dolphin|yazi)$"
      default_workspace = "5"

      [[window_rule]]
      match.app_id = "^(thunderbird|discord|vesktop|slack|signal)$"
      default_workspace = "6"

      [[window_rule]]
      match.app_id = "^(btop|bottom|tmog|grafana)$"
      default_workspace = "7"

      # ==============================================================================
      # Layer Rules
      # ==============================================================================
      [[layer_rule]]
      match.namespace = "^noctalia-(bar-[^\"]+|notification|dock|panel|attached-panel|osd|desktop-widget-[^\"]*)$"
      blur = true
      blur_ignore_alpha = 0.5
      blur_popups = true

      [[layer_rule]]
      match.namespace = "^noctalia-(notification|dock|panel|attached-panel|osd)$"
      blur_optimized = false

      # ==============================================================================
      # Outputs
      # ==============================================================================
      [output.HDMI-A-2]
      enabled = true
      scale = 1.0
      position = [0, 0]

      [output.eDP-1]
      enabled = true
      scale = 1.0
      position = [1920, 0]

      # ==============================================================================
      # EXTENSIONS & SHADERS REFERENCE (https://github.com/noctalia-dev/community-umbriel-shaders)
      # GUI Configurator: umbriel-config gui (Mod+Shift+,)
      # Portals: xdg-desktop-portal-umbriel (ScreenCast, Screenshot, InputCapture)
      # ==============================================================================

      ${cfg.extraConfig}
    '';

  umbrielThemeSwitcher = pkgs.writeShellScriptBin "umbriel-theme" ''
    set -euo pipefail

    PRESETS_DIR="''${HOME}/.config/umbriel/presets"
    ACTIVE_FLAG="''${HOME}/.config/umbriel/.active-preset"
    ORDER=(
      "kzzzt"
      "psychedelic"
      "after-dark"
      "flame-lava"
      "beach-surf"
      "paper-craft"
      "rainbow-neon"
      "rainbow-smoke"
      "sentient-matrix"
      "lightning-shatter"
      "vampire-blood"
      "diwali-festival"
      "flowering-vine"
      "ghostly-tear"
      "cyberpunk-crt"
      "minimal-glass"
    )

    show_help() {
      echo "Usage: umbriel-theme [preset|command]"
      echo ""
      echo "Available Presets in Gallery (16 Curated Themes):"
      echo "   1. kzzzt             - Glitch CRT & circuit traces (kzzzt-open, kzzzt-close, kzzzt-ring, kzzzt window)"
      echo "   2. psychedelic       - Fractal Flow & Veil (fractal-iris, fractal-bloom, fractal-flow)"
      echo "   3. after-dark        - Halloween After Dark (somethings-watching, witchfire, midnight-fog, witching-hour)"
      echo "   4. flame-lava        - Molten Lava & Fire (portal-lava, fire-tendrils, flame-grilled, workspace-burn)"
      echo "   5. beach-surf        - Coastal Surf & Oceanic Foam (beach-surf, beach-surf-overlay, water-splash, pond-wake)"
      echo "   6. paper-craft       - Origami & Stationery Paper (paper border, paper-content, paper-animation, sand-collapse)"
      echo "   7. rainbow-neon      - Rainbow Border & RGB Shimmer (rainbow border, rgb-shimmer, rainbow-tunnel, plasma-flow)"
      echo "   8. rainbow-smoke     - Audio-Reactive Rainbow Smoke (spectrum border, rainbow-smoke, music-radiance, smoke-open/close)"
      echo "   9. sentient-matrix   - Sentient AI Motherboard (sentient-runner, sentient-circuit-v2, glitch-open/close, transporter)"
      echo "  10. lightning-shatter  - Lightning & Kinetic Shatter (lightning border, liquid-glass, shockwave, shattered-glass)"
      echo "  11. vampire-blood     - Gothic Blood & Vampire Wake (heartbeat border, parchment-dark, blood-drip-in/out)"
      echo "  12. diwali-festival   - Diwali Festival of Lights (diya-lights, diya-glow-overlay, festival-sparks, rangoli-iris)"
      echo "  13. flowering-vine    - Botanical Flowering Vine (flowering-vine, flowering-vine-overlay, fairy-tail cursor)"
      echo "  14. ghostly-tear      - Spectral Ghostly Tear (dual-orbit border, mercury-sheen, ghost-thread, ghostly-tear)"
      echo "  15. cyberpunk-crt     - Retro Arcade CRT (window.crt, neon-bleed, old-tv/tv-glitch, workspace-crt-scanline)"
      echo "  16. minimal-glass     - Pure Frosted Glass Blur (accent-pulse border, clean windows, reveal/fade-close)"
      echo ""
      echo "Navigation Commands:"
      echo "  next / cycle          - Cycle forward to the next theme in the gallery (Mod+Shift+G)"
      echo "  prev                  - Cycle backward to the previous theme in the gallery (Mod+Alt+G)"
      echo "  toggle                - Fast toggle between kzzzt and psychedelic"
      echo "  status                - Show currently active preset"
      echo "  help / list           - Show this help message"
    }

    current_theme() {
      if [ -f "$ACTIVE_FLAG" ]; then
        cat "$ACTIVE_FLAG"
      else
        echo "unknown"
      fi
    }

    cycle_theme() {
      local dir="''${1:-next}"
      local curr
      curr="$(current_theme)"
      local total="''${#ORDER[@]}"
      local idx=-1

      for i in "''${!ORDER[@]}"; do
        if [ "''${ORDER[$i]}" = "$curr" ]; then
          idx=$i
          break
        fi
      done

      if [ $idx -lt 0 ]; then
        idx=0
      fi

      if [ "$dir" = "next" ]; then
        local next_idx=$(( (idx + 1) % total ))
      else
        local next_idx=$(( (idx - 1 + total) % total ))
      fi

      switch_theme "''${ORDER[$next_idx]}"
    }

    switch_theme() {
      local target="$1"
      local preset_file="$PRESETS_DIR/$target.toml"
      if [ ! -f "$preset_file" ]; then
        echo "Error: Preset '$target' not found in $PRESETS_DIR" >&2
        exit 1
      fi

      echo "Switching Umbriel shader theme to: $target..."
      ${cfg.package}/bin/umbriel config-replace "$preset_file"
      echo "$target" > "$ACTIVE_FLAG"

      if [ -x "/home/t0psh31f/.local/bin/glados-tts-cli" ]; then
        /home/t0psh31f/.local/bin/glados-tts-cli "Umbriel visual shader preset updated to $target." >/dev/null 2>&1 &
      fi

      if command -v ${pkgs.libnotify}/bin/notify-send >/dev/null 2>&1; then
        ${pkgs.libnotify}/bin/notify-send -a "Umbriel Compositor" "Theme Updated" "Active preset: $target" -i preferences-desktop-theme 2>/dev/null || true
      fi
      echo "Successfully applied $target preset."
    }

    case "''${1:-status}" in
      kzzzt|kkzzrrpp|glitch)
        switch_theme "kzzzt"
        ;;
      psychedelic|fractal)
        switch_theme "psychedelic"
        ;;
      after-dark|halloween|witch*)
        switch_theme "after-dark"
        ;;
      flame*|lava|fire)
        switch_theme "flame-lava"
        ;;
      beach*|surf|ocean|water|waves)
        switch_theme "beach-surf"
        ;;
      paper*|origami|stationery)
        switch_theme "paper-craft"
        ;;
      rainbow-neon|rainbow|neon|rgb-shimmer)
        switch_theme "rainbow-neon"
        ;;
      rainbow-smoke|smoke|music|audio)
        switch_theme "rainbow-smoke"
        ;;
      sentient*|matrix*|ai)
        switch_theme "sentient-matrix"
        ;;
      lightning*|shatter|shock*)
        switch_theme "lightning-shatter"
        ;;
      vampire*|blood|gothic*)
        switch_theme "vampire-blood"
        ;;
      diwali*|festival|lights)
        switch_theme "diwali-festival"
        ;;
      flowering*|vine*|nature|botanical)
        switch_theme "flowering-vine"
        ;;
      ghost*|ghostly*|spectral)
        switch_theme "ghostly-tear"
        ;;
      cyberpunk*|crt|arcade)
        switch_theme "cyberpunk-crt"
        ;;
      minimal*|glass|clean)
        switch_theme "minimal-glass"
        ;;
      next|cycle)
        cycle_theme "next"
        ;;
      prev)
        cycle_theme "prev"
        ;;
      toggle)
        curr="$(current_theme)"
        if [ "$curr" = "kzzzt" ]; then
          switch_theme "psychedelic"
        else
          switch_theme "kzzzt"
        fi
        ;;
      status)
        echo "Active preset: $(current_theme)"
        ${cfg.package}/bin/umbriel effects || true
        ;;
      help|--help|-h|list)
        show_help
        ;;
      *)
        if [ -f "$PRESETS_DIR/$1.toml" ]; then
          switch_theme "$1"
        else
          show_help
          exit 1
        fi
        ;;
    esac
  '';
in
{
  options.layers.desktop.compositors.umbriel = {
    enable = lib.mkEnableOption "Umbriel Wayland compositor";

    package = lib.mkOption {
      type = lib.types.package;
      default = umbrielPkg;
      description = "Umbriel compositor package";
    };

    themePreset = lib.mkOption {
      type = lib.types.enum (builtins.attrNames presets);
      default = "kzzzt";
      description = "Active Umbriel visual & shader theme preset";
    };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra Umbriel configuration (appended to ~/.config/umbriel/umbriel.conf)";
    };
  };

  config = lib.mkIf cfg.enable {
    # ── Environment configuration ──────────────────────────────────────
    environment = {
      etc = {
        "xdg/umbriel/config.toml".text = mkConfigFile {
          includePath = "shaders/all-shaders.toml";
          presetEffects = presets.${cfg.themePreset}.effects;
        };

        "xdg/uwsm/env-umbriel".text = ''
          export XDG_CURRENT_DESKTOP=Umbriel
          export XDG_SESSION_TYPE=wayland
          export XDG_SESSION_DESKTOP=Umbriel
          export WLR_NO_HARDWARE_CURSORS=1
          export WLR_DRM_DEVICES=/dev/dri/card1:/dev/dri/card0
        '';
      }
      // (lib.mapAttrs' (
        name: preset:
        lib.nameValuePair "xdg/umbriel/presets/${name}.toml" {
          text = mkConfigFile {
            includePath = "../shaders/all-shaders.toml";
            presetEffects = preset.effects;
          };
        }
      ) presets);

      # ── System packages ────────────────────────────────────────────────
      systemPackages = [
        cfg.package
        umbrielThemeSwitcher
        (pkgs.writeShellScriptBin "umbriel-switch-theme" ''exec ${umbrielThemeSwitcher}/bin/umbriel-theme "$@"'')
        (pkgs.writeTextFile {
          name = "umbriel-uwsm-wayland-session";
          destination = "/share/wayland-sessions/umbriel-uwsm.desktop";
          text = ''
            [Desktop Entry]
            Name=Umbriel (UWSM)
            Comment=Umbriel Wayland compositor managed by UWSM
            Exec=''${pkgs.uwsm}/bin/uwsm start -F -N "Umbriel" -D Umbriel -C "Umbriel Wayland compositor managed by UWSM" -- /run/current-system/sw/bin/umbriel
            Type=Application
            DesktopNames=Umbriel
          '';
        })
      ];
    };

    # ── XDG portal ─────────────────────────────────────────────────────
    xdg.portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-umbriel
        pkgs.xdg-desktop-portal-gtk
      ];
      config.umbriel = {
        default = [
          "umbriel"
          "gtk"
        ];
      };
    };

    # ── Session registration ───────────────────────────────────────────
    services.displayManager.sessionPackages = [
      (
        (pkgs.writeTextFile {
          name = "umbriel-uwsm-wayland-session";
          destination = "/share/wayland-sessions/umbriel-uwsm.desktop";
          passthru.providedSessions = [ "umbriel-uwsm" ];
          text = ''
            [Desktop Entry]
            Name=Umbriel (UWSM)
            Comment=Umbriel Wayland compositor managed by UWSM
            Exec=${pkgs.uwsm}/bin/uwsm start -F -N "Umbriel" -D Umbriel -C "Umbriel Wayland compositor managed by UWSM" -- /run/current-system/sw/bin/umbriel
            Type=Application
            DesktopNames=Umbriel
          '';
        })
        // {
          providedSessions = [ "umbriel-uwsm" ];
        }
      )
      (
        (pkgs.writeTextFile {
          name = "umbriel-wayland-session";
          destination = "/share/wayland-sessions/umbriel.desktop";
          passthru.providedSessions = [ "umbriel" ];
          text = ''
            [Desktop Entry]
            Name=Umbriel
            Comment=Umbriel Wayland Compositor (Native systemd)
            Exec=${cfg.package}/bin/start-umbriel
            Type=Application
            DesktopNames=Umbriel
          '';
        })
        // {
          providedSessions = [ "umbriel" ];
        }
      )
    ];

    # ── UWSM integration ───────────────────────────────────────────────
    programs.uwsm.enable = lib.mkDefault true;

    # ── Systemd service environment overrides (wlroots hybrid GPU fix) ───
    systemd.user.services.umbriel = {
      environment = {
        WLR_NO_HARDWARE_CURSORS = "1";
        WLR_DRM_DEVICES = "/dev/dri/card1:/dev/dri/card0";
      };
    };

    # ── Security (polkit, pam) ─────────────────────────────────────────
    security = {
      polkit.enable = true;
      pam.services.umbriel.enableGnomeKeyring = lib.mkDefault true;
    };
  };
}
