# Noctalia Desktop Shell

> NFP uses **Noctalia v5** (native C++/OpenGL ES shell, not the Quickshell-based v4).

## Documentation

All Noctalia v5 documentation lives at: **https://docs.noctalia.dev**

### Key pages for NFP maintainers

| Topic | URL |
|-------|-----|
| Overview | https://docs.noctalia.dev/v5/ |
| NixOS installation | https://docs.noctalia.dev/v5/getting-started/nixos/ |
| Running the shell | https://docs.noctalia.dev/v5/getting-started/running-the-shell/ |
| Hyprland compositor settings | https://docs.noctalia.dev/v5/compositor-settings/hyprland/ |
| Configuration model | https://docs.noctalia.dev/v5/configuration/ |
| Bar & widgets | https://docs.noctalia.dev/v5/bar/ |
| Theming | https://docs.noctalia.dev/v5/theming/ |
| IPC commands | https://docs.noctalia.dev/v5/ipc/ |
| Greeter | https://docs.noctalia.dev/v5/greeter/ |
| FAQ | https://docs.noctalia.dev/v5/getting-started/faq/ |

## NFP Plugin Compatibility Architecture

- **Manifest Protocol**: Modern `plugin_api` integer declaration (range 3..32 supported by pinned shell). Legacy `min_noctalia` string manifests are deprecated and rejected by modern Noctalia.
- **Coherent Flake Inputs**: `noctalia`, `noctalia-official-plugins`, and `noctalia-community-plugins` are pinned to mutually compatible Sept 2026 revisions in `flake.lock`.
- **Regression Protection**: Enforced via `nix flake check` (`noctalia-registry-check`) which scans all 200+ official and community plugin manifests in Nix evaluation before machine updates.
- **Diagnostic Tool**: Read-only `noctalia-plugin-doctor` CLI command inspects `~/.config/noctalia/plugins` and reports plugin compatibility status.

### Safe Cache Cleanup Procedure for Stale Community Plugins

If upgrading from legacy Noctalia where stale unmanaged plugins were downloaded via UI into `~/.config/noctalia/plugins`:

1. Backup existing plugins:
   ```bash
   cp -r ~/.config/noctalia/plugins ~/.config/noctalia/plugins.bak-$(date +%Y%m%d%H%M%S)
   ```
2. Remove stale unmanaged downloaded plugins (preserving Nix-managed symlinks):
   ```bash
   find ~/.config/noctalia/plugins/ -mindepth 1 -maxdepth 1 ! -type l -exec rm -rf {} +
   ```
3. Restart Noctalia session:
   ```bash
   systemctl --user restart noctalia
   ```

## NFP-specific notes

- **Flake input**: `github:noctalia-dev/noctalia/cachix`
- **Binary cache**: `noctalia.cachix.org` configured in `layers/10-system/11-foundation/caches.nix`
- **Backend**: Hyprland on both z0r0 and luffy
- **Config**: Home Manager module via `inputs.noctalia.homeModules.default`
- **Systemd**: `programs.noctalia.systemd.enable = true`
- **Greeter**: `noctalia-greeter` (not SDDM, not greetd/ReGreet)
- **Config files**: `layers/40-desktop/43-noctalia/default.nix`, `ipc.nix`, `mutable-includes.nix`
