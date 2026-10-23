{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options.layers.layer-10.system.peripherals.touchpad.enable =
    mkEnableOption "Enhanced touchpad support";

  config = mkIf config.layers.layer-10.system.peripherals.touchpad.enable {
    # Touchpad packages
    environment.systemPackages = with pkgs; [
      libinput
      xinput
    ];

    # Services
    services = {
      # Touchpad support via libinput
      libinput = {
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
      xserver.synaptics = {
        enable = false;
        twoFingerScroll = true;
        palmDetect = true;
        tapButtons = true;
        buttonsMap = [
          1
          3
          2
        ];
        fingersMap = [
          0
          0
          0
        ];
      };

      # Touchpad gesture support
      touchegg = {
        enable = false; # Disabled by default, enable if needed
      };
    };
  };
}
