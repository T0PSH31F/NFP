# machines/z0r0/hardware.nix
# Hardware-specific configuration for z0r0
# - LUKS encryption
# - BTRFS filesystems and subvolumes
# - Swap configuration
{
  imports = [
    ../../flake-parts/hardware
    ../../flake-parts/hardware/laptop.nix
  ];

  # Boot configuration - LUKS encryption
  boot.initrd = {
    luks.devices."crypted".device = "/dev/disk/by-uuid/458b615c-3ac2-4cff-98a2-c8e266bae90f";
  };

  # Filesystems (btrfs subvolumes)
  fileSystems."/" = {
    device = "/dev/mapper/crypted";
    fsType = "btrfs";
    options = [ "subvol=@root" ];
  };

  fileSystems."/var/log" = {
    device = "/dev/mapper/crypted";
    fsType = "btrfs";
    options = [ "subvol=@log" ];
  };

  fileSystems."/nix" = {
    device = "/dev/mapper/crypted";
    fsType = "btrfs";
    options = [ "subvol=@nix" ];
  };

  fileSystems."/persist" = {
    device = "/dev/mapper/crypted";
    fsType = "btrfs";
    options = [ "subvol=@persist" ];
    neededForBoot = true;
  };

  fileSystems."/backup" = {
    device = "/dev/mapper/crypted";
    fsType = "btrfs";
    options = [ "subvol=@backup" ];
  };

  fileSystems."/home" = {
    device = "/dev/mapper/crypted";
    fsType = "btrfs";
    options = [ "subvol=@home" ];
    neededForBoot = true;
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/E6FA-59AC";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  # Swap Configuration
  swapDevices = [
    {
      device = "/persist/swapfile";
      size = 32768; # 32GB
    }
  ];

  # Keep this to prevent auto-detection of broken swap partitions
  boot.kernelParams = [ "systemd.swap=0" ];

  # Platform
  nixpkgs.hostPlatform = "x86_64-linux";
}
