# NFP Agent Onboarding Guide

> **Purpose**: Everything an AI agent (or human) needs to understand this
> system, diagnose boot failures, and perform repairs — written from the
> perspective of an agent who had to figure all of this out the hard way.

---

## 1. System Overview

| Machine | Role | Hardware | Hostname | Deploy Target |
|---------|------|----------|----------|---------------|
| **z0r0** | Laptop workstation, desktop, AI server, dev | LG 17Z90Q, Intel i7-1260P 12th gen, 16GB RAM, 1TB NVMe | `z0r0` | `root@127.0.0.1` (local) |
| **luffy** | Server, homelab, cache, AI server | Intel 9th gen, remote | `luffy` | `root@100.80.146.120` (Tailscale) |

Both machines share the **NFP (Nix Flake Pirates)** flake. Changes to shared
layers affect BOTH machines — be careful.

- **NixOS**: 26.05 (Yarara), nixpkgs-unstable
- **Flake framework**: clan-core + flake-parts
- **Flake location** (on z0r0): `/persist/home/t0psh31f/Clan/NFP`
- **Kernel**: linux-zen-7.0.9 (z0r0), configurable via `layers.layer-10.system.hardware.kernel`
- **Agent Harness**: The repository uses the NFP Agent Harness as system of record — see [`harness.md`](file:///home/t0psh31f/Clan/NFP/layers/00-cyberia/01-docs/harness.md).

---

## 2. Disk Layout (z0r0)

```
nvme0n1
├── nvme0n1p1  vfat FAT32  4G    EFIBOOT (systemd-boot ESP, mounted at /boot)
│                                     UUID: 3824-3E8C
├── nvme0n1p2             16G    (unused — formerly swap partition)
└── nvme0n1p3  crypto_LUKS 911G  encrypted root
                                      UUID: 458b615c-3ac2-4cff-98a2-c8e266bae90f
                                      mapper: /dev/mapper/crypted
                                      fs: btrfs
```

### Btrfs Subvolumes

| Subvol | Mount | Persistent? | Purpose |
|--------|-------|-------------|---------|
| `@root` | `/` | **NO** — rolled back every boot | Ephemeral root filesystem |
| `@root-blank` | — | — | Pristine snapshot of empty root (rollback source) |
| `@home` | `/home` | **NO** (by design — see impermanence.nix comment) | Ephemeral home dirs |
| `@home-blank` | — | — | Pristine home snapshot (not currently used for rollback) |
| `@nix` | `/nix` | **YES** | Nix store (survives reboot) |
| `@persist` | `/persist` | **YES** | Persistent data (bind-mounted into root via impermanence) |
| `@log` | `/var/log` | **YES** | Persistent logs & journals |
| `@backup` | `/backup` | **YES** | Backup storage |

> **Key**: Only `@root` is rolled back on boot. `@nix`, `@persist`, `@log`
> are persistent. `@home` is intentionally NOT rolled back (wiping it breaks
> impermanence bind-mount mountpoints → race conditions → login failures).

### Swap
- 32GB swapfile at `/persist/swapfile` (on @persist subvol)
- `systemd.gpt_auto=0` in kernel params to prevent auto-detection of broken swap partitions

---

## 3. Boot Flow (Critical for Diagnosis)

```
┌─────────────────────────────────────────────────────────────────────┐
│ 1. systemd-boot (ESP: /dev/nvme0n1p1, vfat, mounted at /boot)       │
│    Loads: kernel (linux-zen-7.0.9) + initrd                         │
│    Default: nixos-generation-NNN.conf                               │
│    Boot entries: /boot/loader/entries/nixos-generation-*.conf        │
│    Loader config: /boot/loader/loader.conf                          │
└──────────────────────────┬──────────────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│ 2. Initrd (systemd stage 1, boot.initrd.systemd.enable = true)      │
│    a. systemd-cryptsetup unlocks LUKS → /dev/mapper/crypted         │
│    b. rollback service: deletes @root, snapshots @root-blank → @root│
│       (uses util-linux-MINIMAL mount — initrd has its own copy)     │
│    c. Mounts @root at /sysroot                                      │
│    d. Mounts @nix → /sysroot/nix, @persist → /sysroot/persist,      │
│       @home → /sysroot/home, @log → /sysroot/var/log                │
│    e. initrd-nixos-activation-start:                                │
│       chroot /sysroot → runs prepare-root                           │
│       PATH = coreutils + util-linux-2.42-bin  ← FROM THE SYSTEM     │
│       Mounts special fs (proc, sys, dev) onto real root             │
│       Runs impermanence bind-mounts (machine-id, shell history...)  │
└──────────────────────────┬──────────────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│ 3. switch_root → Stage 2 (real systemd)                             │
│    a. Mounts /boot (vfat), /home, /var/log                          │
│    b. Starts services, firewall, networking                         │
│    c. impermanence bind-mounts from /persist (dirs + files)         │
│    d. home-manager activation for user t0psh31f                     │
└─────────────────────────────────────────────────────────────────────┘
```

### The prepare-root PATH (CRITICAL)

`prepare-root` is generated by nixpkgs and hardcodes its PATH:
```bash
PATH="/nix/store/9ypz3flq...-coreutils-9.11/bin:/nix/store/zca0hp2i...-util-linux-2.42-bin/bin"
```

After chroot into `/sysroot` (the rolled-back @root, which is nearly empty —
only has `nix/` mountpoint + whatever activation created), `/bin` only has
`sh`. So `mount`/`umount`/`findmnt` are found ONLY via the second PATH entry:
`util-linux-2.42-bin/bin/mount` → which is a SYMLINK to a sibling output.

If that symlink target is missing → `mount: command not found` → **entire
boot fails**. This is the #1 boot failure mode for this system.

---

## 4. Impermanence Design

Config: `layers/10-system/15-filesystem/impermanence.nix`

- Root (`@root`) is **ephemeral**: wiped to `@root-blank` on every boot
- `@root-blank` is intentionally minimal (just empty `nix/` dir) — NixOS
  activation creates `/bin`, `/etc` symlinks from the nix store at boot
- Persistent state lives in `@persist`, bind-mounted via impermanence module

### Persisted paths (system):
- `/etc/machine-id` — prevents fresh machine-id each boot (journal continuity)
- `/etc/ssh` — SSH host keys
- `/var/lib/systemd`, `/var/lib/nixos`
- `/etc/NetworkManager/system-connections`, `/var/lib/NetworkManager`

### Persisted paths (user t0psh31f):
- `Clan` (the flake repo!), `Projects`, `Documents`, `Downloads`, etc.
- `.config`, `.ssh`, `.gnupg`, `.cache`, `.mozilla`
- `.bash_history`, `.zsh_history`

### Rollback script (in initrd):
`boot.initrd.systemd.services.rollback` in impermanence.nix:
1. Mounts btrfs root at /mnt
2. Deletes nested subvols under @root
3. Deletes @root
4. Snapshots @root-blank → @root (fresh blank root)
5. Does NOT roll back @home (by design)

---

## 5. Flake Structure

```
NFP/
├── flake.nix              # flake-parts + clan-core, all inputs
├── clan.nix               # machine inventory, clan services (wifi, sshd, etc.)
├── machines/
│   ├── z0r0/
│   │   ├── default.nix    # z0r0-specific config (bootloader, layers, services)
│   │   ├── hardware.nix   # LUKS, btrfs subvols, fstab, swap
│   │   └── facter.json    # hardware facts (nixos-facter)
│   └── luffy/
│       └── default.nix
├── layers/                # dendritic layered module system
│   ├── 00-cyberia/        # templates, tests, clan inventory, devshells
│   ├── 10-system/         # foundation, processor, users, filesystem, etc.
│   │   ├── 11-foundation/ # base.nix (shared core), networking, nix-settings
│   │   ├── 12-processor/  # CPU, GPU, platform (audio, laptop)
│   │   ├── 13-users/      # root.nix, t0psh31f.nix
│   │   ├── 15-filesystem/ # impermanence.nix, google-drive.nix
│   │   └── ...
│   ├── 20-services/       # service modules (networking, ai, media, etc.)
│   ├── 30-theming/        # themes
│   ├── 40-desktop/        # desktop environments (hyprland via noctalia)
│   ├── 50-cli-tui-programs/
│   ├── 60-gui-programs/
│   ├── 70-agents/         # 9-tier AI subsystem (71-harness, 72-voice, 73-memory, 74-ai-infra, 75-mcp, 76-orchestrators, 77-dash-desk-ui, 78-llm-routers, 79-skills)
│   ├── 80-lib/            # libraries, overlays
│   └── 90-profiles/tags/  # tag-based profiles (workstation, desktop, laptop, etc.)
├── tools/
│   ├── mount-nfp.sh       # helper to mount system from live USB
│   └── fix-persist-permissions.sh
├── .agents/rules/           # agent rules (clan-architecture, organization)
├── layers/00-cyberia/01-docs/
│   ├── AGENT_ONBOARDING.md  # ← this file
│   ├── yazelix_guide.md     # nixvim/editor guide
│   ├── hermes-agent.md      # Hermes AI agent docs
│   ├── deployment.md        # deployment methods
│   ├── features.md          # feature overview
│   ├── deploy-from-live.md  # deployment from live USB
│   ├── RECOVERY_NOTE.md     # recovery history
│   └── progress.md          # session progress log
└── README.md              # project readme
```

### How machines are built:
- `clan.nix` defines machine inventory with tags
- Each machine imports `machines/<name>/default.nix` + tag profiles from `layers/90-profiles/tags/`
- Tags enable feature modules automatically (e.g., "laptop" → battery, wireless)
- Build: `nixos-rebuild boot --flake .#z0r0` (or `.#luffy`)

### Key shared files (affect BOTH machines):
- `layers/10-system/11-foundation/base.nix` — core settings, boot.initrd.systemd, util-linux workaround
- `layers/10-system/15-filesystem/impermanence.nix` — impermanence + rollback
- All `layers/` modules are shared unless scoped

### z0r0-specific files (safe to edit without affecting luffy):
- `machines/z0r0/default.nix`
- `machines/z0r0/hardware.nix`

---

## 6. Known Issues & Workarounds

### Issue 1: util-linux broken symlink reference metadata (CRITICAL)

**Affects**: nixpkgs unstable, util-linux-2.42 multi-output package

**The bug**: `util-linux-2.42-bin` (the `bin` output) contains symlinks to
sibling outputs (`mount`, `login`, `swap`), but nix's reference metadata
does NOT list these sibling outputs as references of `bin`. So
`nix-store --gc` sees them as unreferenced and **deletes them**.

**Impact**: When the `mount` output is deleted, `prepare-root` can't find
`mount` → `mount: command not found` → boot cascades to total failure:
- Impermanence bind-mounts fail (machine-id, shell history)
- `/boot` (vfat) fails to mount
- Firewall fails to start
- Firmware (iwlwifi, bluetooth) can't load (specialfs not mounted)
- Fresh machine-id generated each boot (journals scattered)

**Existing workaround** (base.nix:14-16):
```nix
security.wrappers.mount.source = lib.mkForce "${pkgs.util-linuxMinimal}/bin/mount";
security.wrappers.umount.source = lib.mkForce "${pkgs.util-linuxMinimal}/bin/umount";
```
This only fixes the **running system** (stage 2 suid wrappers). It does NOT
fix `prepare-root` (stage 1.5) which uses the full `util-linux-2.42-bin`.

**Permanent fix** (machines/z0r0/default.nix, section 06):
An activation script creates gcroots for all `util-linux-2.42-bin` symlink
targets at every boot, so `nix-store --gc` can't delete them.

**Safe GC**: Use `nix-safe-gc` (provided by the config) or
`nix-collect-garbage --delete-older-than 14d`. NEVER use `nix-store --gc`
or `nix-store --gc --max-freed` without running `nixos-rebuild boot` first.

### Issue 2: openrazer incompatible with linux 7.0.10
Disabled in z0r0 config: `peripherals.razer.enable = lib.mkForce false`

### Issue 3: LM Studio packaging error in unstable
Disabled: `ai-services.lmstudio.enable = lib.mkForce false`

---

## 7. Recovery from Live USB

### Step 1: Boot NixOS minimal ISO

### Step 2: Mount the system
Either use the helper:
```bash
cd /persist/home/t0psh31f/Clan/NFP  # or wherever the flake is accessible
./tools/mount-nfp.sh z0r0
```

Or manually:
```bash
# Decrypt LUKS
echo 'Neonknightowlerik' | sudo cryptsetup open /dev/nvme0n1p3 cryptroot

# Mount subvols
sudo mount -t btrfs -o subvol=@root /dev/mapper/cryptroot /mnt
sudo mkdir -p /mnt/{nix,persist,var/log,home,boot}
sudo mount -t btrfs -o subvol=@nix /dev/mapper/cryptroot /mnt/nix
sudo mount -t btrfs -o subvol=@persist /dev/mapper/cryptroot /mnt/persist
sudo mount -t btrfs -o subvol=@log /dev/mapper/cryptroot /mnt/var/log
sudo mount -t btrfs -o subvol=@home /dev/mapper/cryptroot /mnt/home
sudo mount /dev/nvme0n1p1 /mnt/boot
```

### Step 3: Chroot and rebuild
```bash
sudo nixos-enter --root /mnt
# Inside chroot:
cd /persist/home/t0psh31f/Clan/NFP
nixos-rebuild boot --flake .#z0r0
exit
```

> Use `boot` not `switch` — `boot` updates the bootloader without trying
> to activate services in the chroot.

### Step 4: Reboot
```bash
sudo umount -R /mnt
sudo cryptsetup close cryptroot
# Power off, remove USB, power on
```

---

## 8. Boot Failure Diagnosis Checklist

### Check persisted journals
Journals are in `@log` subvol (persistent). After mounting:
```bash
# List all journal directories (each = a machine-id)
ls /mnt/var/log/journal/

# The correct machine-id for z0r0: b838be84e7674b9e9bb11dde324ae027
# (stored in /persist/etc/machine-id)
# If you see MANY directories with different IDs, it means impermanence
# machine-id bind-mount is failing (each boot generates a fresh ID).

# Read a specific boot's journal:
journalctl --file=/mnt/var/log/journal/<MACHINE_ID>/system.journal -xb -p err
```

### Common failure patterns

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `mount: command not found` in prepare-root | util-linux sibling outputs GC'd | Substitute missing paths + add gcroots (see Issue 1) |
| Fresh machine-id every boot (many journal dirs) | Impermanence `/etc/machine-id` bind-mount failing | Cascade from mount-not-found; fix mount first |
| `/boot` fails to mount | Cascade from mount-not-found (vfat is fine) | Fix mount first |
| Firewall fails to start | Cascade from mount-not-found | Fix mount first |
| iwlwifi/bluetooth firmware missing | Cascade (specialfs not mounted → firmware path unavailable) | Fix mount first |
| `prepare-root: line 51: mount: command not found` | THE root cause — util-linux mount output GC'd | See Issue 1 |

### How to check if util-linux paths are missing
```bash
# After mounting @nix:
ls /mnt/nix/store/bq88bkx76z609nxa7851j39n4b619y7q-util-linux-minimal-2.42-mount
# If missing → mount is gone, needs substitution

# Check all util-linux-2.42-bin symlinks:
find /mnt/nix/store/zca0hp2i6c5yxbaxpl6x76mxc2b0aiqm-util-linux-2.42-bin -type l | \
  while read l; do readlink -f "$l" | grep -q "^/nix/store" && \
  test -e "$(readlink -f "$l")" || echo "BROKEN: $l"; done
```

### How to restore missing util-linux paths
```bash
# Substitute from binary cache (needs network):
sudo nix build --store /mnt --no-link --print-out-paths \
  /nix/store/bq88bkx76z609nxa7851j39n4b619y7q-util-linux-minimal-2.42-mount

# Add gcroot so it won't be GC'd again:
sudo ln -sfn /nix/store/bq88bkx76z609nxa7851j39n4b619y7q-util-linux-minimal-2.42-mount \
  /mnt/nix/var/nix/gcroots/util-linux-2.42-mount-boot-fix
```

---

## 9. Credentials (for recovery only)

| Credential | Value |
|-----------|-------|
| LUKS password | `Neonknightowlerik` |
| Root password | `5677` |
| User | `t0psh31f` (uid 1001, wheel, passwordless sudo in live env) |
| SOPS age key | `/persist/home/t0psh31f/.config/sops/age/keys.txt` |

---

## 10. Rebuild Commands

```bash
# From the running system:
cd ~/Clan/NFP
sudo nixos-rebuild boot --flake .#z0r0    # updates bootloader, doesn't switch
sudo nixos-rebuild switch --flake .#z0r0  # updates bootloader + activates now

# From a live USB (after mounting at /mnt):
sudo nixos-enter --root /mnt
cd /persist/home/t0psh31f/Clan/NFP
nixos-rebuild boot --flake .#z0r0

# Deploy to luffy remotely:
sudo nixos-rebuild switch --flake .#luffy --target-host root@100.80.146.120
```

---

## 11. Important Notes for Agents

1. **NEVER run `nix-store --gc`** on this system without running
   `nixos-rebuild boot` first. The util-linux broken-reference bug will
   delete boot-critical paths. Use `nix-safe-gc` instead.

2. **The flake is shared** between z0r0 and luffy. Changes to `layers/`
   or `base.nix` affect both. Scope machine-specific changes to
   `machines/<name>/default.nix`.

3. **@root-blank is intentionally empty** (just `nix/` dir). Don't try to
   "fix" it by populating it — NixOS activation creates everything at boot.

4. **@home is NOT rolled back** by design. Don't add @home rollback without
   understanding the race condition with impermanence bind-mounts (see
   impermanence.nix comment).

5. **The flake lives in @persist** (`/persist/home/t0psh31f/Clan/NFP`),
   which is persistent. It survives reboot. But @root is wiped, so any
   uncommitted changes in a working dir on @root would be lost.

6. **Journals are persistent** in @log. You can read failed-boot journals
   from a live env by mounting @log and using `journalctl --file=...`.

7. **systemd stage 1 initrd**: The initrd uses systemd
   (`boot.initrd.systemd.enable = true`). The rollback is a systemd
   service, not a shell script in initrd.

8. **clan-core vars**: Secrets are managed via `clan.core.vars` with sops
   backend. Never hardcode secrets in nix files. See `.agents/rules/clan-architecture.md`.

9. **uwsm session crashes**: If the session crashes and you get locked out
   (can't re-login, TTY shows flashing cursor), this is caused by:
   - uwsm env-preloader DBus timeout (`org.freedesktop.DBus.Error.NoReply`)
   - Getty binary GC'd from Nix store (makes TTY inaccessible)
   - Orphaned session state preventing greetd from starting fresh
   Fix: `session-resilience.nix` in `layers/10-system/19-optimizations/`
   adds: getty GC root pinning, uwsm DBus retry/timeout overrides,
   boot-time orphaned session cleanup and recovery. Enable via
   `layers.layer-10.system.sessionResilience.enable = true`.
