{ config, lib, pkgs, ... }:

with lib;

{
  options.hardware.touchpad.enable = mkEnableOption "Enhanced touchpad support";

  config = mkIf config.hardware.touchpad.enable {
    # Touchpad support via libinput
    services.libinput = {
      enable = true;
      touchpad = {
        tapping = true;
        tappingDragLock = true;
        naturalScrolling = true;
        scrollMethod = "twofinger";
        disableWhileTyping = true;
        middleEmulation = true;
        accelProfile = "adaptive";
      };
    };

    # Synaptics touchpad (alternative, disabled by default)
    services.xserver.synaptics = {
      enable = false;
      twoFingerScroll = true;
      palmDetect = true;
      tapButtons = true;
      buttonsMap = [ 1 3 2 ];
      fingersMap = [ 0 0 0 ];
    };

    # Touchpad packages
    environment.systemPackages = with pkgs; [
      libinput
      xinput
      xorg.xf86inputlibinput
    ];

    # Touchpad gesture support
    services.touchegg = {
      enable = false; # Disabled by default, enable if needed
    };
  };
}