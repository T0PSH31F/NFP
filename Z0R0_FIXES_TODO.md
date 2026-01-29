# Z0R0 Fixes TODO

## Phase 1: Fix Home-Manager Build Issues
- [x] Review and fix Home-Manager configuration in z0r0/default.nix
- [x] Ensure all Home-Manager module imports are correct
- [x] Verify Home-Manager options are properly defined

## Phase 2: Fix Monitoring Service
- [x] Resolve Promtail NAMESPACE issue in monitoring.nix
- [x] Test monitoring service build
- [x] Enable monitoring for z0r0

## Phase 3: Fix Media Stack Service
- [x] Resolve Prowlarr STATE_DIRECTORY issue in media-stack.nix
- [x] Test media stack build
- [x] Enable media stack for z0r0

## Phase 4: Remove Luffy from Clan Secrets
- [x] Remove sops/secrets/luffy-age.key/ directory
- [x] Verify no other luffy references exist
- [x] Add z0r0-age.key to secrets
- [x] Update clan configuration if needed

## Phase 5: Testing
- [ ] Test full system build with nixos-rebuild test
- [ ] Test home-manager build specifically
- [ ] Verify all services start correctly
