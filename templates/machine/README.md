# Machine Template Guide

This template is the primary way to add a new permanent machine (laptop, desktop, or server) to the Grandlix-Gang fleet.

## Quick Setup (5 Minutes)

### 1. Create Machine Directory
Choose a unique name for your machine (e.g., `sunny`, `GOING-MERRY`) and copy the template:
```bash
cp -r templates/machine machines/MY_MACHINE_NAME
cd machines/MY_MACHINE_NAME
```

### 2. Update Basic Config
Edit `default.nix`:
*   Change `networking.hostName = "CHANGEME";` to your actual machine name.
*   Configure your `clan.core.tags` (e.g., `["desktop" "laptop" "gaming"]`).
*   Toggle any specific features you want (e.g., `gaming.enable = true`).

### 3. Generate Hardware Info
If you are on the actual target machine:
```bash
nixos-generate-config --root /mnt --show-hardware-config > hardware-configuration.nix
```

### 4. Register in Clan Inventory
Edit `clan.nix` at the repository root:

1.  Add the machine to `inventory.machines`:
    ```nix
    inventory.machines.MY_MACHINE_NAME = {
      tags = [ "desktop" "laptop" ]; # Match what you put in default.nix
      deploy.targetHost = "root@MY_MACHINE_IP_OR_HOSTNAME";
    };
    ```

2.  Import the machine config in `machines`:
    ```nix
    machines.MY_MACHINE_NAME = {
      imports = [ ./machines/MY_MACHINE_NAME/default.nix ];
    };
    ```

## Post-Setup Actions

### Generate Variables (Sops/SSH)
```bash
clan vars generate MY_MACHINE_NAME
```

### Installation
If installing from an ISO:
```bash
# On your build machine
clan machines install MY_MACHINE_NAME --target-host root@ISO_IP
```

### Updates
```bash
clan machines update MY_MACHINE_NAME
```

## Advanced Customization

### The Dendritic Pattern
We use a nested attribute set pattern for toggling features.
*   `system-config.*` - High-level system behavior (like Impermanence).
*   `services-config.*` - Infrastructure bundles.
*   `services.ai-services.*` - Granular AI tool toggles.
*   `home-manager.users.t0psh31f.desktop.*` - User-space GUI toggles.

### Adding Machine-Specific Secrets
To add secrets just for this machine, create a `secrets.yaml` in your machine directory and ensure it's imported in your `default.nix` via `sops-nix`.

## Tags Cheat Sheet
*   `desktop`: Enables video drivers, Hyprland, fonts, and GUI apps.
*   `laptop`: Includes `desktop` + battery management and touchpad support.
*   `server`: Minimal headless setup with server-grade optimizations.
*   `ai-server`: Installs CUDA/ROCm and local LLM runners.
*   `gaming`: Sets up Steam, Proton-GE, and emulators.
*   `nvidia`: Triggers Nvidia proprietary driver installation.
