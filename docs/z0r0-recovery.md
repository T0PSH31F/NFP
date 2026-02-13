# z0r0 Recovery Instructions

## Problem
z0r0 (192.168.1.159) has 2 unusable generations — passwords for root and t0psh31f no longer work.
**Root cause**: `clan-inventory.nix` had `prompt = false` → auto-generated random passwords nobody knows + impermanence persists them + SSH password auth was disabled.

**Fix already pushed to GitHub** (commits `490b460` and `04da607`):
- Added `initialPassword = "changeme123"` for both users
- Changed clan password `prompt` to `true`
- Enabled SSH password auth
- Increased boot generations to 10

## Recovery Steps

### Method 0: Reset Password via GRUB (Fastest, no USB needed)
1. Reboot `z0r0`.
2. At the GRUB menu, select the default NixOS entry and press **`e`**.
3. Find the line starting with `linux` (it ends with `init=/nix/store/.../init`).
4. Append `init=/bin/sh` to the end of that line.
5. Press **`F10`** or **`Ctrl-x`** to boot.
6. You will get a root shell prompt `#`.
7. Remount the filesystem as read-write:
   ```bash
   mount -o remount,rw /
   ```
8. Reset the passwords:
   ```bash
   passwd root
   passwd t0psh31f
   ```
9. Reboot forcefully:
   ```bash
   reboot -f
   ```

### Method 1: Chroot from USB ISO (If GRUB is broken)
1. Boot z0r0 from any NixOS USB ISO

### 2. Decrypt LUKS and mount
```bash
cryptsetup open /dev/disk/by-uuid/458b615c-3ac2-4cff-98a2-c8e266bae90f crypted

mount -o subvol=@root /dev/mapper/crypted /mnt
mount -o subvol=@nix  /dev/mapper/crypted /mnt/nix
mount -o subvol=@home /dev/mapper/crypted /mnt/home
mount -o subvol=@persist /dev/mapper/crypted /mnt/persist
mount -o subvol=@log  /dev/mapper/crypted /mnt/var/log
mount /dev/disk/by-uuid/E6FA-59AC /mnt/boot
```

### 3. Reset passwords
```bash
nixos-enter --root /mnt
passwd root
passwd t0psh31f
exit
```

### 4. Rebuild with fixed config (pick one)

**Option A — Rebuild inside chroot (if z0r0 has internet via ISO):**
```bash
nixos-enter --root /mnt
cd /tmp
git clone https://github.com/T0PSH31F/NFP.git
nixos-rebuild switch --flake /tmp/NFP#z0r0
exit
umount -R /mnt
reboot
```

**Option B — Just reboot, then rebuild remotely from Nami:**
```bash
# Reboot z0r0 with reset passwords
umount -R /mnt
reboot

# From Nami (after it's installed):
cd ~/Clan/NFP && git pull
nixos-rebuild switch --flake .#z0r0 --target-host root@192.168.1.159
```

## Post-Recovery
1. Change passwords to something permanent
2. Run `clan vars generate` (now prompts interactively)
3. Disable SSH password auth: change `PasswordAuthentication` back to `false` in `flake-parts/system/networking.nix`
