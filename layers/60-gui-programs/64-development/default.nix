{ lib, mkDendriticModule, ... }:
{
  imports = [
    (mkDendriticModule "dev-tools" ./dev-tools.nix)
    (mkDendriticModule "vscode" ./vscode.nix)
    (mkDendriticModule "gedit" ./gedit.nix)
  ];
}
