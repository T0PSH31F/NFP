{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Browsers
    firefox
    chromium

    # Communication
    thunderbird

    # File managers
    nautilus

    # Media players
    vlc
    mpv

    # Image viewers/editors
    gimp
    inkscape

    # Office suite
    libreoffice-fresh

    # PDF viewers
    evince
    zathura

    # Screenshot tools
    flameshot

    # Terminal emulators (if not using Ghostty exclusively)
    alacritty
    kitty
  ];
}
