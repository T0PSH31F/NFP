# Caelestia Shell Desktop Environment

Caelestia Shell is a highly aesthetic desktop environment built on top of Quickshell and Hyprland, designed for advanced Linux "ricing" with a focus on visual customization.

## Features

- **Window Manager**: Hyprland (Wayland compositor)
- **Shell**: Quickshell-based widgets
- **Panel**: Single left-side panel with applets
- **Terminal**: Foot terminal emulator
- **Browser**: Zen browser (default)
- **Launcher**: Custom launcher with command support
- **Color Schemes**: Switchable light/dark modes

## Keybindings

### Core Shortcuts

| Keybind | Action |
|---------|--------|
| `Super` | Open launcher (with command support) |
| `Super + T` | Open terminal (Foot) |
| `Super + W` | Open browser (Zen) |
| `Ctrl Alt + Delete` | Open session menu |
| `Ctrl Super Alt + R` | Restart Caelestia shell |

### Workspace Management

| Keybind | Action |
|---------|--------|
| `Super + #` (0-9) | Switch to workspace # |
| `Super Alt + #` | Move active window to workspace # |

### Window Actions

| Keybind | Action |
|---------|--------|
| Standard Hyprland binds | Resize, move, tile windows |

## Unique Features

### Launcher Commands
Access via `Super` key:
- Switch between light/dark color schemes
- Change wallpapers
- Execute system commands
- Launch applications

### Visual Customization
- **Color Schemes**: Multiple variants available
- **Wallpaper Management**: Integrated wallpaper picker
- **Panel Applets**: Workspace switcher, system tray, widgets
- **Themes**: Coordinated Qt/GTK theming

### IPC Commands
Control shell via CLI:
```bash
caelestia shell mpris play    # Play/pause media
caelestia shell mpris next    # Next track
caelestia shell help          # List all IPC commands
```

## Configuration

- **Shell Config**: `~/.config/quickshell/caelestia/`
- **Hyprland Config**: `~/.config/hypr/`
- **Foot Terminal**: `~/.config/foot/` (font size, colors, etc.)
- **Color Schemes**: Managed through launcher
- **Wallpapers**: Set via launcher or on first boot

## Scripts

IPC commands provide shell control:
- Media playback control
- Color scheme switching
- Wallpaper cycling
- Shell restart/reload

## Starting the Shell

```bash
# Start with default config
caelestia shell -d

# Or via Quickshell
qs -c caelestia
```

## Tips

1. Use `Super` launcher for quick theme/color changes
2. Wallpaper changes automatically adjust shell colors
3. Terminal font size: Edit `~/.config/foot/foot.ini`
4. Missing wallpaper? Launcher will prompt selection
5. CLI tools (`eza`, `lsd`) are available in Foot terminal
6. Restart shell with `Ctrl Super Alt + R` after config changes

## Integration with Grandlix-Gang

- Installed as Home Manager module
- Automatically started via Hyprland `exec-once`
- Integrated with NixOS configuration
- CLI available system-wide

## Advanced Customization

### Color Schemes
Switch via launcher or edit configuration files in:
- `~/.config/quickshell/caelestia/`

### Panel Customization
Widget configuration in Quickshell configs:
- Workspace switcher behavior
- System tray appearance
- Applet placement

### Autostart
Managed by Hyprland's `exec-once`:
```nix
# Already configured in module
```

## Troubleshooting

- **Shell not starting**: Run `caelestia shell -d` manually
- **Colors wrong**: Use launcher to reset color scheme
- **Wallpaper missing**: Select via launcher prompt
- **Terminal font**: Edit `~/.config/foot/foot.ini`
