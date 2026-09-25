---
description: Boot recovery and store integrity rule set
trigger: "When diagnosing boot failures, running nix-store garbage collection, or repairing from a live USB environment."
---

# Boot Recovery & Store Integrity

## 1. The #1 Boot Failure Mode: util-linux GC bug

If z0r0 fails to boot and journals show `mount: command not found` in
`prepare-root`, the cause is almost certainly the **util-linux broken
reference metadata bug** (nixpkgs unstable). `nix-store --gc` deleted
the `mount`/`login`/`swap` sibling outputs of `util-linux-2.42-bin`.

**Quick fix from live USB:**
```bash
sudo cryptsetup open /dev/nvme0n1p3 cryptroot
sudo mount -t btrfs -o subvol=@nix /dev/mapper/cryptroot /mnt/nix
sudo nix build --store /mnt --no-link --print-out-paths \
  /nix/store/bq88bkx76z609nxa7851j39n4b619y7q-util-linux-minimal-2.42-mount
sudo ln -sfn /nix/store/bq88bkx76z609nxa7851j39n4b619y7q-util-linux-minimal-2.42-mount \
  /mnt/nix/var/nix/gcroots/util-linux-2.42-mount-boot-fix
```

Then check for other missing util-linux outputs (login, swap) and restore
them the same way. See `docs/AGENT_ONBOARDING.md` section 8 for full
diagnosis checklist.

## 2. NEVER run unsafe garbage collection

- **Forbidden**: `nix-store --gc`, `nix-store --gc --max-freed N`
- **Safe**: `nix-safe-gc` (provided by z0r0 config), or
  `nix-collect-garbage --delete-older-than 14d`
- **Before any GC**: Always run `nixos-rebuild boot` first to
  re-register the full closure as GC roots.
- The util-linux multi-output reference metadata bug means GC can delete
  boot-critical paths that nix doesn't know are needed.

## 3. Recovery Environment

- **Live USB**: NixOS minimal ISO, user `t0psh31f` with passwordless sudo
- **LUKS password**: Specified in secure local credentials store / sops
- **Root password**: Specified in secure local credentials store / sops
- **Flake location**: `/persist/home/t0psh31f/Clan/NFP` (on @persist subvol)
- **Mount helper**: `./tools/mount-nfp.sh z0r0`
- **Full guide**: `docs/AGENT_ONBOARDING.md`

## 4. Shared Flake Warning

Changes to `layers/` or `base.nix` affect BOTH z0r0 and luffy.
Scope machine-specific fixes to `machines/<name>/default.nix`.
When in doubt, verify luffy still builds: `nix build .#luffy`

## 5. Journal Diagnosis

Journals persist in `@log` subvol (`/var/log/journal/`).
z0r0's correct machine-id: `b838be84e7674b9e9bb11dde324ae027`.
Many journal dirs with different IDs = impermanence machine-id bind-mount
failing (cascade from mount-not-found).
