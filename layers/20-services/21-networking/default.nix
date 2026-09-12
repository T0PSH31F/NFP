{ ... }:
{
  imports = [
    ./adguard.nix
    ./avahi.nix
    ./caddy.nix
    ./endpoints.nix
    ./gateway.nix
    ./headscale.nix
    ./ssh-agent.nix
    ./tailscale.nix
    ./nfp-services.nix
  ];
}
