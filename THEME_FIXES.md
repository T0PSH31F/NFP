# Theme and Plugin Fixes - Implementation Summary

## Issues Identified and Fixed

### 1. Plymouth Boot Theme (hellonavi) - ✅ FIXED
**Problem**: Theme not showing on boot - using default "spinner" theme
**Root Cause**: Theme package wasn't installed to system packages
**Fix**: Added `environment.systemPackages = [hellonavi-theme];` to plymouth-hellonavi.nix
**File Modified**: `modules/nixos/themes/plymouth-hellonavi.nix`

### 2. SDDM Theme (sel-shaders) - ✅ FIXED
**Problem**: Theme not showing - only default themes visible
**Root Cause**: Theme package wasn't installed to system packages
**Fix**: Added `sddm-sel-theme` to `environment.systemPackages` in sddm-sel.nix
**File Modified**: `modules/nixos/themes/sddm-sel.nix`

### 3. Sonic Hyprcursor - ✅ FIXED
**Problem**: Cursor theme not configured or visible
**Root Cause**: 
- Package defined but never installed
- No environment variable set
- Wrong installation path
**Fixes**:
- Added `sonic-cursor` to home.packages in hyprland.nix
- Set `HYPRCURSOR_THEME=Sonic-cursor-hyprcursor` environment variable
- Updated package to install to both `/share/icons/` and `/share/hypr/hyprcursor/themes/`
**Files Modified**: 
- `modules/Desktop-env/hyprland.nix`
- `pkgs/sonic-cursor.nix`

### 4. Dynamic Cursor Plugin (hypr-dynamic-cursors) - ✅ FIXED
**Problem**: Plugins not loading (`hyprctl plugin list` showed "no plugins loaded")
**Root Cause**: `package = null` prevented home-manager from generating plugin config
**Fix**: Changed `package = null` to `package = pkgs.hyprland` while keeping `systemd.enable = false` for UWSM compatibility
**File Modified**: `modules/Desktop-env/hyprland.nix`

## Testing Instructions

### Test 1: Plymouth Boot Theme
```bash
# Rebuild system
sudo nixos-rebuild switch --flake .#z0r0

# Verify theme is installed
ls -la /run/current-system/sw/share/plymouth/themes/hellonavi

# Check current theme
plymouth-set-default-theme

# Test plymouth (requires reboot to see on actual boot)
sudo reboot
```
**Expected**: Should see hellonavi theme during boot instead of spinner

### Test 2: SDDM Theme
```bash
# Rebuild system
sudo nixos-rebuild switch --flake .#z0r0

# Verify theme is installed
ls -la /run/current-system/sw/share/sddm/themes/sel-shaders

# Restart display manager to see changes
sudo systemctl restart display-manager.service
```
**Expected**: Should see SEL theme at login screen instead of default theme

### Test 3: Sonic Hyprcursor
```bash
# Rebuild system
sudo nixos-rebuild switch --flake .#z0r0

# Verify cursor is installed
ls -la ~/.nix-profile/share/icons/Sonic-cursor-hyprcursor
ls -la ~/.nix-profile/share/hypr/hyprcursor/themes/Sonic-cursor-hyprcursor

# Check environment variable
echo $HYPRCURSOR_THEME

# Restart Hyprland session
uwsm stop
# Then log back in
```
**Expected**: Should see Sonic cursor theme in Hyprland

### Test 4: Dynamic Cursor Plugin
```bash
# Rebuild system
sudo nixos-rebuild switch --flake .#z0r0

# Restart Hyprland session
uwsm stop
# Then log back in

# Check if plugins are loaded
hyprctl plugin list
```
**Expected**: Should see both plugins listed:
- hypr-dynamic-cursors
- borders-plus-plus

## Configuration Changes Summary

### Files Modified:
1. `modules/nixos/themes/plymouth-hellonavi.nix` - Added theme to system packages
2. `modules/nixos/themes/sddm-sel.nix` - Added theme to system packages
3. `modules/Desktop-env/hyprland.nix` - Added sonic-cursor package, set HYPRCURSOR_THEME env var, fixed plugin loading
4. `pkgs/sonic-cursor.nix` - Updated installation paths for hyprcursor

### Key Configuration Points:
- Plymouth: Requires theme in both `boot.plymouth.themePackages` AND `environment.systemPackages`
- SDDM: Requires theme in both `services.displayManager.sddm.extraPackages` AND `environment.systemPackages`
- Hyprcursor: Requires installation to `/share/hypr/hyprcursor/themes/` and `HYPRCURSOR_THEME` env var
- Hyprland Plugins: Requires actual package (not null) for home-manager to generate plugin config, even with UWSM

## Rebuild Command
```bash
sudo nixos-rebuild switch --flake .#z0r0
```

## Notes
- All fixes maintain compatibility with existing UWSM setup
- Impermanence is configured to persist `.icons`, `.themes`, and `.cursors` directories
- Dynamic cursor plugin is configured with "tilt" mode (mode = "rotate" with threshold = 2)
- SEL theme variant is set to "shaders" (with visual effects)
