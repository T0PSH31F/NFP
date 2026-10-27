# Umbriel Configuration Guide (`umbriel.conf`)

Umbriel reads its configuration from:
`~/.config/umbriel/umbriel.conf`

---

## 1. Minimal Working Configuration

```ini
# General Settings
general {
  gaps_in = 6
  gaps_out = 12
  border_size = 2
  col.active_border = rgba(82aaffff) rgba(c792eaff) 45deg
  col.inactive_border = rgba(1e222aff)
  layout = scrolling
}

# Decoration & Effects
decoration {
  rounding = 10
  
  blur {
    enabled = true
    size = 8
    passes = 3
    new_optimizations = true
  }

  shadow {
    enabled = true
    range = 30
    render_power = 4
    color = rgba(00000066)
  }
}

# Animations
animations {
  enabled = true
  bezier = fluid, 0.05, 0.9, 0.1, 1.05
  animation = windows, 1, 5, fluid
  animation = border, 1, 10, default
  animation = fade, 1, 7, default
  animation = workspaces, 1, 6, fluid, slide
}

# Keybindings
$mod = SUPER
$ipc = noctalia msg

bind = $mod, Return, exec, ghostty
bind = $mod, Q, killactive
bind = $mod, M, exit
bind = $mod, E, exec, nemo
bind = $mod, V, togglefloating
bind = $mod, F, fullscreen

# Noctalia Shell Integration
bind = $mod, A, exec, $ipc panel-toggle launcher
bind = $mod, X, exec, $ipc panel-toggle control-center
bind = $mod, Tab, exec, $ipc window-switcher
bind = CTRL ALT, Delete, exec, $ipc panel-toggle session
bind = $mod, comma, exec, $ipc settings-toggle

# Window Navigation (Scrolling layout)
bind = $mod, left, movefocus, l
bind = $mod, right, movefocus, r
bind = $mod, up, movefocus, u
bind = $mod, down, movefocus, d
```
