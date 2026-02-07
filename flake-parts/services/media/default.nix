# flake-parts/services/media/default.nix
# Media server and library management services
{
  imports = [
    ./media-stack.nix
    ./calibre-web.nix
    ./immich.nix
    ./komga.nix
  ];
}
