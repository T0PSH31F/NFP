{ mkDendriticModule, ... }:
{
  imports = [
    (mkDendriticModule "pentest-tools" ./pentest-tools.nix)
  ];
}
