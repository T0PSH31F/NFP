# network-router — Network control-plane services
# Always-on machines that provide network infrastructure:
# Homepage dashboard, Headscale VPN control server, Tailscale coordination.
{ config, lib, ... }:
{
  config = lib.mkIf (lib.elem "network-router" config.machine.tags) {
    services.headscale-server.enable = lib.mkDefault true;
    services.caddy-server.enable = lib.mkDefault true;
    layers.layer-20.services.config = {
      homepage-dashboard.enable = lib.mkDefault true;
      fleet-healthcheck.enable = lib.mkDefault true;
      tailscale.enable = lib.mkDefault true;
    };
  };
}
