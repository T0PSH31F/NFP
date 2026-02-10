{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.hardware.razer;
in
{
  options.hardware.razer = {
    enable = mkEnableOption "Razer peripheral support (OpenRazer)";

    user = mkOption {
      type = types.str;
      default = "t0psh31f";
      description = "User to add to openrazer group";
    };

    enablePolychromatic = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Polychromatic GUI for RGB control";
    };
  };

  config = mkIf cfg.enable {
    # Enable OpenRazer driver
    hardware.openrazer = {
      enable = true;
      # Allow user to control devices without root
      users = [ cfg.user ];
      # Enable device power management
      batteryNotifier.enable = true;
      # Sync effects across devices
      syncEffectsEnabled = true;
      # Enable device power management for battery savings
      devicesOffOnScreensaver = false;
    };

    # Install Razer control tools
    environment.systemPackages =
      with pkgs;
      [
        openrazer-daemon # Daemon for device communication
        razergenie # Qt-based configuration tool
        razer-cli # Command-line interface
      ]
      ++ lib.optionals cfg.enablePolychromatic [
        polychromatic # Full-featured GTK GUI
      ];

    # Ensure plugdev group exists (required for USB access)
    users.groups.plugdev = { };

    # Add user to required groups
    users.users.${cfg.user}.extraGroups = [
      "openrazer"
      "plugdev"
    ];

    # udev rules are automatically set up by hardware.openrazer
  };
}
