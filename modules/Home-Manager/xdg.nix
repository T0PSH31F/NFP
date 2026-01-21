{
  config,
  lib,
  pkgs,
  ...
}: {
  # Ensure desktop-file-utils is available for updating the desktop database
  home.packages = with pkgs; [
    desktop-file-utils
    shared-mime-info
  ];

  # Note: XDG_DATA_DIRS is handled by xdg.systemDirs.data below

  xdg.configFile."uwsm/env".source = "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh"; 

  xdg = {
    enable = true;
    mime.enable = true;
    mimeApps = {
      enable = true;
      defaultApplications = {
        # Text files
        "text/plain" = ["ghostty.desktop"];
        "text/markdown" = ["ghostty.desktop"];
        "text/x-python" = ["ghostty.desktop"];
        "text/x-c" = ["ghostty.desktop"];
        "text/x-c++" = ["ghostty.desktop"];
        "text/x-java" = ["ghostty.desktop"];
        "text/x-javascript" = ["ghostty.desktop"];
        "text/x-rust" = ["ghostty.desktop"];

        # Documents & eBooks
        "application/pdf" = ["org.pwmt.zathura.desktop"];
        "application/msword" = ["libreoffice.desktop"];
        "application/vnd.ms-excel" = ["libreoffice.desktop"];
        "application/vnd.ms-powerpoint" = ["libreoffice.desktop"];
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = ["libreoffice.desktop"];
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = ["libreoffice.desktop"];
        "application/vnd.openxmlformats-officedocument.presentationml.presentation" = ["libreoffice.desktop"];
        "application/rtf" = ["libreoffice.desktop"];
        "application/epub+zip" = ["librum.desktop"];
        "application/vnd.amazon.ebook" = ["librum.desktop"];
        "application/x-mobipocket-ebook" = ["librum.desktop"];

        # Media
        "image/jpeg" = ["swayimg.desktop"];
        "image/png" = ["swayimg.desktop"];
        "image/gif" = ["swayimg.desktop"];
        "image/webp" = ["swayimg.desktop"];
        "video/mp4" = ["mpv.desktop"];
        "video/webm" = ["mpv.desktop"];
        "video/x-matroska" = ["mpv.desktop"];
        "video/quicktime" = ["mpv.desktop"];

        # Web
        "text/html" = ["vivaldi.desktop"];
        "x-scheme-handler/http" = ["vivaldi.desktop"];
        "x-scheme-handler/https" = ["vivaldi.desktop"];

       
      };
    };
    # Ensure system applications directory is included
    systemDirs.data = [
      "/run/current-system/sw/share"
      "/nix/var/nix/profiles/default/share"
      "${config.home.profileDirectory}/share"
    ];
    userDirs = {
      enable = true;
      createDirectories = true;
      desktop = "$HOME/Desktop";
      documents = "$HOME/Documents";
      download = "$HOME/Downloads";
      music = "$HOME/Music";
      pictures = "$HOME/Pictures";
      publicShare = "$HOME/Public";
      templates = "$HOME/Templates";
      videos = "$HOME/Videos";
      extraConfig = {
        XDG_AGENTS_DIR = "$HOME/Agents";
        XDG_APPIMAGE_DIR = "$HOME/AppImages";
        XDG_CLAN_DIR = "$HOME/Clan";
        XDG_FLATPAK_DIR = "$HOME/Flatpaks";
        XDG_NIXOS_DIR = "$HOME/NixOS";
        XDG_PROJECTS_DIR = "$HOME/Projects";
        XDG_SCREENSHOTS_DIR = "$HOME/Pictures/screenshots";
      };
    };
  };
}
