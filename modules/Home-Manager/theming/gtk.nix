{ pkgs, ... }:
{
  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.callPackage ../../../pkgs/sonic-cursor.nix { };
    name = "Sonic-cursor-hyprcursor";
    size = 36;
    hyprcursor = {
      enable = true;
      size = 36;
    };
  };

  gtk = {
    enable = true;
    cursorTheme = {
      package = pkgs.callPackage ../../../pkgs/sonic-cursor.nix { };
      name = "Sonic-cursor-hyprcursor";
      size = 36;
    };
  };
}
