# VM Configuration Template
#
# This creates a lightweight VM configuration suitable for:
# - Testing configurations
# - Development environments
# - Temporary instances
#
# Build with: nix build .#nixosConfigurations.vm-template.config.system.build.vm
# Or use nixos-generators: nix build .#images.vm-template
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ../../modules/system
    ../../modules/users/t0psh31f.nix
  ];

  # VM-optimized settings
  networking.hostName = "grandlix-vm";

  # Enable minimal desktop for GUI testing
  services.xserver = {
    enable = true;
    displayManager.lightdm.enable = true;
    desktopManager.xfce.enable = true;
  };

  # Or use one of our desktop environments
  # grandlix.desktop.illogical-impulse.enable = true;

  # Virtualization guest tools
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  # Shared folder support
  fileSystems."/mnt/shared" = {
    fsType = "9p";
    device = "shared";
    options = ["trans=virtio" "version=9p2000.L" "msize=104857600"];
  };

  # Enable SSH for remote access
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  # Faster boot in VMs
  boot.loader.timeout = 1;
  boot.loader.grub = {
    enable = true;
    device = "/dev/vda"; # For VirtIO disk
  };

  # Basic packages for testing
  environment.systemPackages = with pkgs; [
    vim
    git
    htop
    wget
    curl
  ];

  # Enable features you want to test
  gaming.enable = false;
  services.ai-services.enable = false;
  programs.appimage-support.enable = true;
  services.flatpak-support.enable = true;

  # Auto-login for easy testing (INSECURE - only for VMs!)
  services.displayManager.autoLogin = {
    enable = true;
    user = "t0psh31f";
  };

  system.stateVersion = "25.05";
}
