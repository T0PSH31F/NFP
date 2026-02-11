# Grandlix-Gang Templates Directory

This directory contains blueprints for different types of NixOS configurations. Each template is designed to be copied and customized.

## 📋 Template Overview

| Template | Purpose | Use Case |
| :--- | :--- | :--- |
| [`machine/`](machine/) | **Full Machine** | Laptops, Desktops, Servers, Raspberry Pis |
| [`iso/`](iso/) | **Live Media** | USB installers, Recovery, Live demonstrations |
| [`vm/`](vm/) | **Test Environment** | Testing configs without real hardware |
| [`container/`](container/) | **Deployment** | Docker/Podman microservices |
| [`disko/`](disko/) | **Disk Layouts** | Partitioning schemes for Btrfs, ZFS, or Ext4 |

---

## 🚀 How to use each template

### 🖥️ New Machine Template
Ideal for adding a permanent device to your fleet.
*   **Action**: `cp -r templates/machine machines/my-new-rig`
*   **Guide**: See [Machine Setup Guide](machine/README.md) for step-by-step instructions.

### 💿 ISO Template
Creates a bootable image named **"Going-Merry"** by default.
*   **Action**: Modify `templates/iso/default.nix` if you want a custom pre-installed environment.
*   **Build**: `nix build .#packages.x86_64-linux.iso`
*   **Result**: Check `result/iso/Going-Merry.iso`

### 💻 VM Template
Quickly test your configuration in QEMU.
*   **Action**: `cp -r templates/vm machines/test-vm`
*   **Build**: `nixos-rebuild build-vm --flake .#test-vm`
*   **Run**: `./result/bin/run-test-vm-vm`

### 📦 Container Template
Package a NixOS setup as a Docker/Podman image.
*   **Build**: `nix build .#packages.x86_64-linux.docker`
*   **Run**: `docker load < result && docker run -it grandlix-container`

---

## 📐 The "Grandlix" Pattern

All templates follow the **Dendritic Registry** pattern:
1.  **Imports**: We import high-level feature bundles from `flake-parts/`.
2.  **Toggles**: We use simple boolean toggles (`enable = true`) to activate complex feature sets.
3.  **Tags**: We use Clan tags to categorize machines, which drives automatic service discovery and configuration.

## 🛠️ Global Build Commands

```bash
# Build the default installer ISO (Going-Merry)
nix build .#iso

# Build a machine configuration locally
nix build .#nixosConfigurations.z0r0.config.system.build.toplevel

# Deploy all updates across the network
clan machines update --all
```
