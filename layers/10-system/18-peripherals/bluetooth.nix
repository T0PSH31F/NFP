{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.layers.layer-10.system.peripherals.bluetooth;
in
{
  config = lib.mkIf cfg.enable {
    # Enable Bluetooth
    hardware.bluetooth = {
      enable = lib.mkDefault true;
      powerOnBoot = lib.mkDefault true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          Experimental = true;
        };
        Policy = {
          AutoEnable = true;
        };
      };
    };

    # Bluetooth services
    services = {
      blueman.enable = true;

      # Prevent Bluetooth USB controllers from auto-suspending (turning off on idle)
      udev.extraRules = ''
        # Disable USB autosuspend for Bluetooth controllers
        ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{bDeviceClass}=="e0", ATTR{bDeviceSubClass}=="01", ATTR{bDeviceProtocol}=="01", ATTR{power/control}="on"
        ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ENV{ID_USB_INTERFACES}=="*:e00101:*", ATTR{power/control}="on"
        ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_interface", DRIVERS=="btusb", RUN+="/bin/sh -c 'echo on > /sys$env{DEVPATH}/../power/control'"
      '';

      # Prevent TLP from turning off bluetooth on boot or when switching power sources
      tlp.settings = lib.mkIf (config.services.tlp.enable or false) {
        DEVICES_TO_DISABLE_ON_STARTUP = "none";
        DEVICES_TO_DISABLE_ON_BAT_NOT_IN_USE = "none";
        DEVICES_TO_DISABLE_ON_LAN_CONNECT = "none";
        DEVICES_TO_DISABLE_ON_WIFI_CONNECT = "none";
        DEVICES_TO_DISABLE_ON_WWAN_CONNECT = "none";
        DEVICES_TO_ENABLE_ON_STARTUP = "bluetooth";
        DEVICES_TO_ENABLE_ON_AC = "bluetooth";
        DEVICES_TO_ENABLE_ON_BAT = "bluetooth";
        USB_EXCLUDE_BTUSB = 1;
      };
    };

    # Bluetooth packages
    environment.systemPackages = with pkgs; [
      bluez
      bluez-tools
      blueman
      bluetuith
    ];

    # Auto-connect trusted Bluetooth devices on boot
    # Iterates through trusted devices and connects each one
    systemd.user.services.bluetooth-auto-connect = {
      description = "Auto-connect Bluetooth devices";
      after = [ "bluetooth.service" ];
      partOf = [ "bluetooth.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart =
          let
            autoConnectScript = pkgs.writeShellScript "bluetooth-auto-connect" ''
              set -euo pipefail
              # Get all trusted Bluetooth devices and connect each
              ${pkgs.bluez}/bin/bluetoothctl devices Trusted | while read -r _ mac name; do
                echo "Connecting to $name ($mac)..."
                ${pkgs.coreutils}/bin/timeout 10 ${pkgs.bluez}/bin/bluetoothctl connect "$mac" 2>/dev/null || true
              done
            '';
          in
          "${autoConnectScript}";
        RemainAfterExit = true;
      };
      wantedBy = [ "default.target" ];
    };
  };
}
