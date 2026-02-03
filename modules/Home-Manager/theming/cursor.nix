{
  pkgs,
  ...
}:

{
  home.pointerCursor = {
    package = pkgs.sonic-cursor;
    name = "Sonic";
    size = 32;
    gtk.enable = true;
    x11.enable = true;
    hyprcursor = {
      enable = true;
      size = 32;
    };
  };

  # Hyprland-specific cursor configuration
  wayland.windowManager.hyprland.settings = {
    env = [
      "XCURSOR_THEME,Sonic"
      "XCURSOR_SIZE,32"
      "HYPRCURSOR_THEME,Sonic"
      "HYPRCURSOR_SIZE,32"
    ];

    exec-once = [
      "hyprctl setcursor Sonic 32"
    ];
  };

  # Manual symlinks for Hyprcursor (ensures directory structure is recognized)
  home.file.".local/share/hyprcursor/themes/Sonic".source =
    "${pkgs.sonic-cursor}/share/hyprcursor/themes/Sonic";

  # Ensure cursor theme is available to all applications
  home.sessionVariables = {
    XCURSOR_THEME = "Sonic";
    HYPRCURSOR_THEME = "Sonic";
  };
}
