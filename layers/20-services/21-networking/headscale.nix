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
          base_domain = cfg.baseDomain;
          nameservers = {
            global = [
              "1.1.1.1"
              "1.0.0.1"
            ];
          };
        };
        server_url = cfg.serverUrl;
        # No external DERP fetch — headscale dies without internet DNS
        # ("getting DERPMap: no such host"). Use built-in DERP only.
        derp = {
          auto_update = false;
          auto_update_enabled = false;
          urls = [ ];
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
