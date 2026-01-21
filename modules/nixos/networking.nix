{
  config,
  lib,
  ...
}: {
  networking = {
    networkmanager.enable = true;

    # Comprehensive firewall configuration for all services
    firewall = {
      enable = true;

      allowedTCPPorts = [
        # Web servers
        80 # HTTP
        443 # HTTPS

        # SSH
        22

        # AI Services (if enabled)
        5432 # PostgreSQL (AI services, Nextcloud, Matrix)
        6333 # Qdrant vector database
        6334 # Qdrant gRPC
        8000 # ChromaDB / SillyTavern
        8080 # Open WebUI
        8081 # LocalAI

        # Matrix Synapse
        8008 # Matrix client/federation
        8448 # Matrix federation (standard port)
        9000 # Matrix Prometheus metrics

        # Mautrix Bridges (native)
        29317 # Telegram bridge
        29318 # WhatsApp bridge
        29328 # Signal bridge

        # Mautrix Bridges (container-based)
        29319 # Facebook bridge
        29320 # Google Chat bridge
        29327 # Twitter bridge
        29330 # Instagram bridge
        29334 # Discord bridge
        29335 # Slack bridge
        29336 # Google Messages bridge

        # Home Assistant
        8123 # Home Assistant web interface

        # Nextcloud
        # (Uses 80/443 via Caddy/nginx)

        # Immich
        2283 # Immich web interface

        # Calibre-Web
        8083 # Calibre-Web

        # Steam Remote Play (gaming.nix)
        27036 # Steam Remote Play
        27037 # Steam Remote Play

        # Redis (various services)
        6379 # Redis
      ];

      allowedUDPPorts = [
        # QUIC for Caddy (HTTP/3)
        443

        # Steam Remote Play
        27031 # Steam Remote Play
        27036 # Steam Remote Play

        # mDNS / Avahi (for Home Assistant and other services)
        5353 # mDNS
      ];

      # Allow specific interfaces (e.g., Tailscale, Docker)
      trustedInterfaces = [
        "tailscale0" # Tailscale VPN
        "docker0" # Docker bridge
        "podman0" # Podman bridge
      ];

      # Allow loopback
      allowPing = true;

      # Log refused connections (useful for debugging)
      logRefusedConnections = false; # Set to true for debugging
    };
  };
  services.tailscale.enable = true;

  # SSH Server Configuration
  # Ensure host keys persist across reboots to prevent "host key changed" warnings
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = lib.mkDefault false;
      PermitRootLogin = lib.mkForce "yes"; # Force allow root login for clan deployments
    };
    # Explicitly define host keys to ensure they're generated in a persistent location
    # These paths are also persisted by impermanence module at /etc/ssh
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
      {
        path = "/etc/ssh/ssh_host_rsa_key";
        type = "rsa";
        bits = 4096;
      }
    ];
  };
}
