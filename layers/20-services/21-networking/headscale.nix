{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.services.headscale-server;
in
{
  options.services.headscale-server = {
    enable = mkEnableOption "Headscale Tailscale control server";
    port = mkOption {
      type = types.port;
      default = 8086;
    };
    serverUrl = mkOption {
      type = types.str;
      default = "https://headscale.lovelain.duckdns.org";
      description = "Public URL where this Headscale instance is reachable (used by Tailscale clients as login-server)";
    };
    baseDomain = mkOption {
      type = types.str;
      default = "nfp.nix";
      description = "Magic DNS base domain for the tailnet";
    };
  };

  config = mkIf cfg.enable {
    services.headscale = {
      enable = true;
      inherit (cfg) port;
      address = "0.0.0.0";
      settings = {
        dns = {
          magic_dns = true;
          # Authoritative MagicDNS suffix — derived from layers.meta.tailnetDomain (nfp.nix).
          # Static check fails if this drifts from layers.meta.tailnetDomain.
          base_domain = config.layers.meta.tailnetDomain;
          # Global DNS pushed to all Tailnet clients (except luffy loop-avoidance).
          # AdGuard on luffy (Tailnet-reachable) is the single fleet resolver.
          # Sourced once from fleetAddresses authority; never inlined elsewhere.
          nameservers = {
            global = [
              config.layers.meta.fleetAddresses.luffy
            ];
          };
          # override_local_dns: when true, Tailnet clients that accept-dns=true
          # override their local /etc/resolv.conf stub and use the global resolver
          # above for all non-MagicDNS queries. Required for Headscale to enforce
          # AdGuard fleet-wide. Documented behavior: MagicDNS records always win
          # over global; global used for public Internet names via AdGuard.
          override_local_dns = true;
        };
        server_url = cfg.serverUrl;
        # Bootstrap resolver path: Headscale itself must resolve DERP map hostnames
        # (controlplane.tailscale.com) via public DNS, not via the Tailnet global
        # resolver it advertises. Systemd-resolved bootstrap + AdGuard bootstrap_dns
        # (9.9.9.9, 1.1.1.1) handles this without creating a loop. Keep Derp URLs
        # minimal and rely on built-in DERP if AdGuard bootstrap fails.
        derp = {
          auto_update_enabled = true;
          urls = [ "https://controlplane.tailscale.com/derpmap/default" ];
        };
        # Structured ACL policy (group:admin full access, group:guest media/docs only)
        policy = {
          mode = "file";
          path = "/var/lib/headscale/acl/hujson";
        };
      };
    };

    layers.layer-20.services.config.reverseProxy.routes.headscale = cfg.port;

    networking.firewall.allowedTCPPorts = [ cfg.port ];

    systemd.services.headscale.serviceConfig.DynamicUser = lib.mkForce false;

    users.users.headscale = {
      group = "headscale";
      isSystemUser = true;
      home = "/var/lib/headscale";
      createHome = true;
    };
    users.groups.headscale = { };

    clan.core.vars.generators.headscale = {
      files."headscale_auth_key" = {
        secret = true;
        owner = "headscale";
        group = "headscale";
      };
      script = ''
        ${pkgs.openssl}/bin/openssl rand -hex 32 > "$out/headscale_auth_key"
      '';
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/headscale 0750 headscale headscale -"
      "d /var/lib/headscale/acl 0750 headscale headscale -"
      ''f+ /var/lib/headscale/acl/hujson 0640 headscale headscale - {\n  "groups": {\n    "group:admin": ["t0psh31f@nfp.nix"],\n    "group:guest": []\n  },\n  "tagOwners": {\n    "tag:control-plane": ["group:admin"],\n    "tag:router": ["group:admin"],\n    "tag:pkb": ["group:admin"],\n    "tag:media": ["group:admin"],\n    "tag:docs": ["group:admin"],\n    "tag:monitoring": ["group:admin"],\n    "tag:desktop": ["group:admin"]\n  },\n  "acls": [\n    {\n      "action": "accept",\n      "src": ["group:admin"],\n      "dst": ["*:*"]\n    },\n    {\n      "action": "accept",\n      "src": ["group:guest"],\n      "dst": ["tag:media:80,443,8096,5000", "tag:docs:80,443,3007"]\n    }\n  ]\n}''
    ];

    # Persistence
    environment.persistence."/persist" = mkIf config.layers.layer-10.system.config.impermanence.enable {
      directories = [ "/var/lib/headscale" ];
    };
  };
}
