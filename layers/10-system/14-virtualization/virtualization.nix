{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  options.layers.layer-10.system.virtualization = {
    enable = mkEnableOption "Virtualization support (QEMU/KVM, Docker, Podman)";
    waydroid.enable = mkEnableOption "Waydroid container support";
    user = mkOption {
      type = types.str;
      default = "t0psh31f";
      description = "Primary user to add to virtualization groups.";
    };
  };

  config = mkMerge [
    (mkIf config.layers.layer-10.system.virtualization.enable {
      programs = {
        extra-container.enable = true;
        # Ensure dconf is enabled for virt-manager to save settings
        dconf.enable = true;
      };

      # Add your user to the virtualization group
      users.users."${config.layers.layer-10.system.virtualization.user}".extraGroups = [
        "libvirtd"
        "kvm"
      ];

      # Enable IOMMU and nested virtualization for PCI/USB passthrough and VM performance
      boot = {
        kernelParams = [
          "iommu=pt"
        ]
        ++ lib.optional (
          builtins.elem "intel-9th-gen" (config.machine.tags or [ ])
          || builtins.elem "intel-12th-gen" (config.machine.tags or [ ])
          || builtins.elem "intel-13th-gen" (config.machine.tags or [ ])
        ) "intel_iommu=on"
        ++ lib.optional (builtins.elem "amd" (config.machine.tags or [ ])) "amd_iommu=on";

        extraModprobeConfig =
          ""
          + lib.optionalString (
            builtins.elem "intel-9th-gen" (config.machine.tags or [ ])
            || builtins.elem "intel-12th-gen" (config.machine.tags or [ ])
            || builtins.elem "intel-13th-gen" (config.machine.tags or [ ])
          ) "options kvm_intel nested=1\n"
          + lib.optionalString (builtins.elem "amd" (
            config.machine.tags or [ ]
          )) "options kvm_amd nested=1\n";
      };

      # Enable virtualization
      virtualisation = {
        # Enable libvirtd for QEMU/KVM
        libvirtd = {
          enable = true;
          qemu = {
            package = pkgs.qemu_kvm;
            swtpm.enable = true; # Required for Windows 11 TPM emulation
            runAsRoot = true; # Required for seamless USB passthrough
          };
        };

        # This enables the SPICE USB redirector daemon
        spiceUSBRedirection.enable = true;

        # Podman configuration (Docker replacement)
        podman = {
          enable = true;
          dockerCompat = true;
          dockerSocket.enable = true;
          defaultNetwork.settings.dns_enabled = true;
          autoPrune = {
            enable = true;
            dates = "weekly";
          };
        };

        oci-containers.backend = mkDefault "podman";
      };

      systemd.services.libvirtd = {
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          # libvirtd exits with status 1 after 120s idle timeout.
          # Socket activation restarts it on demand.
          SuccessExitStatus = "1";
        };
      };

      # The GUI to manage the VM
      programs.virt-manager.enable = true;

      # Install virtualization tools
      environment.systemPackages = with pkgs; [
        # Running android apps natively
        # android-translation-layer
        # QEMU and related tools
        qemu
        quickemu
        quickgui

        # VM management
        virt-viewer
        spice
        spice-gtk
        spice-protocol
        virtio-win
        win-spice

        # Container tools
        #podman-compose
        distrobox
        compose2nix

        # Bridge utilities
        bridge-utils

        # OCI tools
        buildah
        skopeo
        nixos-shell
      ];

      # Persistence for virtualization data
      environment.persistence."/persist" = mkIf config.layers.layer-10.system.config.impermanence.enable {
        directories = [
          "/var/lib/containers"
          "/var/lib/podman"
          "/var/lib/libvirt"
          "/etc/libvirt"
          "/var/lib/mongodb-container"
        ];
      };
    })

    (mkIf config.layers.layer-10.system.virtualization.waydroid.enable {
      virtualisation.waydroid.enable = true;

      # Note: Requires appropriate kernel modules (often compiled in Zen/CachyOS kernels)
      # Persistence for waydroid data
      environment.persistence."/persist" = mkIf config.layers.layer-10.system.config.impermanence.enable {
        directories = [
          "/var/lib/waydroid"
        ];
      };
    })
  ];
}
