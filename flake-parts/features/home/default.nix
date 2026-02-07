# flake-parts/features/home/default.nix
# Home Manager feature toggles - user-level tools and applications
{
  imports = [
    ./dev-tools.nix
    ./pentest-tools.nix
    ./gaming-apps.nix
    ./desktop
    ./core.nix
    ./shell.nix
    ./vscode.nix
    ./spicetify.nix
  ];
}
