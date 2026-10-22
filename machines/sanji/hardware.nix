{ lib, ... }:
{
  imports = [
    ../../layers/10-system/12-processor/default.nix
    ../../layers/10-system/12-processor/12.4-platform/laptop.nix
  ];

  # Intel 13th Gen Raptor Lake i7-13850HX
  boot.kernelModules = [ "kvm-intel" ];

  # Initrd storage & bus drivers detected from Dell Precision 7680
  boot.initrd = {
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

  # Filesystems (btrfs subvolumes with zstd compression)
  fileSystems."/" = {
    device = "/dev/mapper/crypted";
    fsType = "btrfs";
    options = [
      "subvol=@root"
      "compress=zstd"
      "noatime"
    ];
  };

  fileSystems."/var/log" = {
    device = "/dev/mapper/crypted";
    fsType = "btrfs";
    options = [
      "subvol=@log"
      "compress=zstd"
      "noatime"
    ];
  };

  fileSystems."/nix" = {
    device = "/dev/mapper/crypted";
    fsType = "btrfs";
    options = [
      "subvol=@nix"
      "compress=zstd"
      "noatime"
    ];
  };

  fileSystems."/persist" = {
    device = "/dev/mapper/crypted";
    fsType = "btrfs";
    options = [
      "subvol=@persist"
      "compress=zstd"
      "noatime"
    ];
    neededForBoot = true;
  };

  fileSystems."/backup" = {
    device = "/dev/mapper/crypted";
    fsType = "btrfs";
    options = [
      "subvol=@backup"
      "compress=zstd"
      "noatime"
    ];
  };

  fileSystems."/home" = {
    device = "/dev/mapper/crypted";
    fsType = "btrfs";
    options = [
      "subvol=@home"
      "compress=zstd"
      "noatime"
    ];
    neededForBoot = true;
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-partlabel/ESP";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = [
    {
      device = "/persist/swapfile";
      size = 32768; # 32GB
    }
  ];

  boot.kernelParams = [ "systemd.gpt_auto=0" ];

  hardware.cpu.intel.updateMicrocode = lib.mkDefault true;
  nixpkgs.hostPlatform = "x86_64-linux";
}
