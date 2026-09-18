{
  config,
  lib,
  ...
}:
{
  networking = {
    networkmanager.enable = true;

    # Fleet DNS: AdGuard Home primary with Cloudflare fallback
    nameservers = [
      "192.168.1.54"
      "1.1.1.1"
      "1.0.0.1"
    ];

    # Unified Master Fleet Firewall Configuration
    firewall = {
      enable = true;

      # Master Fleet Port List (z0r0 & luffy) — DNS never WAN-exposed.
      # Per Phase 4: DNS (53) only from LAN 192.168.1.0/24,
      # Tailnet 100.64.0.0/10 (via trustedInterfaces tailscale0), and localhost.
      # No global exposure of DNS port.
      allowedTCPPorts = [
        22 # SSH Access
        80 # HTTP
        389 # Vaultwarden LDAP
        443 # HTTPS
        1337 # Jan AI
        2019 # Caddy Admin API
        3000 # Hermes Workspace
        3001 # HedgeDoc
        3002 # AdGuard Web
        3003 # FreeLLMAPI
        3005 # Langfuse
        3006 # AionUI
        3007 # N8N Primary Web
        3008 # Grafana Observability
        3099 # Mission Control
        3100 # Loki
        3101 # Paperclip
        3333 # Mistral MCP
        3457 # YourSpotify
        5000 # Harmonia Nix Cache
        5050 # Kavita
        5432 # PostgreSQL
        5678 # N8N Webhook
        5680 # OpenCompany UI
        5681 # OpenCompany Backend
        6080 # Camofox VNC
        6333 # Qdrant HTTP API
        6334 # Qdrant gRPC
        6380 # Nextcloud
        6767 # Bazarr
        6800 # Aria2
        7878 # Radarr
        8000 # SillyTavern
        8004 # ChromaDB
        8008 # Matrix Synapse
        8010 # Brain Service
        8080 # Signal CLI
        8081 # SABnzbd (usenet) / LocalAI reserve
        8082 # Homepage Dashboard
        8083 # FreeLLMPool
        8084 # Paperless-ngx
        8085 # Hermes Agent Gateway
        8086 # Headscale
        8087 # Mealie
        8088 # Open WebUI
        8089 # Filebrowser
        8090 # Kong Gateway (proxy)
        8091 # Kong Admin API
        7777 # Polyfloor API
        7119 # CalibreWeb
        8095 # qBittorrent WebUI
        8096 # Jellyfin
        8443 # HTTPS Alt 1 / Nginx SSL
        8444 # Element Web
        8686 # Lidarr
        8787 # Readarr
        8788 # Hermes WebUI
        8880 # Hermes Live Voice
        8888 # SearXNG
        8989 # Sonarr
        9090 # Prometheus
        9100 # Glances Node Exporter
        9119 # Hermes Dashboard
        9377 # Camofox Browser
        9696 # Prowlarr
        11434 # Ollama
        25600 # Komga
        29317 # Mautrix WhatsApp
        29318 # Mautrix Signal
        32768 # Spacedrive
        32784 # MaxKB
        32790 # SimStudio
        # 51820 # WireGuard VPN
        # 9993 # ZeroTier VPN
        61208 # Glances Web Stats
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

  # OpenSSH Server Configuration
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = lib.mkForce true;
      PermitRootLogin = "yes";
    };
  };
}
