{ config, lib, ... }:
with lib;
let
  cfg = config.layers.layer-20.services.config.gateway;
in
{
  options.layers.layer-20.services.config.gateway = {
    enable = mkEnableOption "VPN gateway (IP forwarding + NAT for VPN exit node traffic)";

    wanInterface = mkOption {
      type = types.str;
      default = "eth0";
      description = "WAN/interface facing the Spectrum router (for NAT masquerade)";
    };

    vpnInterfaces = mkOption {
      type = types.listOf types.str;
      default = [
        "tailscale0"
      ];
      description = "VPN interfaces to NAT and forward traffic from";
    };

    lanIp = mkOption {
      type = types.str;
      default = "192.168.1.54";
      description = "Luffy's static LAN IP (set IP reservation on Spectrum router to match)";
    };
  };

  config = mkIf cfg.enable {
    # Enable IP forwarding for VPN exit node functionality
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = mkDefault 1;
      "net.ipv6.conf.all.forwarding" = mkDefault 1;
    };

    # NAT for VPN traffic — allows VPN clients to route internet through luffy
    networking.nat = {
      enable = true;
      externalInterface = cfg.wanInterface;
      internalInterfaces = cfg.vpnInterfaces;
    };

    # Trust VPN interfaces so firewall allows forwarded traffic
    networking.firewall.trustedInterfaces = cfg.vpnInterfaces;
  };
}
