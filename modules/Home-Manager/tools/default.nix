{ pkgs, ... }:
{
  imports = [
    ./lf.nix
    ./mcp.nix
    ./zathura.nix
    ./shikane.nix
    ./btm.nix
    ./inlyne.nix
    ./flameshot.nix
    ./keybinds.nix
  ];
}
