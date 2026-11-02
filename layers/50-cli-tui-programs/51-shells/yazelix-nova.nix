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
    YZX_BIN=""
    if command -v yzx >/dev/null 2>&1; then
      YZX_BIN="yzx"
    elif [ -n "${yazelixPkg}" ] && [ -x "${yazelixPkg}/bin/yzx" ]; then
      YZX_BIN="${yazelixPkg}/bin/yzx"
    else
      echo "Yazelix Nova (yzx) binary not found." >&2
      exit 1
    fi

    # Clean up any dead/exited 'yazelix' session so --session yazelix never fails,
    # or attach if a live 'yazelix' session is already running in the background.
    SESSION_STATE="$("$YZX_BIN" run yzx-zellij list-sessions --no-formatting 2>/dev/null | grep -E '^yazelix(\s|$)' || true)"
    if echo "$SESSION_STATE" | grep -q "EXITED"; then
      "$YZX_BIN" run yzx-zellij delete-session yazelix --force >/dev/null 2>&1 || true
    elif [ -n "$SESSION_STATE" ]; then
      exec "$YZX_BIN" enter attach yazelix
    fi

    exec "$YZX_BIN" enter --session yazelix "$@"
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
