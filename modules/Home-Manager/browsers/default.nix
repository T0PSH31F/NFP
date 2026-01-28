{
  pkgs,
  ...
}:
#with lib;
{
  #  options.browsers = {
  #    firefox.enable = mkEnableOption "Firefox browser";
  #    brave.enable = mkEnableOption "Brave browser";
  #    vivaldi.enable = mkEnableOption "Vivaldi browser";
  #    qutebrowser.enable = mkEnableOption "Qutebrowser";
  #
  #    # Default to enable all browsers
  #    enableAll = mkOption {
  #      type = types.bool;
  #      default = false;
  #      description = "Enable all browsers";
  #    };
  #  };

  imports = [
    ./firefox.nix
    ./qutebrowser.nix
  ];

  # config = mkMerge [
  #   # Firefox
  #   (mkIf (config.browsers.firefox.enable || config.browsers.enableAll) {
  #     home.packages = with pkgs; [
  #     ];
  #
  #     # Firefox policies for better defaults
  #     programs.firefox = {
  #       enable = true;
  #       };
  #     };
  #   })
  #
  #   # Brave
  #   (mkIf (config.browsers.brave.enable || config.browsers.enableAll) {
  #     home.packages = with pkgs; [
  #       brave
  #     ];
  #   })
  #
  #   # Vivaldi
  #   (mkIf (config.browsers.vivaldi.enable || config.browsers.enableAll) {
  #     home.packages = with pkgs; [
  #       vivaldi
  #       vivaldi-ffmpeg-codecs # Additional codec support
  #     ];
  #   })
  #
  #   # Qutebrowser
  #   (mkIf (config.browsers.qutebrowser.enable || config.browsers.enableAll) {
  #     home.packages = with pkgs; [
  #       qutebrowser
  #     ];
  #   })
  # ];

  # Additional browser-related utility packages
  home.packages = with pkgs; [
    actiona # automation tool
    ariang # aria2 web ui
    autobrr # torrent tracker
    brave
    bombadillo # gopher, gemini, finger browser
    browserpass # Pass integration
    browsh # vim like cmd line browser
    clouddrive2 # google drive client
    code-server # web based code editor
    deluge # torrent client
    geopard # web browser
    google-authenticator # 2fa
    google-drive-ocamlfuse # google drive fuse
    headscale # tailscale web ui
    insync # google drive sync
    jackett # torrent tracker
    kristall # web browser
    media-downloader # media downloader
    mullvad-browser # mullvad browser
    nyaa # torrent tracker
    obfs4 # obfs4 proxy
    onedrive # one drive client
    popcorntime # watch movies
    protonvpn-gui # protonvpn gui
    quiet # vpn client
    shadowfox # firefox based
    spacedrive # spacedrive
    tootik # tootkit
    tor # tor browser
    tor-browser # tor browser
    torrentstream # torrent stream
    tractor # torrent tracker
    varia # torrent tracker
    vivaldi
    vivaldi-ffmpeg-codecs
  ];
}
