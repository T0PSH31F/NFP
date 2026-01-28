# Installing nami (Dell XPS 13)

Follow these steps to install NixOS on nami using the Grandlix-Gang configuration.

## Prerequisites
- A USB drive with the Grandlix-Gang ISO (see "Building the ISO" below).
- Internet connection (Wi-Fi or Ethernet).

## 1. Boot from ISO
1. Insert the USB drive into nami.
2. Power on and press `F12` (or your BIOS boot menu key) to select the USB drive.
3. Once booted, you will be in the Hyprland environment. Open a terminal (Ghostty).

## 1.5. Access the Configuration
The repository is already pre-bundled in the ISO!
1.  Open a terminal (Ghostty).
2.  The repository is located at: `/etc/Grandlix-Gang`
3.  Change to that directory: `cd /etc/Grandlix-Gang`

## 2. Disk Partitioning (Disko)
The system is configured with LUKS encryption and Btrfs subvolumes for impermanence.
Run the disko command that uses the pre-evaluated configuration from our flake:

```bash
# Ensure you are in the repo directory
cd /etc/Grandlix-Gang

# Run the evaluated disko script for nami
sudo nix run .#nixosConfigurations.nami.config.system.build.diskoScript
```

## 3. Generate Hardware Facts
Clan uses hardware facts for specific optimizations.
```bash
clan facts generate nami
```

## 4. Install
Run the installation command:
```bash
sudo nixos-install --flake .#nami
```

## 5. Post-Installation
1. Reboot the system.
2. Set your user password:
   ```bash
   sudo passwd t0psh31f
   ```

---

## Building the ISO
If you don't have the ISO yet, you can build it on another machine in the clan:
```bash
nix build .#iso
```
The resulting ISO will be in `./result/iso/`.
