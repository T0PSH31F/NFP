{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  options.virtualization = {
    enable = mkEnableOption "Virtualization support (QEMU/KVM, Docker, Podman)";
  };

  config = mkIf config.virtualization.enable {
    programs.extra-container = {
      enable = true;
    };
    # Enable virtualization
    virtualisation = {
      # Enable libvirtd for QEMU/KVM
      libvirtd = {
        enable = true;
        qemu = {
          package = pkgs.qemu_kvm;
          swtpm.enable = true;
          runAsRoot = false;
        };
      };

      # Docker configuration
      docker = {
        enable = true;
        enableOnBoot = true;
        autoPrune = {
          enable = true;
          dates = "weekly";
        };
      };

      # Podman configuration (rootless container engine)
      podman = {
        enable = true;
        defaultNetwork.settings.dns_enabled = true;
        autoPrune = {
          enable = true;
          dates = "weekly";
        };
      };
    };

    # Install virtualization tools
    environment.systemPackages = with pkgs; [
      # QEMU and related tools
      qemu
      quickemu
      quickgui

      # VM management
      virt-manager
      virt-viewer
      spice
      spice-gtk
      spice-protocol
      virtio-win
      win-spice

      # Container tools
      docker-compose
      podman-compose
      distrobox

      # Bridge utilities
      bridge-utils

      # OCI tools
      buildah
      skopeo
      nixos-shell
    ];
  };
}
