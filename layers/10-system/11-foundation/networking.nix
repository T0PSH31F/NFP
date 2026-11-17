{
  lib,
  ...
}:
{
  networking = {
    networkmanager.enable = true;

    # Prefer IPv4 over IPv6 when dual-stack is present to avoid blackhole timeouts
    getaddrinfo.enable = true;
    getaddrinfo.precedence = {
      "::ffff:0:0/96" = 100;
    };

    # Fleet DNS: AdGuard Home primary with Cloudflare fallback
    nameservers = [
      "192.168.1.54"
      "1.1.1.1"
      "1.0.0.1"
    ];

    # Unified Master Fleet Firewall Configuration
    firewall = {
      enable = true;

      # Strictly limit globally-open TCP ports to HTTP/HTTPS for Caddy;
      # SSH, DNS, databases, AI services, and admin panels are reachable only
      # over trusted Tailscale (tailscale0 / 100.64.0.0/10) and LAN (192.168.1.0/24).
      allowedTCPPorts = [
        80 # HTTP (ACME / TLS redirect)
        443 # HTTPS (Caddy + Authentik SSO reverse proxy)
      ];

      allowedUDPPorts = [
        # 53 DNS not globally open — restricted to LAN/Tailnet/localhost via extraInputRules + trustedInterfaces
        67 # DHCP
        443 # QUIC / HTTP/3
        5353 # mDNS / Avahi
        # 51820 # WireGuard VPN
        # 9993 # ZeroTier VPN
      ];

      # Allow full access on trusted internal VPN and container interfaces
      trustedInterfaces = [
        "tailscale0" # Tailscale VPN mesh
        "podman0" # Podman container bridge
      ];

      allowPing = true;
      logRefusedConnections = false;

      # Allow full traffic from trusted LAN subnet + Tailnet CIDR (Phase 4 firewall)
      # DNS (53) only reachable from LAN, Tailnet (tailscale0 trustedInterface), and localhost — never WAN.
      extraInputRules = ''
        ip saddr 192.168.1.0/24 accept
        ip saddr 100.64.0.0/10 accept
      '';
    };
  };

  # OpenSSH Server Configuration (key-only authentication across fleet)
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = lib.mkForce false;
      KbdInteractiveAuthentication = lib.mkForce false;
      PermitRootLogin = lib.mkForce "prohibit-password";
      X11Forwarding = false;
      MaxAuthTries = 3;
    };
  };
}
