{ lib, ... }:
{
  imports = [
    ../../layers/10-system/12-processor/default.nix
    ../../layers/10-system/12-processor/12.4-platform/laptop.nix
  ];

  # Intel 13th Gen Raptor Lake i7-13850HX
  boot = {
    kernelModules = [ "kvm-intel" ];
    initrd = {
      availableKernelModules = [
        "vmd"
        "xhci_pci"
        "thunderbolt"
        "nvme"
        "usb_storage"
        "sd_mod"
        "rtsx_pci_sdmmc"
      ];
      luks.devices."crypted" = {
        device = "/dev/disk/by-partlabel/cryptroot";
        allowDiscards = true;
        bypassWorkqueues = true;
      };
    };
    kernelParams = [ "systemd.gpt_auto=0" ];
  };

  # Filesystems (btrfs subvolumes with zstd compression)
  fileSystems = {
    "/" = {
      device = "/dev/mapper/crypted";
      fsType = "btrfs";
      options = [
        "subvol=@root"
        "compress=zstd"
        "noatime"
      ];
    };
    "/var/log" = {
      device = "/dev/mapper/crypted";
      fsType = "btrfs";
      options = [
        "subvol=@log"
        "compress=zstd"
        "noatime"
      ];
    };
    "/nix" = {
      device = "/dev/mapper/crypted";
      fsType = "btrfs";
      options = [
        "subvol=@nix"
        "compress=zstd"
        "noatime"
      ];
    };
    "/persist" = {
      device = "/dev/mapper/crypted";
      fsType = "btrfs";
      options = [
        "subvol=@persist"
        "compress=zstd"
        "noatime"
      ];
      neededForBoot = true;
    };
    "/backup" = {
      device = "/dev/mapper/crypted";
      fsType = "btrfs";
      options = [
        "subvol=@backup"
        "compress=zstd"
        "noatime"
      ];
    };
    "/home" = {
      device = "/dev/mapper/crypted";
      fsType = "btrfs";
      options = [
        "subvol=@home"
        "compress=zstd"
        "noatime"
      ];
      neededForBoot = true;
    };
    "/boot" = {
      device = "/dev/disk/by-partlabel/ESP";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
  };

  # Swap Configuration (32GB backing disk swap beneath zram)
  swapDevices = [
    {
      device = "/persist/swapfile";
      priority = 10;
    }
  ];

  hardware.cpu.intel.updateMicrocode = lib.mkDefault true;
  nixpkgs.hostPlatform = "x86_64-linux";
}
