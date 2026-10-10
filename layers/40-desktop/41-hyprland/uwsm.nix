{
  osConfig ? config,
  config,
  lib,
  ...
}:
let
  cfg = osConfig.layers.layer-40.desktop.hyprland;
in
{
  config = lib.mkIf cfg.enable {
    # uwsm environment variables
    # Reference: https://wiki.hypr.land/Configuring/Environment-variables/
    xdg.configFile."uwsm/env".text = ''
      export GDK_BACKEND=wayland,x11,*
      export QT_QPA_PLATFORM="wayland;xcb"
      export SDL_VIDEODRIVER=wayland
      export CLUTTER_BACKEND=wayland
      export XDG_CURRENT_DESKTOP=Hyprland
      export XDG_SESSION_TYPE=wayland
      export XDG_SESSION_DESKTOP=Hyprland
      export QT_AUTO_SCREEN_SCALE_FACTOR=1
      export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
      export QT_QPA_PLATFORMTHEME_QT6=qt6ct
      export QT_QPA_PLATFORMTHEME=qt6ct
      export MOZ_ENABLE_WAYLAND=1
      export NIXOS_OZONE_WL=1
      export QT_MEDIA_BACKEND=gstreamer

      export ELECTRON_OZONE_PLATFORM_HINT=auto
    ''
    + lib.optionalString cfg.isNvidia ''

      # NVIDIA Specific
      export NVD_BACKEND=direct
      export LIBVA_DRIVER_NAME=nvidia
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
    '';

    xdg.configFile."uwsm/env-hyprland".text = ''
      export HYPRCURSOR_THEME=Sonic-Hyprcursor
      export HYPRCURSOR_SIZE=${toString osConfig.layers.layer-30.theming.cursor.size}
      export XCURSOR_THEME=Sonic-Hyprcursor
      export XCURSOR_SIZE=${toString osConfig.layers.layer-30.theming.cursor.size}
      export _JAVA_AWT_WM_NONREPARENTING=1
    '';
  };
}
