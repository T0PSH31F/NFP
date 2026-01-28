{
  pkgs,
  ...
}:
{
  imports = [
    ./firefox.nix
    ./qutebrowser.nix
  ];

  # Core browsers for Noctalia keybinds
  # Super+W → Brave (default)
  # Super+Ctrl+W → Librewolf
  # Super+Shift+W → Mullvad
  # Super+Alt+W → Dillo+ (kristall)
  home.packages = with pkgs; [
    # Primary browsers (Noctalia keybinds)
    brave # Default browser
    librewolf # Privacy-focused Firefox fork
    mullvad-browser # Mullvad VPN browser
    
    # Alternative browsers
    kristall # Gemini browser (Dillo+ replacement)
    bombadillo # Gopher, Gemini, Finger browser
    
    # Privacy & Security
    tor # Tor daemon
    tor-browser # Tor browser
    google-authenticator # 2FA
    
    # Media & Downloads
    media-downloader # Media downloader
    popcorntime # Watch movies
    varia # Torrent tracker
    
    # Browser utilities
    browserpass # Pass integration
    
    # Keep Vivaldi
    vivaldi
    vivaldi-ffmpeg-codecs
  ];

  # Set Brave as default browser
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "brave-browser.desktop";
      "x-scheme-handler/http" = "brave-browser.desktop";
      "x-scheme-handler/https" = "brave-browser.desktop";
      "x-scheme-handler/about" = "brave-browser.desktop";
      "x-scheme-handler/unknown" = "brave-browser.desktop";
    };
  };
}
