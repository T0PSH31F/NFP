{ pkgs, ... }:
{
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "nfp-check" (builtins.readFile ./nfp-check.sh))
    (pkgs.writeShellScriptBin "fs-diff" (builtins.readFile ./fs-diff.sh))
    (pkgs.writeShellScriptBin "clan-validate" (builtins.readFile ./clan-validate.sh))
    (pkgs.writeShellScriptBin "setup-persistence" (builtins.readFile ./setup-persistence.sh))
    (pkgs.writeShellScriptBin "validate-impermanence" (builtins.readFile ./validate-impermanence.sh))
  ];
}
