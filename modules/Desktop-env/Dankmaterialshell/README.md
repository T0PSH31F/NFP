# Dank Material Shell (Niri)

Dank Material Shell is a modern desktop shell for Wayland, optimized for the Niri compositor. It features a Material Design-inspired interface with a focus on aesthetics and functionality.

## Features
- **Material Design**: Sleek, modern UI with dynamic theming.
- **Niri Integration**: Optimized for the Niri scrolling tiling window manager.
- **Unified Shell**: Replaces waybar, swaylock, mako, and launchers with a cohesive experience.
- **Widgets**: Includes panels, docks, and overlays.

## Keybindings (Niri Default)
- **Super + Enter**: Open Terminal
- **Super + D**: Open Launcher (DMS)
- **Super + Q**: Close Window
- **Super + Left/Right**: Scroll Workspace
- **Super + Shift + Left/Right**: Move Window
- **Super + F**: Fullscreen
- **Super + Shift + E**: Exit

## Configuration
The configuration is managed via NixOS and Home Manager modules provided by the `dank-material-shell` flake.

### Customization
You can customize the shell by modifying `modules/desktop/dankmaterial/default.nix`.

## Links
- [GitHub Repository](https://github.com/AvengeMedia/DankMaterialShell)
- [Niri Compositor](https://github.com/YaLTeR/niri)
