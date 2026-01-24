{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Thunar File Manager
  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-archive-plugin
      thunar-volman
      thunar-media-tags-plugin
    ];
  };

  # Services needed for file managers
  services.gvfs.enable = true; # Mount, trash, and other functionalities
  services.tumbler.enable = true; # Thumbnail support

  environment.systemPackages = with pkgs; [
    # Nemo File Manager (Cinnamon)
    nemo-with-extensions
    nemo-fileroller

    calibre
    cosmic-files
    koreader
    openbooks
    readest
    epy
    glow
    lf
    yazi
    fff
    librum
    superfile
    spacedrive
    # Dolphin File Manager (KDE)
    kdePackages.dolphin
    kdePackages.dolphin-plugins
    kdePackages.kio-extras # Extra protocols support
    kdePackages.kio-admin # Admin support

    # File Roller (Archive Manager for Nemo/Thunar)
    file-roller
  ];
}
