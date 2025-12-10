# Templates and Image Generation Guide

This directory contains templates for creating various types of NixOS configurations and images.

## Templates

### 1. Machine Template (`templates/machine/`)

Full-featured machine configuration with all Grandlix-Gang options exposed.

**Use cases:**
- New physical machines
- New laptops/desktops
- Servers

**Quick start:**
```bash
cp -r templates/machine machines/mynewmachine
cd machines/mynewmachine
# Edit default.nix with your settings
# Generate hardware config during installation
```

See [machine/README.md](machine/README.md) for detailed instructions.

### 2. VM Template (`templates/vm/`)

Optimized for virtual machines with guest tools and testing features.

**Use cases:**
- Testing configurations
- Development environments
- Temporary instances

**Build:**
```bash
# Using nixos-generators
nix build .#vm

# Or build a test VM from a machine config
nixos-rebuild build-vm --flake .#luffy
./result/bin/run-luffy-vm
```

### 3. ISO Template (`templates/iso/`)

Live bootable ISO with installer and demo environment.

**Use cases:**
- Installation media
- Recovery systems
- Live demonstrations

**Build:**
```bash
nix build .#iso
# ISO will be in result/iso/
```

### 4. Container Template (`templates/container/`)

Minimal container image for Docker/Podman.

**Use cases:**
- Microservices
- CI/CD containers
- Development containers

**Build and run:**
```bash
# Build Docker image
nix build .#docker
docker load < result

# Or use with podman
podman load < result
```

## Available Image Formats

Using `nixos-generators`, we support multiple output formats:

```bash
# Virtual Machine Formats
nix build .#vm           # QEMU qcow2
nix build .#vmware       # VMware VMDK
nix build .#virtualbox   # VirtualBox VDI

# Container Formats
nix build .#docker       # Docker image
nix build .#lxc          # LXC container

# Cloud Formats
nix build .#amazon       # Amazon EC2 AMI

# Installation Media
nix build .#iso          # Live ISO
```

## Integration with Clan

Clan-core provides additional tools for machine management:

### Install a New Machine

```bash
# 1. Create machine from template
cp -r templates/machine machines/newserver

# 2. Edit machines/newserver/default.nix
# 3. Add to clan.nix inventory

# 4. Install to target machine
clan machines install newserver
```

### Generate Facts (Hardware Detection)

```bash
# Automatically detect and configure hardware
clan facts generate machinename
```

### Deploy to Existing Machine

```bash
# Deploy configuration updates
clan machines update machinename

# Or deploy all machines
clan machines update --all
```

### Build for Multiple Machines

```bash
# Build specific machine
nix build .#nixosConfigurations.luffy.config.system.build.toplevel

# Build all machines
nix build .#clanInternals.all.machinesConfig
```

## Customization

### Creating Custom Image Template

1. Create a new directory in `templates/`
2. Add `default.nix` with your configuration
3. Add to `flake.nix` perSystem.packages:

```nix
my-custom-image = inputs.nixos-generators.nixosGenerate {
  inherit system;
  specialArgs = {inherit inputs;};
  modules = [
    ./templates/my-custom/default.nix
  ];
  format = "iso";  # or "docker", "vm", etc.
};
```

### Available nixos-generators Formats

- `amazon` - Amazon EC2 AMI
- `azure` - Azure image
- `do` - DigitalOcean
- `docker` - Docker container
- `gce` - Google Compute Engine
- `hyperv` - Hyper-V
- `install-iso` - Installer ISO
- `iso` - Live ISO
- `kexec` - kexec tarball
- `lxc` - LXC container
- `lxc-metadata` - LXC metadata
- `openstack` - OpenStack image
- `proxmox` - Proxmox VE
- `qcow` - QEMU qcow2
- `raw` - Raw disk image
- `raw-efi` - Raw EFI disk image
- `vagrant-virtualbox` - Vagrant VirtualBox
- `virtualbox` - VirtualBox
- `vm` - QEMU VM
- `vmware` - VMware

## Best Practices

### For Machines
- Always use the machine template as a starting point
- Generate hardware config on the target machine
- Use descriptive hostnames
- Tag machines appropriately in clan inventory
- Test with VMs before deploying to physical hardware

### For Images
- Keep ISO images minimal unless for demos
- Use container images for specific services
- Test images in their target environment
- Document any special configuration in image templates

### For Development
- Use VMs for testing changes
- Build and test in `dev shell` environment
- Use `nix flake check` before deploying
- Keep templates updated with new features

## Troubleshooting

### Build Failures

```bash
# Check flake
nix flake check

# Show detailed error trace
nix build .#iso --show-trace

# Update flake inputs
nix flake update
```

### VM Issues

```bash
# Rebuild with more memory
nixos-rebuild build-vm --flake .#machinename
# Edit the resulting script to increase RAM if needed
```

### ISO Boot Issues

- Verify UEFI/BIOS boot settings
- Check ISO integrity with SHA256
- Try different USB creation tools (dd, Etcher, Ventoy)

### Container Issues

```bash
# Verify image loaded
docker images

# Check container logs
docker logs container-name

# Enter container for debugging
docker run -it image-name /bin/bash
```

## Examples

### Create a Gaming Machine

```bash
cp -r templates/machine machines/gaming-rig
# Edit machines/gaming-rig/default.nix:
# - Set hostname
# - Enable gaming.enable = true
# - Choose desktop environment
# Add to clan.nix and deploy
```

### Create a Home Server

```bash
cp -r templates/machine machines/homeserver
# Edit machines/homeserver/default.nix:
# - Enable services.nextcloud-server.enable = true
# - Enable services.home-assistant-server.enable = true
# - Enable services.immich-server.enable = true
# Add to clan.nix and deploy
```

### Create a Development Container

```bash
nix build .#docker
docker load < result
docker run -it grandlix-container
# Or customize templates/container/default.nix first
```

## Resources

- [NixOS Generators Documentation](https://github.com/nix-community/nixos-generators)
- [Clan-core Documentation](https://docs.clan.lol)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Flake Parts Documentation](https://flake.parts)
