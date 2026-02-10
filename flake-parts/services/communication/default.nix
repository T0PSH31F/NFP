# flake-parts/services/communication/default.nix
# Communication and collaboration services
{
  imports = [
    ./karakeep.nix
    ./matrix.nix
    ./mautrix.nix
    ./your-spotify.nix
  ];
}
