# iOS Device Support (usbmuxd, ifuse, libimobiledevice)
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.layers.layer-10.system.mobile.ios;
in
{
  options.layers.layer-10.system.mobile.ios = {
    enable = lib.mkEnableOption "iOS device support (usbmuxd, ifuse)";
  };

  config = lib.mkIf cfg.enable {
    # Enable usbmuxd for USB multiplexing (required for iOS)
    services.usbmuxd.enable = true;

    programs.idescriptor.enable = true;

    environment.systemPackages = with pkgs; [
      libimobiledevice # Communicate with iOS devices
      libirecovery
      libusbmuxd
      usbmuxd2
      ipad_charge
      ifuse # Mount iOS filesystems
      ideviceinstaller # Manage apps
      # Debug WebKit on iOS
      # Upstream builds with `-Wall -Werror`, and GCC 16 promotes
      # -Wdiscarded-qualifiers to a hard error:
      #   ios_webkit_debug_proxy.c:1974: char *fext = strrchr(path, '.');
      #   -> "initialization discards 'const' qualifier from pointer target type"
      # Demote just that warning; NIX_CFLAGS_COMPILE is appended after the
      # package's own flags, so it wins over -Werror.
      (ios-webkit-debug-proxy.overrideAttrs (old: {
        NIX_CFLAGS_COMPILE = (old.NIX_CFLAGS_COMPILE or "") + " -Wno-error=discarded-qualifiers";
      }))
    ];
  };
}
