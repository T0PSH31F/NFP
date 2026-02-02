{
  pkgs,
  ...
}:

{
  home.pointerCursor = {
    package = pkgs.callPackage ../../../pkgs/sonic-cursor.nix { };
    name = "Sonic-cursor-hyprcursor";
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
      "XCURSOR_THEME,Sonic-cursor-hyprcursor"
      "XCURSOR_SIZE,32"
      "HYPRCURSOR_THEME,Sonic-cursor-hyprcursor"
      "HYPRCURSOR_SIZE,32"
    ];

    exec-once = [
      "hyprctl setcursor Sonic-cursor-hyprcursor 32"
    ];
  };

  # Ensure cursor theme is available to all applications
  home.sessionVariables = {
    XCURSOR_THEME = "Sonic-cursor-hyprcursor";
    XCURSOR_SIZE = "32";
  };
}
