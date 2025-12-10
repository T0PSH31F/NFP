{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./desktop.nix # Laptops are desktops + power management
  ];

  # Power Management
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  # Touchpad support
  services.libinput.enable = true;
  services.libinput.touchpad.tapping = true;
  services.libinput.touchpad.naturalScrolling = true;
}
