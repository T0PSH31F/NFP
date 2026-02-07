{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Laptop-specific hardware configuration
  # Desktop environment setup is handled separately in flake-parts/desktop/

  # Power Management
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  # Touchpad support
  services.libinput.enable = true;
  services.libinput.touchpad.tapping = true;
  services.libinput.touchpad.naturalScrolling = true;
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
}
