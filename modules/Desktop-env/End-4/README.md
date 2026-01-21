# Illogical Impulse Desktop Environment

Illogical Impulse is a sophisticated Hyprland configuration with advanced workspace management, dynamic theming, and a feature-rich shell environment.

## Features

- **Window Manager**: Hyprland (Wayland compositor)
- **Workspace System**: Grouped workspaces (11-20, 21-30, etc.)
- **Theming**: Dynamic color adjustment with wallpaper
- **Sidebar**: Right sidebar with clock, widgets, and settings
- **Configuration**: Split between default and custom configs

## Keybindings

### Essential Shortcuts

| Keybind | Action |
|---------|--------|
| `Super + I` | Open settings |
| `Super + Tab` | Toggle workspace overview |
| `Ctrl + Super + T` | Wallpaper selector (adjusts colors) |

### Window Management

| Keybind | Action |
|---------|--------|
| `Super + Left/Right/Up/Down` | Move/swap windows across monitors |
| `Super + Shift + Left/Right/Up/Down` | Move windows to adjacent workspaces |

### Workspace Navigation

| Keybind | Action |
|---------|--------|
| `Super + 2` | Switch to workspace 12 (if in 11-20 group) |
| `Super + 3` | Switch to workspace 13 (if in 11-20 group) |
| *etc.* | Workspace numbers relative to current group |

## Unique Features

### Grouped Workspaces
- Workspaces organized in groups: 11-20, 21-30, 31-40, etc.
- `Super + #` switches within current group
- Move windows between groups with directional keys

### Dynamic Theming
- **Wallpaper Selection** (`Ctrl + Super + T`):
  - Automatically adjusts shell colors
  - Updates Qt and GTK app themes
  - Repositions background clock
  - Coordinates entire color scheme

### Workspace Overview
- Toggle with `Super + Tab`
- Visual representation of all workspaces
- Quick workspace switching
- Window previews

### Settings Panel
- Access via `Super + I` or sidebar gear button
- Configure system settings
- Manage workspace groups
- Adjust shell behavior

### Right Sidebar
Features:
- Background clock (auto-positioned with wallpaper)
- System widgets
- Quick settings access
- Notifications

## Configuration

### File Locations

- **Default Keybinds**: `~/.config/hypr/hyprland/keybinds.conf`
- **Custom Keybinds**: `~/.config/hypr/custom/keybinds.conf`
- **Workspace Scripts**: `~/.config/hypr/hyprland/scripts/workspace_action.sh`
- **Main Config**: `~/.config/hypr/hyprland.conf`

### Customization Methods

1. **Add Custom Keybinds**:
   - Edit `~/.config/hypr/custom/keybinds.conf`
   - Use `unbind` to override defaults

2. **Override Defaults**:
   - Copy default configs to `custom/` directory
   - Modify as needed

3. **Workspace Behavior**:
   - Edit `workspace_action.sh` for custom actions
   - Configure group ranges
   - Add navigation shortcuts

## Scripts

### Workspace Management
- `workspace_action.sh`: Handles grouped workspace navigation
- Custom scripts for workspace-specific actions

### Theming Scripts
- Wallpaper color extraction
- Qt/GTK theme synchronization
- Clock repositioning automation

### Utility Scripts
- Settings panel management
- Widget configuration
- Notification handling

## Tips

1. **Learn Workspace Groups**: Start in workspace 11, use `Super + 2-9` to navigate within 11-20
2. **Customize Wallpaper**: `Ctrl + Super + T` adapts entire theme to your choice
3. **Quick Settings**: `Super + I` for fast system config access
4. **Override Binds**: Use `custom/keybinds.conf` to avoid conflicts
5. **CLI Tools**: `eza` and `lsd` configured for terminal use
6. **Workspace Overview**: `Super + Tab` shows all workspaces visually

## Advanced Features

### Workspace Groups
Configure ranges in workspace scripts:
- Group 1: Workspaces 11-20
- Group 2: Workspaces 21-30
- Group 3: Workspaces 31-40
- etc.

### Cross-Monitor Window Movement
Use `Super + Shift + Arrows` to:
- Move windows between monitors
- Transfer to different workspace groups
- Maintain window state and properties

### Color Coordination
Wallpaper selection triggers:
1. Color extraction from image
2. Shell theme update
3. Qt application theme sync
4. GTK application theme sync
5. Widget color adjustment
6. Clock background positioning

## Integration with Grandlix-Gang

- Enabled via `programs.illogical-impulse.enable`
- Home Manager integration for dotfiles
- NetworkManager and geoclue2 enabled
- Hyprland system-wide integration
- Works with NixOS impermanence

## Troubleshooting

- **Workspace confusion**: Remember you're in a group (11-20, etc.)
- **Keybind conflicts**: Use `custom/keybinds.conf` with `unbind`
- **Theme not updating**: Re-run wallpaper selector (`Ctrl + Super + T`)
- **Settings not saving**: Check `~/.config/hypr/custom/` permissions
