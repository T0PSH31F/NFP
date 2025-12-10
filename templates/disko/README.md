# Disko Templates

Declarative disk partitioning templates for NixOS using [disko](https://github.com/nix-community/disko).

## Available Templates

### 1. Simple (`simple.nix`)
**Use case:** Basic installations, testing, minimal setups

**Layout:**
- 1GB FAT32 `/boot`
- ext4 `/` (100% remaining)
- No encryption

**When to use:**
- Quick test VMs
- Simple desktops
- Learning NixOS

---

### 2. Impermanence (`impermanence.nix`)
**Use case:** "Delete your darlings" - NixOS impermanence setup

**Layout:**
- 4GB FAT32 `/boot`
- LUKS encrypted btrfs with subvolumes:
  - `@root` → `/` (wiped on boot)
  - `@nix` → `/nix` (persistent)
  - `@persist` → `/persist` (your persistent data)
  - `@home` → `/home` (optional persistence)
  - `@backup` → `/backup`
  - `@log` → `/var/log`
  - `@swap` → swap file (16GB default)

**When to use:**
- Reproducible desktops
- Clean system state on every boot
- Maximum declarative configuration

**Required:** Use with [impermanence](https://github.com/nix-community/impermanence) module

---

### 3. ZFS (`zfs.nix`)
**Use case:** Servers, NAS, databases, file sharing

**Layout:**
- 1GB FAT32 `/boot`
- LUKS encrypted ZFS pool with datasets:
  - `zroot/root` → `/`
  - `zroot/nix` → `/nix` (no snapshots)
  - `zroot/home` → `/home` (with quota)
  - `zroot/srv` → `/srv` (web content, 128K recordsize)
  - `zroot/nas` → `/nas` (file sharing, 1M recordsize)
  - `zroot/database` → `/var/lib/databases` (16K recordsize)
  - `zroot/containers` → `/var/lib/containers`
  - `zroot/backup` → `/backup` (max compression)

**Features:**
- Automatic snapshots
- Per-dataset optimization
- Data integrity (scrubbing)
- Reserved space for emergencies

**When to use:**
- File servers (NAS/FTP)
- Web servers
- Database servers
- Containers/VMs
- Any scenario needing snapshots/rollbacks

---

## Usage

### Installation

1. **Choose a template:**
   ```bash
   cp templates/disko/impermanence.nix machines/mymachine/disko.nix
   ```

2. **Edit disk device:**
   ```nix
   device = "/dev/nvme0n1"; # Change to your actual disk!
   ```

3. **Set up LUKS password (encrypted templates only):**

   **Option A: Manual (during installation)**
   ```bash
   echo "my-secure-password" > /tmp/secret.key
   ```

   **Option B: Clan secrets (recommended)**
   ```bash
   clan secrets set disk-password
   ```
   Then update the template:
   ```nix
   passwordFile = config.clan.core.facts.services.disk-password.secret."disk-password".path;
   ```

4. **Import in machine config:**
   ```nix
   # machines/mymachine/default.nix
   imports = [
     ./disko.nix
   ];
   ```

5. **Install:**
   ```bash
   clan machines install mymachine
   ```

### Impermanence Setup

After installing with the impermanence template:

1. **Add impermanence module to flake inputs:**
   ```nix
   inputs.impermanence.url = "github:nix-community/impermanence";
   ```

2. **Configure persistence:**
   ```nix
   environment.persistence."/persist" = {
     hideMounts = true;
     directories = [
       "/var/lib/nixos"
       "/var/lib/systemd/coredump"
       "/etc/nixos"
       # Add more as needed
     ];
     files = [
       "/etc/machine-id"
       "/etc/ssh/ssh_host_ed25519_key"
       "/etc/ssh/ssh_host_ed25519_key.pub"
       "/etc/ssh/ssh_host_rsa_key"
       "/etc/ssh/ssh_host_rsa_key.pub"
     ];
   };
   ```

### ZFS Configuration

After installing with the ZFS template:

1. **Set host ID (required):**
   ```nix
   networking.hostId = "$(head -c 8 /etc/machine-id)";
   ```

2. **Enable ZFS services:**
   ```nix
   boot.supportedFilesystems = [ "zfs" ];
   services.zfs.autoSnapshot.enable = true;
   services.zfs.autoScrub.enable = true;
   ```

## Customization Tips

### Adjust Sizes
```nix
size = "512M";  # Boot partition
size = "50%";   # Half of remaining
size = "100%";  # All remaining
```

### Btrfs Options
```nix
mountOptions = [ 
  "compress=zstd"  # Compression
  "noatime"        # No access time updates
  "space_cache=v2" # Better space cache
  "discard=async"  # Async TRIM
];
```

### ZFS Record Sizes
- **16K**: Databases (PostgreSQL)
- **128K**: General server data, VMs
- **1M**: Large files, media

### Swap Size
Adjust based on RAM:
- 16GB RAM → 8GB swap
- 32GB RAM → 16GB swap
- 64GB+ RAM → 8GB swap (minimal)

## Security Notes

1. **LUKS passwords:** 
   - Use strong passwords (20+ characters)
   - Consider using SOPS with clan for encrypted storage
   - Never commit `/tmp/secret.key` to git

2. **ZFS encryption:**
   - Already have LUKS, second layer is optional
   - If using ZFS encryption, passwords needed on every import

3. **Backup your data:**
   - Disko is **destructive** - it wipes the disk
   - Always backup before installation

## References

- [Disko Documentation](https://github.com/nix-community/disko)
- [NixOS Impermanence](https://github.com/nix-community/impermanence)
- [ZFS on NixOS](https://nixos.wiki/wiki/ZFS)
- [Clan Core](https://docs.clan.lol)
