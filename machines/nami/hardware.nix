# machines/nami/hardware.nix
# Hardware-specific configuration for Nami
# Intel i7-7560U, Iris Plus Graphics 640, 16GB RAM, 477GB NVMe
#
# IMPORTANT: After partitioning and before nixos-install, run:
#   nixos-generate-config --root /mnt --show-hardware-config
# and update UUIDs below to match your actual partition UUIDs.
{
  config,
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ../../flake-parts/hardware
    ../../flake-parts/hardware/intel-7th-gen.nix
  ];

  # Boot configuration
  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # ============================================================================
  # FILESYSTEMS - BTRFS subvolumes on NVMe
  # UUIDs are PLACEHOLDERS - update after partitioning with actual UUIDs
  # Use `blkid` to find them after formatting
  # ============================================================================

  fileSystems."/" = {
    device = "/dev/disk/by-label/NAMI_ROOT";
    fsType = "btrfs";
    options = [ "subvol=@root" "compress=zstd" "noatime" ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-label/NAMI_ROOT";
    fsType = "btrfs";
    options = [ "subvol=@home" "compress=zstd" "noatime" ];
    neededForBoot = true;
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-label/NAMI_ROOT";
    fsType = "btrfs";
    options = [ "subvol=@nix" "compress=zstd" "noatime" ];
  };

  fileSystems."/var/log" = {
    device = "/dev/disk/by-label/NAMI_ROOT";
    fsType = "btrfs";
    options = [ "subvol=@log" "compress=zstd" "noatime" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/NAMI_BOOT";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  # Swap - file-based on btrfs
  swapDevices = [
    {
      device = "/var/swapfile";
      size = 16384; # 16GB (matches RAM)
    }
  ];

  # Platform
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
