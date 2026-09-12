# machines/z0r0/hardware.nix
# Hardware-specific configuration for z0r0
# - LUKS encryption
# - BTRFS filesystems and subvolumes
# - Swap configuration
{
  imports = [
    ../../layers/10-system/12-processor/default.nix
    ../../layers/10-system/12-processor/12.4-platform/laptop.nix
  ];

  boot.kernelModules = [ "lg-laptop" ];

  # Boot configuration - LUKS encryption
  boot.initrd = {
    availableKernelModules = [
      "xhci_pci"
      "thunderbolt"
      "vmd"
      "nvme"
      "usbhid"
      "usb_storage"
      "sd_mod"
    ];
    luks.devices."crypted" = {
      device = "/dev/disk/by-uuid/458b615c-3ac2-4cff-98a2-c8e266bae90f";
      allowDiscards = true;
      bypassWorkqueues = true;
    };
  };

  # Filesystems (btrfs subvolumes)
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
    device = "/dev/disk/by-uuid/3824-3E8C";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  # Swap Configuration
  swapDevices = [
    { device = "/dev/disk/by-uuid/f3b5cc40-4eaf-4f9e-a3e5-b2f2f43b4826"; }
    {
      device = "/persist/swapfile";
      size = 32768; # 32GB
    }
  ];

  # Use systemd.gpt_auto=0 instead of systemd.swap=0 to prevent auto-detection
  # of broken swap partitions without completely disabling fstab swap mounts.
  boot.kernelParams = [ "systemd.gpt_auto=0" ];

  # Platform
  nixpkgs.hostPlatform = "x86_64-linux";
}
