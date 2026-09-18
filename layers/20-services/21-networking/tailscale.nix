{
  config,
  lib,
  ...
}:
let
  cfg = config.layers.layer-20.services.config.tailscale;
in
{
  options.layers.layer-20.services.config.tailscale = {
    enable = lib.mkEnableOption "Tailscale client";
    loginServer = lib.mkOption {
      type = lib.types.str;
      default = "https://headscale.lovelain.duckdns.org";
      description = "Headscale login server URL for fleet-wide Tailscale authentication";
    };
    authKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to file containing Headscale pre-authenticated authkey";
    };
  };

  config = lib.mkIf cfg.enable (
    let
      # Tailnet DNS acceptance: all clients use MagicDNS + global AdGuard resolver.
      # luffy is the AdGuard host and must NOT accept its own pushed Tailnet DNS
      # to avoid recursive loop — it resolves via local AdGuard (127.0.0.1) with
      # bootstrap DNS (9.9.9.9 / 1.1.1.1) handling public upstream bootstrap.
      # This host-local escape is derived from hostname, not machine files, per
      # tag-role architecture (network-router vs pkb-node vs workstation).
      isResolverHost = config.networking.hostName == "luffy";
      acceptDnsFlag = if isResolverHost then "false" else "true";
    in
    {
      # Shared Tailscale client configuration for the fleet
      services.tailscale = {
        enable = true;
        inherit (cfg) authKeyFile;
        extraUpFlags = [
          "--login-server=${cfg.loginServer}"
          "--accept-dns=${acceptDnsFlag}"
        ];
        # Documented: Headscale override_local_dns=true pushes global DNS above;
        # clients with --accept-dns=true will honor it (MagicDNS suffix nfp.nix
        # + global AdGuard). luffy with --accept-dns=false keeps local resolver
        # path and avoids self-query loop.
      };

      # Open UDP port 41641 for peer-to-peer Tailscale connections
      networking.firewall.allowedUDPPorts = [ 41641 ];

      # Luffy resolver safety: ensure systemd-resolved points to local AdGuard
      # rather than recursively querying itself via Tailnet. Bootstrapped via
      # AdGuard bootstrap_dns; public fallback only if AdGuard not yet ready.
      networking.nameservers = lib.mkIf isResolverHost (
        lib.mkForce [
          "127.0.0.1"
          "9.9.9.9"
          "1.1.1.1"
        ]
      );

      assertions = [
        {
          assertion =
            cfg.loginServer == "https://headscale.lovelain.duckdns.org"
            || lib.hasPrefix "http://luffy." cfg.loginServer
            || lib.hasPrefix "https://headscale." cfg.loginServer;
          message = "tailscale.loginServer should target Headscale control plane (luffy.nfp.nix:8086 via Tailnet or headscale.lovelain.duckdns.org via WAN for bootstrap). Verify authority split: publicDomain for WAN, tailnetDomain for MagicDNS.";
        }
      ];
    }
  );
}
