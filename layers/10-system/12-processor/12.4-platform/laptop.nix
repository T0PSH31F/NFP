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
  config = lib.mkIf (hasTag "laptop") {
    # Laptop-specific hardware configuration
    # Desktop environment setup is handled separately in flake-parts/desktop/

    # Power Management & Peripherals
    services = {
      power-profiles-daemon.enable = lib.mkDefault true;
      upower.enable = lib.mkDefault true;
      udev.extraRules = ''
        ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{class}=="0x0c0330", ATTR{power/control}="on"
        ACTION=="add", SUBSYSTEM=="typec", ATTR{power/control}="on"
      '';
      libinput = {
        enable = lib.mkDefault true;
        touchpad = {
          tapping = lib.mkDefault true;
          naturalScrolling = lib.mkDefault true;
        };
      };
    };

    # Prevent Intel Type-C / UCSI controller auto-suspend sleep lockups & extend timeouts
    boot.kernelParams = [ "typec_ucsi.cmd_timeout=5000" ];
    # Keyboard Backlight Control
    environment.systemPackages = [ pkgs.brightnessctl ];

    # Turn on keyboard backlight on boot
    systemd.services.keyboard-backlight = {
      description = "Turn on keyboard backlight";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.bash}/bin/bash -c 'echo 255 > /sys/class/leds/kbd_backlight/brightness || true'";
      };
    };
  };
}
