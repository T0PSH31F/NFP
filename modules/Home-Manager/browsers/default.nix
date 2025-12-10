{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./firefox.nix
    ./qutebrowser.nix
  ];
  # Browser-related packages
  home.packages = with pkgs; [
    # Browser extensions and tools
    actiona # automation tool
    ariang # aria2 web ui
    autobrr # torrent tracker
    bombadillo # gopher, gemini, finger browser
    brave # chromium based
    browserpass # Pass integration
    browsh # vim like cmd line browser
    clouddrive2 # google drive client
    code-server # web based code editor
    deluge # torrent client
    deluged # torrent daemon
    dillo-plus # web browser
    floorp-bin # web browser
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
    qutebrowser # web browser
    shadowfox # firefox based
    spacedrive # spacedrive
    tootik # tootkit
    tor # tor browser
    tor-browser # tor browser
    torrentstream # torrent stream
    tractor # torrent tracker
    varia # torrent tracker
    vivaldi # chromium based
    # castor
    # lagrange
    # ncgopher
    # Alternative frontends
    # libredirect # Redirect to privacy-friendly frontends
  ];
}
