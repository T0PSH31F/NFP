{
  config,
  lib,
  pkgs,
  ...
}:
let
  hasTag = tag: builtins.elem tag (config.machine.tags or [ ]);
in
{
  config = lib.mkMerge [
    # Common Intel & GPU settings
    (lib.mkIf (hasTag "intel-9th-gen" || hasTag "intel-12th-gen" || hasTag "intel-13th-gen") {
      boot.kernelModules = [ "kvm-intel" ];
      hardware.enableRedistributableFirmware = true;
      hardware.graphics = {
        enable = true;
        extraPackages = with pkgs; [
          libva-vdpau-driver
          libvdpau-va-gl
        ];
      };
    })

    # i7-9700F (9th gen Coffee Lake) - luffy
    (lib.mkIf (hasTag "intel-9th-gen") {
      hardware.graphics.extraPackages = with pkgs; [
        intel-vaapi-driver # i965 driver
      ];

      # TLP for server/workstation stability on older chips
      services.tlp.enable = lib.mkDefault true;
      services.power-profiles-daemon.enable = lib.mkDefault false;
    })

    # i7-1260P (12th gen Alder Lake) - z0r0
    (lib.mkIf (hasTag "intel-12th-gen") {
      boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
      boot.initrd.kernelModules = [ "i915" ];

      hardware.graphics.extraPackages = with pkgs; [
        intel-media-driver # iHD driver
        intel-compute-runtime
        intel-ocl
      ];

      # Modern power management for hybrid architectures
      services = {
        power-profiles-daemon.enable = lib.mkDefault true;
        thermald.enable = lib.mkForce false; # Often fails on 12th gen laptops
        hardware.bolt.enable = true;
      };
    })

    # i7-13850HX (13th gen Raptor Lake) - sanji
    (lib.mkIf (hasTag "intel-13th-gen") {
      boot.initrd.kernelModules = [ "i915" ];

      hardware.graphics.extraPackages = with pkgs; [
        intel-media-driver # iHD driver
        intel-compute-runtime
        intel-ocl
        vpl-gpu-rt # Intel Quick Sync / VPL runtime
      ];

      # Modern power management for hybrid architectures
      services = {
        power-profiles-daemon.enable = lib.mkDefault true;
        thermald.enable = lib.mkForce false;
        hardware.bolt.enable = true;
      };
    })
  ];
}
