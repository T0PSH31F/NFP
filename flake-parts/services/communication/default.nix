# flake-parts/services/communication/default.nix
# Communication and collaboration services
{
  imports = [
    ./matrix.nix
    ./mautrix.nix
    ./your-spotify.nix
    ./karakeep.nix
  ];
}
