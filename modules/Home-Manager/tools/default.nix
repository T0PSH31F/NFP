{ pkgs, inputs, ... }:
{
  imports = [
    inputs.vicinae.homeManagerModules.default
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
