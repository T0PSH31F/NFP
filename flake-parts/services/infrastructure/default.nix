# flake-parts/services/infrastructure/default.nix
# Infrastructure and system services
{
  imports = [
    ./caddy.nix
    ./home-assistant.nix
    ./n8n.nix
    ./nextcloud.nix
    ./harmonia.nix
    ./monitoring.nix
    ./homepage-dashboard.nix
    ./adguard.nix
    ./searxng.nix
    ./pastebin.nix
    ./avahi.nix
    ./ssh-agent.nix
    ./extras.nix
  ];
}
