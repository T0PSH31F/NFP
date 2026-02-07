{ config, lib, pkgs, ... }:

with lib;

{
  options.hardware.bluetooth.enhanced.enable = mkEnableOption "Enhanced Bluetooth support";

  config = mkIf config.hardware.bluetooth.enhanced.enable {
    # Enable Bluetooth
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          Experimental = true;
        };
      };
    };

    # Bluetooth services
    services.blueman.enable = true;

    # Bluetooth packages
    environment.systemPackages = with pkgs; [
      bluez
      bluez-tools
      blueman
      bluetuith
    ];

    # Auto-connect trusted devices
    systemd.user.services.bluetooth-auto-connect = {
      description = "Auto-connect Bluetooth devices";
      after = [ "bluetooth.service" ];
      partOf = [ "bluetooth.service" ];
      serviceConfig = {
        Type = "forking";
        ExecStart = "${pkgs.bluez}/bin/bluetoothctl connect-all";
        RemainAfterExit = true;
      };
      wantedBy = [ "default.target" ];
    };
  };
}