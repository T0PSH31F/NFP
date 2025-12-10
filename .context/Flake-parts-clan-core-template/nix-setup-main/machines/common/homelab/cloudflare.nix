{
  config,
  pkgs,
  ...
}: {
  # Cloudflare tunnel configuration
  sops.secrets.cloudflare_tunnel_credentials = {};

  services.cloudflared = {
    enable = true;
    tunnels = {
      # TODO: Fill in tunnel UUID and configuration
      "4cc24480-547c-4c48-8eb0-9a0a786fbe35" = {
        credentialsFile = config.sops.secrets.cloudflare_tunnel_credentials.path;
        default = "http_status:404";
      };
    };
  };

  # Firewall rules for cloudflared
  networking.firewall.allowedTCPPorts = [
    # Add any additional ports needed for tunnel
  ];
}
