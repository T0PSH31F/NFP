{
  inputs,
  pkgs,
  config,
  ...
}:
{
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    devenv # devenv for dev environments
    desktop-file-utils # update-desktop-database
    shared-mime-info # update-mime-database
    xdg-utils # xdg-open & desktop chooser
    file-roller # archive manager for .zip, .rar, .tar, .7z, .gz
    fileinfo # file info tool
    file
    xorg-cf-files # Fixes for mime type resolution
    inputs.nixai.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      # Audio
      "audio/mpeg" = "mpv.desktop";
      "audio/mp3" = "mpv.desktop";
      "audio/x-mp3" = "mpv.desktop";
      "audio/flac" = "mpv.desktop";
      "audio/x-flac" = "mpv.desktop";
      "audio/wav" = "mpv.desktop";
      "audio/x-wav" = "mpv.desktop";
      "audio/ogg" = "mpv.desktop";
      "audio/opus" = "mpv.desktop";
      "audio/aac" = "mpv.desktop";
      "audio/m4a" = "mpv.desktop";
      "audio/x-m4a" = "mpv.desktop";
      "audio/mp4" = "mpv.desktop";
      "audio/x-matroska" = "mpv.desktop";
      # Video
      "video/mp4" = "mpv.desktop";
      "video/x-matroska" = "mpv.desktop";
      "video/webm" = "mpv.desktop";
      "video/avi" = "mpv.desktop";
      "video/quicktime" = "mpv.desktop";
      # Images
      "image/jpeg" = "mvi.desktop";
      "image/png" = "mvi.desktop";
      "image/gif" = "mvi.desktop";
      "image/webp" = "mvi.desktop";
      "image/svg+xml" = "mvi.desktop";
      # Archives
      "application/zip" = "org.gnome.FileRoller.desktop";
      "application/x-zip-compressed" = "org.gnome.FileRoller.desktop";
      "application/x-rar" = "org.gnome.FileRoller.desktop";
      "application/vnd.rar" = "org.gnome.FileRoller.desktop";
      "application/x-tar" = "org.gnome.FileRoller.desktop";
      "application/x-compressed-tar" = "org.gnome.FileRoller.desktop";
      "application/gzip" = "org.gnome.FileRoller.desktop";
      "application/x-gnutar" = "org.gnome.FileRoller.desktop";
      "application/x-7z-compressed" = "org.gnome.FileRoller.desktop";
      "application/x-xz" = "org.gnome.FileRoller.desktop";
      "application/x-xz-compressed-tar" = "org.gnome.FileRoller.desktop";
      "application/x-bzip2" = "org.gnome.FileRoller.desktop";
      "application/x-bzip-compressed-tar" = "org.gnome.FileRoller.desktop";
      # Executables & AppImages
      "application/x-ms-dos-executable" = "com.usebottles.bottles.desktop";
      "application/x-msi" = "com.usebottles.bottles.desktop";
      "application/x-msdownload" = "com.usebottles.bottles.desktop";
      "application/x-wine-extension-exe" = "com.usebottles.bottles.desktop";
      "application/x-dosexec" = "com.usebottles.bottles.desktop";
      "application/vnd.microsoft.portable-executable" = "com.usebottles.bottles.desktop";
      "application/x-iso9660-appimage" = "appimage-run.desktop";
      "application/x-appimage" = "appimage-run.desktop";
      "application/x-executable-appimage" = "appimage-run.desktop";
      # Android Packages (.apk)
      "application/vnd.android.package-archive" = "waydroid.desktop";
      # Documents & Web
      "application/pdf" = "org.pwmt.zathura.desktop";
      "application/epub+zip" = "org.pwmt.zathura.desktop";
      "application/x-mobipocket-ebook" = "org.pwmt.zathura.desktop";
      "application/x-mobi8-ebook" = "org.pwmt.zathura.desktop";
      "application/vnd.amazon.mobi8-ebook" = "org.pwmt.zathura.desktop";
      "application/x-azw" = "org.pwmt.zathura.desktop";
      "application/x-azw3" = "org.pwmt.zathura.desktop";
      "application/x-cbz" = "org.pwmt.zathura.desktop";
      "application/x-cbr" = "org.pwmt.zathura.desktop";
      "application/x-fictionbook+xml" = "org.pwmt.zathura.desktop";
      "text/plain" = "org.gnome.TextEditor.desktop";
      "text/markdown" = "org.gnome.TextEditor.desktop";
      "text/html" = "brave-browser.desktop";
      "application/xhtml+xml" = "brave-browser.desktop";
      "x-scheme-handler/http" = "brave-browser.desktop";
      "x-scheme-handler/https" = "brave-browser.desktop";
      "inode/directory" = "nemo.desktop";
    };
    associations.added = {
      "audio/mpeg" = [ "mpv.desktop" ];
      "audio/mp3" = [ "mpv.desktop" ];
      "audio/flac" = [ "mpv.desktop" ];
      "audio/wav" = [ "mpv.desktop" ];
      "audio/ogg" = [ "mpv.desktop" ];
      "audio/opus" = [ "mpv.desktop" ];
      "audio/m4a" = [ "mpv.desktop" ];
      "video/mp4" = [ "mpv.desktop" ];
      "video/x-matroska" = [ "mpv.desktop" ];
      "image/jpeg" = [
        "mvi.desktop"
        "feh.desktop"
      ];
      "image/png" = [
        "mvi.desktop"
        "feh.desktop"
      ];
      "application/zip" = [ "org.gnome.FileRoller.desktop" ];
      "application/x-rar" = [ "org.gnome.FileRoller.desktop" ];
      "application/x-tar" = [ "org.gnome.FileRoller.desktop" ];
      "application/x-7z-compressed" = [ "org.gnome.FileRoller.desktop" ];
      "application/gzip" = [ "org.gnome.FileRoller.desktop" ];
      "application/x-ms-dos-executable" = [
        "com.usebottles.bottles.desktop"
        "net.lutris.Lutris.desktop"
      ];
      "application/x-msi" = [ "com.usebottles.bottles.desktop" ];
      "application/x-iso9660-appimage" = [ "appimage-run.desktop" ];
      "application/x-appimage" = [ "appimage-run.desktop" ];
      "application/vnd.android.package-archive" = [ "waydroid.desktop" ];
      "application/pdf" = [
        "org.pwmt.zathura.desktop"
        "koreader.desktop"
      ];
      "application/epub+zip" = [
        "org.pwmt.zathura.desktop"
        "koreader.desktop"
      ];
      "application/x-mobipocket-ebook" = [
        "org.pwmt.zathura.desktop"
        "koreader.desktop"
      ];
      "application/x-mobi8-ebook" = [
        "org.pwmt.zathura.desktop"
        "koreader.desktop"
      ];
      "application/vnd.amazon.mobi8-ebook" = [
        "org.pwmt.zathura.desktop"
        "koreader.desktop"
      ];
      "application/x-azw" = [
        "org.pwmt.zathura.desktop"
        "koreader.desktop"
      ];
      "application/x-azw3" = [
        "org.pwmt.zathura.desktop"
        "koreader.desktop"
      ];
      "application/x-cbz" = [
        "org.pwmt.zathura.desktop"
        "koreader.desktop"
      ];
      "application/x-cbr" = [
        "org.pwmt.zathura.desktop"
        "koreader.desktop"
      ];
      "application/x-fictionbook+xml" = [
        "org.pwmt.zathura.desktop"
        "koreader.desktop"
      ];
      "text/plain" = [ "org.gnome.TextEditor.desktop" ];
      "text/markdown" = [ "org.gnome.TextEditor.desktop" ];
      "text/html" = [
        "brave-browser.desktop"
        "librewolf.desktop"
      ];
      "inode/directory" = [ "nemo.desktop" ];
    };
  };

  # Silence warnings by adopting new default behavior
  gtk.gtk4.theme = null;

  xdg = {
    enable = true;
    configFile."mimeapps.list".force = true;
    desktopEntries.appimage-run = {
      name = "AppImage Runner";
      comment = "Run AppImage files natively on NixOS";
      exec = "${pkgs.appimage-run}/bin/appimage-run %u";
      terminal = false;
      categories = [ "Utility" ];
      mimeType = [
        "application/x-iso9660-appimage"
        "application/x-appimage"
        "application/x-executable-appimage"
      ];
    };
    userDirs = {
      enable = true;
      setSessionVariables = true;
      createDirectories = true;
      desktop = "${config.home.homeDirectory}/Desktop";
      documents = "${config.home.homeDirectory}/Documents";
      download = "${config.home.homeDirectory}/Downloads";
      music = "${config.home.homeDirectory}/Music";
      pictures = "${config.home.homeDirectory}/Pictures";
      publicShare = null; # "${config.home.homeDirectory}/Public";
      templates = null; # "${config.home.homeDirectory}/Templates";
      videos = "${config.home.homeDirectory}/Videos";
      extraConfig = {
        PROJECTS = "${config.home.homeDirectory}/Projects";
        GAMES = "${config.home.homeDirectory}/Games";
        FLATPAKS = "${config.home.homeDirectory}/Flatpaks";
        APPIMAGES = "${config.home.homeDirectory}/Appimages";
        CLAN = "${config.home.homeDirectory}/Clan";
        ICONS = "${config.home.homeDirectory}/.icons";
        CURSORS = "${config.home.homeDirectory}/.cursors";
        THEMES = "${config.home.homeDirectory}/.themes";
        AGENTS = "${config.home.homeDirectory}/Agents";
      };
    };

    # Ensure base directories are defined (usually defaults are fine, but explicitly setting ensures consistency)
    configHome = "${config.home.homeDirectory}/.config";
    dataHome = "${config.home.homeDirectory}/.local/share";
    stateHome = "${config.home.homeDirectory}/.local/state";
    cacheHome = "${config.home.homeDirectory}/.cache";
  };
  # Custom user directories
  home = {
    preferXdgDirectories = true;
    file = {
      "Appimages/.keep".text = "";
      "Clan/.keep".text = "";
      "Flatpaks/.keep".text = "";
      "Games/.keep".text = "";
      "Projects/.keep".text = "";
      ".icons/.keep".text = "";
      ".cursors/.keep".text = "";
      ".themes/.keep".text = "";
    };
  };
}
