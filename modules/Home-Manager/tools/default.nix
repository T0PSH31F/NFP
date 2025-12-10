{pkgs, ...}: {
  imports = [
    ./lf.nix
    ./mcp.nix
    ./zathura.nix
    ./kanshi.nix
    ./btm.nix
    ./inlyne.nix
  ];
}
