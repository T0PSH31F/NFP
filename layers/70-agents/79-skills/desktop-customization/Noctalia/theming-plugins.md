# Noctalia Theming, Plugins & Color Synchronization

Noctalia Shell v5 supports live theming, dynamic wallpaper palette extraction, and an isolated Luau plugin ecosystem.

---

## 1. Dynamic Wallpaper Theming

When a wallpaper is set via Noctalia IPC:
```bash
noctalia msg wallpaper-set "/path/to/wallpaper.png"
```

Noctalia extracts dominant and accent colors into:
`~/.config/hypr/noctalia/noctalia-colors.conf`

Format generated:
```ini
$background = rgba(101216ff)
$foreground = rgba(e6e8ecff)
$primary = rgba(82aaffff)
$secondary = rgba(c792eaff)
$accent = rgba(ff5370ff)
$surface = rgba(1e222aff)
```

Other applications can source this file directly:
- **Hyprland**: `source = ~/.config/hypr/noctalia/noctalia-colors.conf`
- **Rofi**: In `~/.config/rofi/colors.rasi`, dynamically imported.
- **Qutebrowser / Spicetify / WezTerm**: Synchronized via `noctalia-spicetify-sync` and theme reloaders.

---

## 2. Luau Plugin Architecture

Plugins are installed in `~/.config/noctalia/plugins/<plugin-name>/`:

```
~/.config/noctalia/plugins/
├── assistant-panel/       # AI / LLM chat interface integration
├── ip-monitor/            # Network & VPN interface telemetry
├── tailscale/             # Tailnet node status & quick switch
├── workspace-overview/    # Interactive visual workspace map
├── screen-toolkit/        # Screenshot, OCR, color picker tools
├── todo/                  # Fast local task list
└── model-usage/           # Live router & token metrics
```

### Plugin IPC & Dispatch:
Send events to plugins live:
```bash
# Event format:
noctalia msg plugin <author/plugin:entry> <target> <event> [payload]

# Example: trigger action in assistant-panel
noctalia msg plugin official/assistant-panel:main focused open-prompt "Summarize screen"

# Plugin lifecycle commands:
noctalia msg plugins list
noctalia msg plugins enable <plugin-id>
noctalia msg plugins disable <plugin-id>
```
