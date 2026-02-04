{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Load hardware tools if 'desktop' or 'laptop' tag is present, or just generic hardware support
  config = lib.mkIf (config.clan.lib.hasTags [ "desktop" ] || config.clan.lib.hasTag "laptop") {
    environment.systemPackages = with pkgs; [
      logitech-udev-rules
      solaar
    ];

    # Enable hardware services if needed
    # services.solaar.enable = true; # Option does not exist? Use hardware.logitech.wireless.enable?
  };
}
