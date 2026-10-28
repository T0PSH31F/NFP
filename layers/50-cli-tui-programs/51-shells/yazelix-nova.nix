# Tier: 50-cli-tui-programs / 51-shells
# Module: yazelix-nova.nix
# Purpose: Yazelix Nova flake workspace integration via Home Manager module.
# Option Path: layers.layer-50.cli.yazelix-nova
# Enabling Host Tags: desktop, workstation, development
{
  config,
  lib,
  pkgs,
  inputs ? { },
  ...
}:
let
  yazelixPkg =
    if
      inputs ? yazelix
      && inputs.yazelix ? packages
      && inputs.yazelix.packages ? ${pkgs.stdenv.hostPlatform.system}
    then
      inputs.yazelix.packages.${pkgs.stdenv.hostPlatform.system}.yazelix-no-rio
        or inputs.yazelix.packages.${pkgs.stdenv.hostPlatform.system}.default
    else
      null;

  # Wrapper script to launch Yazelix smoothly inside a designated terminal
  yazelix-launcher = pkgs.writeShellScriptBin "yazelix-workspace" ''
    if command -v yzx >/dev/null 2>&1; then
      exec yzx enter --session yazelix "$@"
    elif [ -n "${yazelixPkg}" ] && [ -x "${yazelixPkg}/bin/yzx" ]; then
      exec ${yazelixPkg}/bin/yzx enter --session yazelix "$@"
    else
      echo "Yazelix Nova (yzx) binary not found." >&2
      exit 1
    fi
  '';
in
{
  options.layers.layer-50.cli.yazelix-nova = {
    enable = lib.mkEnableOption "Yazelix Nova shell & workspace manager";
  };

  config = lib.mkIf config.layers.layer-50.cli.yazelix-nova.enable {
    environment.systemPackages = lib.optionals (yazelixPkg != null) [
      yazelixPkg
      yazelix-launcher
    ];
  };

  home =
    { osConfig, ... }:
    {
      config = lib.mkIf (osConfig.layers.layer-50.cli.yazelix-nova.enable or false) {
        home.packages = lib.optionals (yazelixPkg != null) [
          yazelixPkg
          yazelix-launcher
        ];
      };
    };
}
