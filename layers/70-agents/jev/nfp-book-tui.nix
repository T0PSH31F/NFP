# Tier: 53-tools
# Module: nfp-book-tui.nix
# Purpose: Interactive TUI review tool for E-Book Vault purification, covers, and RAG ingestion.
# Option Path: layers.layer-50.cli.nfp-book-tui
# Enabling Host Tags: workstation, homelab, storage
# RAM Footprint: minimal (<30MB)
{
  pkgs,
  ...
}:
let
  nfpBookTuiBin = pkgs.writeShellScriptBin "nfp-book-tui" ''
    exec ${pkgs.python3}/bin/python3 ${./nfp-book-tui.py} "$@"
  '';
in
{
  environment.systemPackages = [ nfpBookTuiBin ];
}
