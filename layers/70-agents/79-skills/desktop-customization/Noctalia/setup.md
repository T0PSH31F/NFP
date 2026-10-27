# Noctalia Setup & Compositor Layer Integration

This guide documents how to set up Noctalia Shell across Hyprland, Umbriel, and Niri, including critical layer rules, blur parameters, and UWSM management.

---

## 1. NixOS / NFP Integration

In Nix Flake Pirates (NFP), Noctalia Shell is packaged declaratively via:

```nix
layers.desktop.experience = "noctalia";
# Or specify default preselected compositor:
layers.desktop.noctalia.defaultCompositor = "hyprland"; # "niri" | "umbriel"
```

This automatically:
- Installs the Noctalia v5 package from `inputs.noctalia`.
- Fetches and links official & community plugins (`assistant-panel`, `ip-monitor`, `tailscale`, `workspace-overview`, `screen-toolkit`, `todo`, `model-usage`).
- Configures `programs.noctalia-greeter` on Greetd.
- Generates UWSM desktop entries for `noctalia-hyprland`, `noctalia-niri`, and `noctalia-umbriel`.

---

## 2. Hyprland Layer Rules & Styling

Under Hyprland, Noctalia components render as Wayland `layer-shell` surfaces. To ensure smooth blur, shadows, and instant responsiveness without unwanted window slide animations:

```ini
# ~/.config/hypr/experiences/noctalia.conf

$ipc = noctalia msg

# ── Blur & Layer Rules ──────────────────────────────────────────
layerrule = blur 1, match:namespace ^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd)$
layerrule = blur_popups 1, match:namespace ^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd)$
layerrule = no_anim 1, match:namespace ^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd)$
layerrule = ignore_alpha 0.1, match:namespace ^noctalia-(notification|dock|osd)$

# ── Lightsaber Shadow Aura ─────────────────────────────────────
decoration {
  shadow {
    enabled = true
    range = 50
    offset = 0 4
    render_power = 10
    color = $primary
    color_inactive = 0x00000000
  }
}

# ── Keybindings ────────────────────────────────────────────────
bind = $mod, comma, exec, $ipc settings-toggle
bind = $mod, A, exec, $ipc panel-toggle launcher
bind = $mod, X, exec, $ipc panel-toggle control-center
bind = $mod, Tab, exec, $ipc window-switcher
bind = $mod SHIFT, L, exec, $ipc session lock
bind = CTRL ALT, Delete, exec, $ipc panel-toggle session
bind = $mod SHIFT, N, exec, $ipc notification-dnd-toggle
```

---

## 3. UWSM Session Management

Always launch Noctalia within the UWSM environment. In `~/.config/uwsm/env`:

```bash
export XDG_CURRENT_DESKTOP=Hyprland # or Umbriel / niri
export XDG_SESSION_TYPE=wayland
export QT_QPA_PLATFORM="wayland;xcb"
export MOZ_ENABLE_WAYLAND=1
export ELECTRON_OZONE_PLATFORM_HINT=auto
```

When logging out or switching compositors at the greeter, UWSM automatically terminates all child slices (`app.slice`), ensuring the Noctalia daemon is restarted freshly without socket deadlocks.
