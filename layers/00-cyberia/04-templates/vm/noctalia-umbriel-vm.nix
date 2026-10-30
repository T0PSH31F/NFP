{
  pkgs,
  config,
  inputs,
  modulesPath,
  ...
}:
{
  imports = [
    "${modulesPath}/virtualisation/qemu-vm.nix"
    inputs.home-manager.nixosModules.home-manager
    inputs.nixos-passthru-cache.nixosModules.nixos-passthru-cache
    ../../../10-system/13-users/hm-catalog.nix
    ../../../10-system/11-foundation
    ../../../30-environments
    ../../../40-desktop
  ];

  networking.hostName = "noctalia-umbriel-vm";

  virtualisation = {
    memorySize = 4096;
    cores = 4;
    graphics = true;
    resolution = {
      x = 1920;
      y = 1080;
    };
    qemu.options = [
      "-vga virtio"
      "-display gtk"
      "-serial stdio"
    ];
  };

  machine.tags = [
    "desktop"
    "vm"
  ];

  layers.desktop = {
    enable = true;
    experience = "noctalia-umbriel";
  };

  hardware.graphics.enable = true;

  systemd = {
    settings.Manager = {
      DefaultEnvironment = "WLR_RENDERER_ALLOW_SOFTWARE=1 WLR_NO_HARDWARE_CURSORS=1 LIBGL_ALWAYS_SOFTWARE=1";
    };
    user.settings.Manager = {
      DefaultEnvironment = "WLR_RENDERER_ALLOW_SOFTWARE=1 WLR_NO_HARDWARE_CURSORS=1 LIBGL_ALWAYS_SOFTWARE=1";
    };
    services.greetd.environment = {
      WLR_RENDERER_ALLOW_SOFTWARE = "1";
      WLR_NO_HARDWARE_CURSORS = "1";
      LIBGL_ALWAYS_SOFTWARE = "1";
    };
  };

  environment.sessionVariables = {
    WLR_RENDERER_ALLOW_SOFTWARE = "1";
    WLR_NO_HARDWARE_CURSORS = "1";
    LIBGL_ALWAYS_SOFTWARE = "1";
  };

  services = {
    qemuGuest.enable = true;
    spice-vdagentd.enable = true;
    greetd = {
      enable = true;
      settings = {
        initial_session = {
          command = "${pkgs.writeShellScript "launch-umbriel-session" ''
            export WLR_RENDERER_ALLOW_SOFTWARE=1
            export WLR_NO_HARDWARE_CURSORS=1
            export LIBGL_ALWAYS_SOFTWARE=1
            export XDG_CURRENT_DESKTOP=Umbriel
            export XDG_SESSION_DESKTOP=Umbriel
            export XDG_SESSION_TYPE=wayland
            exec ${pkgs.dbus}/bin/dbus-run-session ${config.layers.desktop.compositors.umbriel.package}/bin/umbriel
          ''}";
          user = "t0psh31f";
        };
      };
    };
  };

  users.users.t0psh31f = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "video"
      "input"
      "audio"
    ];
    initialPassword = "nixos";
  };

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
    ghostty
    kitty
    fastfetch
    pciutils
  ];

  system.stateVersion = "26.05";
}
