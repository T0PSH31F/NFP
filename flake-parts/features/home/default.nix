# flake-parts/features/home/default.nix
# Home Manager feature toggles - user-level tools and applications
{
  imports = [
    ./cli
    ./core.nix
    ./desktop
    ./documents/default.nix
    ./dev-tools.nix
    ./gaming-apps.nix
    ./pentest-tools.nix
    ./spicetify.nix
    ./vscode.nix
  ];
}
