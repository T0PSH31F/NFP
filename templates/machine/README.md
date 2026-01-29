# Machine Template README

## Creating a New Machine

### Step 1: Copy the Template
```bash
cp -r templates/machine machines/newmachine
cd machines/newmachine
```

### Step 2: Generate Hardware Configuration

For a physical machine or during installation:
```bash
nixos-generate-config --root /mnt --show-hardware-config > hardware-configuration.nix
```

Or use clan's facter (if the machine is already running NixOS):
```bash
clan facts generate newmachine
```

### Step 3: Edit Configuration

Edit `default.nix`:
1. Change `networking.hostName` to your machine name
2. Choose your desktop environment
3. Enable desired services and features
4. Update user imports if needed

### Step 4: Add to Clan Inventory

Edit `clan.nix` at the root of the repository:

```nix
{
  inventory = {
    machines = {
      # ... existing machines ...
      newmachine = {
        tags = ["client" "desktop"];  # or ["server"], etc.
        deploy.targetHost = "root@192.168.1.XXX";
      };
    };
  };

  machines = {
    # ... existing machines ...
    newmachine = {...}: {
      imports = [./machines/newmachine/default.nix];
    };
  };
}
```

### Step 5: Build and Deploy

Test build:
```bash
nix build .#nixosConfigurations.newmachine.config.system.build.toplevel
```

Build VM for testing:
```bash
nixos-rebuild build-vm --flake .#newmachine
./result/bin/run-newmachine-vm
```

Deploy to target machine:
```bash
clan machines install newmachine
```

Or traditional nixos-rebuild:
```bash
nixos-rebuild switch --flake .#newmachine --target-host root@targethost
```

## Configuration Options

All options are documented in `default.nix` with inline comments. Major categories:

- **Desktop Environment**: Choose between Omarchy, Caelestia, or illogical-impulse
- **Gaming**: Steam, Proton, emulators, performance tools
- **AI Services**: PostgreSQL, Open WebUI, Qdrant, ChromaDB, LocalAI
- **Web Services**: Nextcloud, Caddy, Home Assistant, Calibre-Web
- **Communication**: Matrix, Mautrix bridges (10 platforms), Immich
- **System Compatibility**: AppImage, Flatpak
- **Themes**: SDDM Lain, GRUB Lain, Plymouth Matrix

## Tags Reference

Common tags for machines:
- `client` - Desktop/laptop for end-user
- `server` - Server machine
- `laptop` - Portable device
- `desktop` - Stationary workstation
- `vm` - Virtual machine
- `container` - Container instance
