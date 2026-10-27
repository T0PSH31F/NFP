# Noctalia Shell v5 — AI Desktop Design & Ricing Guide

> Official Docs: [https://docs.noctalia.dev/](https://docs.noctalia.dev/)  
> Upstream Repository: [github.com/noctalia-dev/noctalia](https://github.com/noctalia-dev/noctalia)

Noctalia is a modern, modular Wayland desktop shell engineered for Hyprland, Niri, Umbriel, and Sway. It replaces traditional ad-hoc bars, notification daemons, docks, application launchers, and control centers with a single unified, hardware-accelerated, IPC-driven substrate.

---

## Architecture Overview

```
                                 ┌─────────────────────────┐
                                 │     Noctalia Shell      │
                                 │ (Bars, Docks, Launcher, │
                                 │  OSD, Control Center)   │
                                 └────────────┬────────────┘
                                              │
                      ┌───────────────────────┼───────────────────────┐
                      │ IPC ("noctalia msg")  │ Luau Plugin Engine    │
                      ▼                       ▼                       ▼
            ┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐
            │     Hyprland     │    │     Umbriel      │    │       Niri       │
            │  (Tiling/Dwindle)│    │(Fluid Compositor)│    │(Scrolling Tiles) │
            └──────────────────┘    └──────────────────┘    └──────────────────┘
```

1. **Unified State & Daemon**: Runs as a daemon (`noctalia`) managing:
   - Status Bars (`noctalia-bar-*`)
   - Floating Action / Control Center (`control-center`)
   - Application Launcher (`launcher`)
   - On-Screen Display (`osd` for volume, brightness, mic)
   - Workspace Switcher & Overview (`window-switcher`, `workspace-overview`)
   - Notification Center (`notification`, `notification-history`)
   - Power & Session Menu (`session`)

2. **IPC-Driven**: All components are addressable via the Unix socket client:
   ```bash
   noctalia msg <command> [args...]
   ```

3. **Multi-Compositor Support**:
   - **Hyprland**: Native layer-shell integration with blur, lightsaber shadow aura, and submap binding.
   - **Umbriel**: Direct integration through the `umbriel-companion` plugin and Unix socket events.
   - **Niri**: Native scrolling workspace sync, window switching, and portal integration.

---

## Directory & File Structure

```
~/.config/noctalia/
├── noctalia.toml          # Primary shell configuration (geometry, modules, behavior)
├── noctalia.json          # Alternative/generated JSON configuration
├── plugins/               # Active Luau plugins (community & official)
├── themes/                # Custom CSS and styling overrides
└── colors/                # Dynamic color palette definitions
```

---

## Key IPC Commands for Ricing

| Command | Action | Recommended Keybind |
|---|---|---|
| `noctalia msg panel-toggle launcher` | Toggle application launcher | `Super + A` / `Super + Space` |
| `noctalia msg panel-toggle control-center` | Toggle quick settings / control center | `Super + X` |
| `noctalia msg panel-toggle session` | Toggle power / logout / lock menu | `Ctrl + Alt + Delete` |
| `noctalia msg window-switcher` | Toggle interactive window switcher | `Alt + Tab` / `Super + Tab` |
| `noctalia msg settings-toggle` | Open live Noctalia settings UI | `Super + Comma` |
| `noctalia msg notification-dnd-toggle`| Toggle Do-Not-Disturb mode | `Super + Shift + N` |
| `noctalia msg volume-up` | Increment audio output volume | `XF86AudioRaiseVolume` |
| `noctalia msg volume-down` | Decrement audio output volume | `XF86AudioLowerVolume` |
| `noctalia msg brightness-up` | Increment display backlight | `XF86MonBrightnessUp` |
| `noctalia msg brightness-down` | Decrement display backlight | `XF86MonBrightnessDown` |
| `noctalia msg media toggle` | Play / pause media player | `XF86AudioPlay` |
| `noctalia msg wallpaper-set <path>` | Live update wallpaper & palette sync | Automatic / script hook |
