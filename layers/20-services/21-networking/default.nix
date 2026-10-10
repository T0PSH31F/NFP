{ ... }:
{
  imports = [
    ./adguard.nix
    ./avahi.nix
    ./caddy.nix
    ./endpoints.nix
    ./gateway.nix
    ./headplane.nix
    ./headscale.nix
    ./ssh-agent.nix
    ./tailscale.nix
    ./tailscale-sidecar.nix
    ./nfp-services.nix
  ];
}
