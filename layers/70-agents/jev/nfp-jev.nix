# Tier: 53-tools
# Module: nfp-jev.nix
# Purpose: Unified CLI & TUI control plane for Jev System-1 decision workflows.
# Option Path: layers.layer-50.cli.nfp-jev
# Enabling Host Tags: workstation, homelab, ai-agent
# RAM Footprint: minimal (<30MB)
{
  pkgs,
  ...
}:
let
  nfpJevBin = pkgs.writeShellScriptBin "nfp-jev" ''
    exec ${pkgs.python3}/bin/python3 ${./nfp-jev.py} "$@"
  '';
in
{
  environment.systemPackages = [ nfpJevBin ];
}
