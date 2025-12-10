{
  config,
  lib,
  ...
}: {
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

        # Documents
        "application/pdf" = ["org.pwmt.zathura.desktop"];

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
        "text/html" = ["firefox.desktop"];
        "x-scheme-handler/http" = ["firefox.desktop"];
        "x-scheme-handler/https" = ["firefox.desktop"];
      };
    };
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
