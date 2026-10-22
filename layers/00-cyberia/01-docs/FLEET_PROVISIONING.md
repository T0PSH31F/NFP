# NFP Fleet Provisioning — Zero-Touch Host Bootstrap

This document describes the complete workflow for bootstrapping a new machine
into the NFP Clan fleet using the self-contained `nfp-installer-iso`.

---

## Overview

```
Boot ISO → nfp-install-host wizard → Btrfs layout → LUKS → Age key gen
         → Headscale Tailnet enrollment → nixos-install → reboot
         → Post-install: add Age key to .sops.yaml → clan machines update
```

## Prerequisites

- NFP installer ISO burned to USB or PXE-booted
  - Build: `nix build .#packages.x86_64-linux.installer-iso`
- Target machine with ≥32 GB disk
- Internet access (or local nixos-anywhere with bundled store)
- Headscale pre-auth key (from `headscale preauthkeys create --expiration 1h --reusable`)

---

## Step 1: Boot the Installer ISO

Boot from USB / PXE. The live session auto-logs in as `nixos` with passwordless sudo.

Verify connectivity:
```bash
ping 1.1.1.1
```

---

## Step 2: Run `nfp-install-host`

```bash
nfp-install-host
```

The interactive wizard will prompt for:

| Prompt | Example |
|--------|---------|
| Hostname | `sanji` |
| Target disk | `/dev/nvme0n1` |
| LUKS encryption | `Y` |
| LUKS passphrase | (enter securely) |
| Headscale pre-auth key | `hspreauth:...` |

The wizard will then:
1. **Partition** — GPT with EFI + data partitions
2. **Encrypt** — LUKS2 on data partition (if enabled)
3. **Btrfs subvolumes** — creates the impermanence layout:
   - `@root` — ephemeral root (wiped on boot)
   - `@root-blank` — read-only snapshot for impermanence wipe
   - `@persist` — `/persist` (survives reboots)
   - `@nix` — `/nix` store
   - `@swap` — swap file volume
   - `@log` — `/var/log` (persistent journals)
4. **Age key** — generates `/persist/etc/sops/age/machine.key`
5. **Tailnet** — stores pre-auth key for first-boot enrollment
6. **Install** — `nixos-install --flake github:T0PSH31F/NFP#<hostname>`

---

## Step 3: Register the New Host in NFP

After the wizard completes (before rebooting the new machine), on your workstation:

### 3a. Add machine to `.sops.yaml`

The wizard prints the Age public key. Add it to `.sops.yaml`:

```yaml
keys:
  machines:
    sanji: &sanji age1<pubkey_from_wizard>
creation_rules:
  - path_regex: machines/sanji/.*
    key_groups:
      - age:
        - *sanji
        - *t0psh31f  # admin key always present
```

Then re-encrypt secrets for the new machine:
```bash
sops updatekeys machines/sanji/secrets.yaml
```

### 3b. Create machine directory

```bash
mkdir -p machines/sanji
```

Create `machines/sanji/default.nix`:

```nix
{
  clan.core.networking.targetHost = "root@<tailscale-ip-or-hostname>";
  machine = {
    name = "sanji";
    tags = [ "desktop" "ai-interface" ];  # choose appropriate tags
  };
  layers.desktop.experience = "noctalia-hyprland";  # or preferred experience
}
```

### 3c. Register in `clan.nix`

Add to the `machines` attrset in `flake.nix` or `clan.nix`:

```nix
machines.sanji = {
  directory = ./machines/sanji;
};
```

### 3d. Deploy

```bash
clan machines update sanji
```

This distributes SOPS secrets, runs the NixOS activation, and completes enrollment.

---

## Step 4: Tailnet Auto-Enrollment (first boot)

On first boot, the new host runs:
```bash
tailscale up --login-server https://headscale.grandlix.gang \
             --auth-key $(cat /persist/etc/nfp/headscale-preauth-key)
```

Verify enrollment from z0r0:
```bash
headscale nodes list
```

---

## Step 5: Add to Monitoring & Dashboard

After Tailnet enrollment:

1. **Prometheus** — add scrape config to `layers/20-services/prometheus.nix`
2. **Homepage** — add service entry to `layers/20-services/homepage.nix`
3. **Grafana** — host will auto-appear via Prometheus scrape if using discovery

---

## Disk Layout Reference

```
/dev/nvme0n1p1  → ESP / /boot   (vfat, 512 MiB)
/dev/nvme0n1p2  → LUKS container
  /dev/mapper/cryptroot → Btrfs pool
    @root         → /            (ephemeral, wiped on boot via impermanence)
    @root-blank   → blank snapshot for impermanence wipe
    @persist      → /persist     (survives reboots)
    @nix          → /nix         (Nix store)
    @swap         → /swap        (swap file)
    @log          → /var/log     (persistent journals)
```

---

## Troubleshooting

### `nixos-install` fails: host not in flake

The hostname must have a corresponding `nixosConfigurations.<hostname>` in the flake.
Create `machines/<hostname>/default.nix` with minimal config and push to `github:T0PSH31F/NFP`
before running `nfp-install-host`, or use `nixos-anywhere` with `--flake .#<hostname>`
from a local checkout.

### Tailnet enrollment fails on first boot

Check: `/persist/etc/nfp/headscale-preauth-key` exists and is not expired.
Re-generate with `headscale preauthkeys create` and update the file manually.

### LUKS passphrase forgotten

Recovery requires the SOPS-encrypted LUKS key backup (stored by `clan.core.vars`
if using the vars-managed LUKS workflow). See `layers/00-cyberia/01-docs/recovery.md`.

---

## Building the ISO

```bash
# Full ISO build (slow first time, cached after)
nix build .#packages.x86_64-linux.installer-iso --print-build-logs

# Write to USB (replace /dev/sdX)
sudo dd if=result/iso/nfp-installer-*.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

The ISO is pre-bundled with Clan CLI, Age, SOPS, Btrfs tools, and the NFP
Nix store closure for common packages to minimize internet dependencies during install.
