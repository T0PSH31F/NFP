# Tier: 70-agents/jev
# Purpose: Jev System-1 Decision Engine, LLM Router Hook, Daemons, Exporters, and CLI/TUI suites.
{ ... }:
{
  imports = [
    ./jev-engine.nix
    ./jev-router-plugin.nix
    ./jev-exporter.nix
    ./nfp-jev.nix
    ./nfp-book-tui.nix
    ./book-vault-purifier.nix
    ./fs-organizer-daemon.nix
    ./email-triage-daemon.nix
  ];
}
