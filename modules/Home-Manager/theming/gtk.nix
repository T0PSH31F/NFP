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

    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };

    iconTheme = {
      name = "BeautyLine";
      package = pkgs.beauty-line-icon-theme;
    };

    font = {
      name = "Inter";
      package = pkgs.google-fonts;
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };

  # Ensure packages are installed
  home.packages = with pkgs; [
    adw-gtk3
    beauty-line-icon-theme
    libsForQt5.qt5ct
    libsForQt5.qtstyleplugin-kvantum
  ];
}
