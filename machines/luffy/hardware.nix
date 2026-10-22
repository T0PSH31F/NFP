{ lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Modules for Intel i7 9700F / Gigabyte B365M
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.kernel.sysctl = {
    "kernel.unprivileged_userns_clone" = 1;
  };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Boot configuration - LUKS encryption
  boot.initrd.luks.devices = {
    "crypted" = {
      device = "/dev/disk/by-uuid/c62695ca-f48c-4296-8e27-62f27a32c7e1";
      allowDiscards = true;
      bypassWorkqueues = true;
    };
  };

  # Stage 2 LUKS decryption for non-essential partitions using keyfiles
  environment.etc.crypttab = {
    mode = "0600";
    text = ''
      swap_crypted UUID=b0a3e560-5af1-4311-abd0-12e5e463812b /persist/secrets/swap.key discard,nofail
      luffy_storage UUID=1d5aefd2-bee6-47a3-b691-91d2794c5258 /persist/secrets/luffy_storage.key discard,nofail
    '';
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
    device = "/dev/disk/by-uuid/8F18-74D6";
    fsType = "vfat";
    options = [
      "defaults"
      "umask=0077"
    ];
  };

  # Samsung 860 EVO 250GB SSD - Extended Storage
  fileSystems."/storage" = {
    device = "/dev/mapper/luffy_storage";
    fsType = "btrfs";
    options = [
      "compress=zstd"
      "noatime"
      "nofail"
    ];
  };

  # Swap Configuration
  swapDevices = [
    {
      device = "/dev/mapper/swap_crypted";
      discardPolicy = "both";
      options = [ "nofail" ];
    }
  ];
  # Plain assignment, not lib.mkDefault: z0r0 sets it this way and evaluates
  # fine; with mkDefault the option was losing the merge and NixOS then failed
  # with "Neither nixpkgs.hostPlatform nor the legacy option nixpkgs.system has
  # been set" while evaluating bluetooth.nix.
  nixpkgs.hostPlatform = "x86_64-linux";
}
