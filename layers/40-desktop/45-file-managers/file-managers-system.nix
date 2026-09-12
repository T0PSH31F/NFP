{
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
  services.gvfs.enable = true;
  services.tumbler.enable = true;
  services.gnome.gnome-online-accounts.enable = true;

  environment.systemPackages = with pkgs; [
    # Nemo File Manager (Cinnamon)
    nemo-with-extensions
    nemo-fileroller
    folder-color-switcher
    gnome-control-center
    # calibre
    # cosmic-files  # DROPPED: 2-day build blocker, not in any cache
    koreader
    openbooks
    readest
    epy
    glow
    iconic
    yazi
    librum
    superfile
    # spacedrive — refused to evaluate in this nixpkgs rev
    # Dolphin File Manager (KDE)
    kdePackages.dolphin
    kdePackages.dolphin-plugins
    kdePackages.kio-extras # Extra protocols support
    kdePackages.kio-admin # Admin support
  ];
}
