# Z0R0 Fixes Summary

## Overview
This document summarizes all fixes applied to resolve z0r0 configuration issues including:
- Home-Manager build errors (exit code 4)
- Monitoring service (Promtail NAMESPACE issue)
- Media stack service (Prowlarr STATE_DIRECTORY issue)
- Clan secrets (removing luffy references)

## Changes Made

### 1. Fixed Media Stack Service (modules/nixos/services/media-stack.nix)
**Problem:** Prowlarr service had STATE_DIRECTORY ownership issues and didn't support group option directly.

**Solution:**
- Removed `group = config.services-config.media-stack.group` from `services.prowlarr` (not supported)
- Added `Group = lib.mkForce config.services-config.media-stack.group` to systemd service config
- Added namespace fixes for impermanence compatibility:
  - `PrivateTmp = lib.mkForce false`
  - `ProtectSystem = lib.mkForce false`
  - `ProtectHome = lib.mkForce false`
  - `ReadWritePaths = [ "/var/lib/prowlarr" ]`
- Added proper service dependencies:
  - `after = [ "network.target" "local-fs.target" ]`
  - `wants = [ "network-online.target" ]`

### 2. Fixed Monitoring Service (modules/nixos/services/monitoring.nix)
**Problem:** Promtail had NAMESPACE conflicts with impermanence bind mounts.

**Solution:**
- Enhanced systemd service configuration to fix namespace issues:
  - `PrivateTmp = lib.mkForce false`
  - `ProtectSystem = lib.mkForce false`
  - `ProtectHome = lib.mkForce false`
  - `ReadWritePaths = [ "/var/lib/promtail" ]`
  - `TemporaryFileSystem = lib.mkForce ""`
  - `BindReadOnlyPaths = lib.mkForce ""`
  - `BindPaths = lib.mkForce ""`
- Added proper service dependencies:
  - `after = [ "network.target" "local-fs.target" ]`
  - `wants = [ "network-online.target" ]`

### 3. Enabled Services for z0r0 (machines/z0r0/default.nix)
**Problem:** Monitoring and media stack services were disabled due to build errors.

**Solution:**
- Changed `services-config.media-stack.enable = true` (was false)
- Changed `services-config.monitoring.enable = true` (was false)
- Updated comments to reflect fixes

### 4. Removed Luffy from Clan Secrets
**Problem:** Old luffy machine references caused z0r0 to be seen as a stranger on reboot.

**Solution:**
- Removed `sops/secrets/luffy-age.key/` directory entirely
- Verified no luffy references remain in *.nix files

### 5. Added z0r0 Age Key to Secrets
**Problem:** z0r0 needed its own age key for proper clan secrets management.

**Solution:**
- Generated new age key pair for z0r0
- Created `sops/secrets/z0r0-age.key/secret` (encrypted)
- Created `sops/secrets/z0r0-age.key/users/t0psh31f/key.json` (public key)
- Updated `sops/machines/z0r0/key.json` with new public key
- Public key: `age1pqcyhq9au4r9yl5dxmc4urucna23jpzue6plv2pql2xr9v7j4sfsm696e3`

## Testing Status

### Completed
- [x] Fixed media stack Prowlarr configuration
- [x] Fixed monitoring Promtail namespace issues
- [x] Enabled monitoring and media stack services
- [x] Removed luffy from clan secrets
- [x] Added z0r0 age key to secrets

### In Progress
- [ ] Running nixos-rebuild test to verify all fixes
- [ ] Verify Home-Manager builds successfully
- [ ] Verify all services start correctly

## Next Steps

After successful build verification:
1. Test actual system rebuild on z0r0
2. Verify all services are running:
   - Prometheus (port 9090)
   - Grafana (port 3000)
   - Loki (port 3100)
   - Promtail (port 9080)
   - Deluge (port 8112)
   - Sonarr (port 8989)
   - Radarr (port 7878)
   - Prowlarr (port 9696)
   - Lidarr (port 8686)
   - Readarr (port 8787)
   - Bazarr (port 6767)
3. Verify clan secrets work correctly on reboot
4. Document any additional issues found

## Files Modified

1. `modules/nixos/services/media-stack.nix` - Fixed Prowlarr configuration
2. `modules/nixos/services/monitoring.nix` - Fixed Promtail namespace issues
3. `machines/z0r0/default.nix` - Enabled monitoring and media stack
4. `sops/secrets/z0r0-age.key/` - Added new age key (directory created)
5. `sops/machines/z0r0/key.json` - Updated with new public key
6. `sops/secrets/luffy-age.key/` - Removed (directory deleted)

## Notes

- All fixes use `lib.mkForce` to override default systemd service configurations
- Namespace fixes ensure compatibility with impermanence bind mounts
- Service dependencies ensure proper startup order
- Age key generation follows clan-core conventions
- No luffy references remain in the configuration
