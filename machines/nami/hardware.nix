# machines/nami/hardware.nix
# Hardware-specific configuration for Nami
# Intel i7-7560U, Iris Plus Graphics 640, 16GB RAM, 477GB NVMe
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
    ./disko.nix
  ];

  # Boot configuration
  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # Platform
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
