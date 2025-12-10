# Quick Reference: Templates & Images

## Creating a New Machine

```bash
# 1. Copy template
cp -r templates/machine machines/newmachine

# 2. Edit configuration
vim machines/newmachine/default.nix
# - Change hostname
# - Enable desired features
# - Choose desktop environment

# 3. Add to clan.nix
# Add machine to inventory.machines and machines sections

# 4. Build and test
nix build .#nixosConfigurations.newmachine.config.system.build.toplevel

# 5. Deploy
clan machines install newmachine
```

## Building Images

```bash
# Live ISO (Installation media)
nix build .#iso
# Result: result/iso/nixos.iso

# QEMU VM
nix build .#vm
# Result: result/nixos.qcow2

# Docker Container
nix build .#docker
docker load < result

# VMware
nix build .#vmware

# VirtualBox  
nix build .#virtualbox

# Amazon EC2
nix build .#amazon

# LXC Container
nix build .#lxc
```

## Testing Configurations

```bash
# Build VM from machine config
nixos-rebuild build-vm --flake .#machinename
./result/bin/run-machinename-vm

# Check configuration
nix flake check

# Build specific machine
nix build .#nixosConfigurations.machinename.config.system.build.toplevel
```

## Clan Commands

```bash
# Install new machine
clan machines install machinename

# Update machine
clan machines update machinename

# Update all machines
clan machines update --all

# Generate hardware facts
clan facts generate machinename

# List machines
clan machines list
```

## Common Machine Configurations

### Minimal Desktop

```nix
{
  networking.hostName = "minimal";
  grandlix.desktop.illogical.enable = true;
  system.stateVersion = "25.05";
}
```

### Gaming Setup

```nix
{
  networking.hostName = "gaming-rig";
  grandlix.desktop.omarchy.enable = true;
  
  gaming = {
    enable = true;
    enableSteam = true;
    enableGamemode = true;
    enableEmulators = true;
  };
  
  system.stateVersion = "25.05";
}
```

### Home Server

```nix
{
  networking.hostName = "homeserver";
  
  services.nextcloud-server = {
    enable = true;
    hostName = "cloud.example.com";
  };
  
  services.home-assistant-server.enable = true;
  services.immich-server.enable = true;
  
  services.caddy-server = {
    enable = true;
    email = "admin@example.com";
  };
  
  system.stateVersion = "25.05";
}
```

### Matrix Communication Server

```nix
{
  networking.hostName = "matrix-server";
  
  services.matrix-server = {
    enable = true;
    serverName = "matrix.example.com";
    enableRegistration = false;
  };
  
  services.mautrix-bridges = {
    enable = true;
    homeserverDomain = "matrix.example.com";
    telegram.enable = true;
    whatsapp.enable = true;
    signal.enable = true;
  };
  
  system.stateVersion = "25.05";
}
```

### AI/ML Workstation

```nix
{
  networking.hostName = "ai-workstation";
  grandlix.desktop.omarchy.enable = true;
  
  services.ai-services = {
    enable = true;
    postgresql.enable = true;
    open-webui.enable = true;
    qdrant.enable = true;
    localai.enable = true;
  };
  
  system.stateVersion = "25.05";
}
```

## Directory Structure

```
templates/
├── README.md              # This file
├── QUICK-REFERENCE.md     # Quick reference
├── machine/               # Full machine template
│   ├── default.nix       # Configuration with all options
│   ├── hardware-configuration.nix
│   └── README.md
├── vm/                    # VM template
│   └── default.nix
├── iso/                   # Live ISO template
│   └── default.nix
└── container/             # Container template
    └── default.nix
```

## Available Toggles

All services and features can be enabled/disabled:

**Desktop**:
- `grandlix.desktop.omarchy.enable`
- `grandlix.desktop.caelestia.enable`
- `grandlix.desktop.illogical.enable`

**Gaming**:
- `gaming.enable`
- `gaming.enableSteam`
- `gaming.enableGamemode`
- `gaming.enableEmulators`

**AI Services**:
- `services.ai-services.enable`
- `services.ai-services.postgresql.enable`
- `services.ai-services.open-webui.enable`
- `services.ai-services.qdrant.enable`
- `services.ai-services.chromadb.enable`
- `services.ai-services.localai.enable`

**Web Services**:
- `services.nextcloud-server.enable`
- `services.caddy-server.enable`
- `services.home-assistant-server.enable`
- `services.calibre-web-app.enable`
- `services.sillytavern-app.enable`

**Communication**:
- `services.matrix-server.enable`
- `services.mautrix-bridges.enable`
- `services.mautrix-bridges.telegram.enable`
- `services.mautrix-bridges.whatsapp.enable`
- (... 8 more bridge toggles)
- `services.immich-server.enable`

**System**:
- `programs.appimage-support.enable`
- `services.flatpak-support.enable`

**Themes**:
- `themes.sddm-lain.enable`
- `themes.grub-lain.enable`
- `themes.plymouth-matrix.enable`

## Troubleshooting

**Build error**: `nix flake check --show-trace`  
**Update inputs**: `nix flake update`  
**Clean build**: `nix-collect-garbage -d && nix build ...`  
**Check logs**: `journalctl -xeu service-name`
