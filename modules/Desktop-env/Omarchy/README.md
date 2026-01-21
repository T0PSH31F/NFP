# Omarchy Desktop Environment

Omarchy is an opinionated NixOS desktop environment based on DHH's Omarchy project, utilizing Hyprland as its window manager with a focus on productivity and aesthetics.

## Features

- **Window Manager**: Hyprland (Wayland compositor)
- **Theme**: Tokyo Night (configurable)
- **Terminal**: Default configured terminal
- **Application Launcher**: Rofi
- **Status Bar**: Waybar-based components
- **Configuration**: `~/.config/hypr/bindings.conf` for custom keybinds

## Keybindings

### Essential Shortcuts

| Keybind | Action |
|---------|--------|
| `Super + K` | Display all keybindings, apps, and shortcuts |
| `Super + Enter` | Launch terminal |
| `Super + W` | Close active window/menu |
| `Super + Space` | Open application launcher (Rofi) |
| `Super + Alt + Space` | Open Omarchy Menu (system config) |
| `Super + Escape` | Power menu (lock/suspend/restart/shutdown) |

### Window Management

| Keybind | Action |
|---------|--------|
| `Super + J` | Toggle split layout |
| `Super + F` | Toggle fullscreen |
| `Super + Plus` | Increase window size |
| `Super + Minus` | Decrease window size |
| `Super + Left Mouse` | Drag window |

### Productivity

| Keybind | Action |
|---------|--------|
| `Super + C` | Copy selection |
| `Super + V` | Paste |
| `Super + Shift + T` | Open btop (system monitor) |
| `Super + Shift + F` | Open file manager |
| `Super + Shift + L` | Copy current URL (in web apps) |

### Workspace Navigation

| Keybind | Action |
|---------|--------|
| `Super + 0-9` | Switch to workspace 0-9 |
| `Super + Shift + 0-9` | Move window to workspace 0-9 |

## Unique Features

### Omarchy Menu (`Super + Alt + Space`)
- Install/remove packages
- Configure system settings
- Manage input devices
- Access utilities

### Auto-Restart
- Configuration changes in `~/.config/hypr/bindings.conf` trigger automatic process restarts

## Configuration

- **Main Config**: Uses Omarchy's opinionated defaults
- **User Config**: `~/.config/hypr/bindings.conf` for custom keybinds
- **Theme**: Tokyo Night (can be changed via Omarchy configuration)
- **Email**: Set via `omarchy.email_address`
- **Full Name**: Set via `omarchy.full_name`

## Scripts

Located in Omarchy's configuration directories:
- Workspace management scripts
- Application launcher scripts
- Power management scripts
- Screenshot utilities

## Tips

1. Press `Super + K` first time to learn the layout
2. Most productivity shortcuts use `Super + Shift` for consistency
3. Edit `~/.config/hypr/bindings.conf` for custom shortcuts
4. Use Omarchy Menu for system-level changes


## Integration with Grandlix-Gang

- Configured with user `t0psh31f@grandlix.gang`
- Tokyo Night theme applied
- Integrated with Home Manager for dotfiles
- Works seamlessly with NixOS impermanence setup
