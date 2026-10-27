{
  osConfig ? config,
  config,
  lib,
  ...
}:
let
  cfg = osConfig.layers.layer-40.desktop.noctalia;
in
{
  config =
    lib.mkIf (cfg.enable && (cfg.backend == "niri" || cfg.backend == "both" || cfg.backend == "all"))
      {
        # uwsm environment variables for Niri (compositor-specific)
        xdg.configFile."uwsm/env-niri".text = ''
          export XDG_CURRENT_DESKTOP=niri
          export XDG_SESSION_TYPE=wayland
          export XDG_SESSION_DESKTOP=niri
          export ELECTRON_OZONE_PLATFORM_HINT=auto
        '';

        # Common Wayland toolkit env (mkDefault so hyprland's version wins in "both" mode)
        xdg.configFile."uwsm/env".text = lib.mkDefault ''
          export GDK_BACKEND=wayland,x11,*
          export QT_QPA_PLATFORM="wayland;xcb"
          export SDL_VIDEODRIVER=wayland
          export CLUTTER_BACKEND=wayland
          export QT_AUTO_SCREEN_SCALE_FACTOR=1
          export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
          export QT_QPA_PLATFORMTHEME_QT6=qt6ct
          export QT_QPA_PLATFORMTHEME=qt6ct
          export MOZ_ENABLE_WAYLAND=1
          export NIXOS_OZONE_WL=1
          export QT_MEDIA_BACKEND=gstreamer
          export ELECTRON_OZONE_PLATFORM_HINT=auto
        '';

        # Desktop Entry for UWSM managed Niri session
        home.file.".local/share/wayland-sessions/niri-uwsm.desktop".text = ''
          [Desktop Entry]
          Name=Niri (UWSM)
          Comment=Niri compositor managed by UWSM
          Exec=uwsm start -F -- niri --session
          DesktopNames=niri
          Type=Application
        '';
      };
}
