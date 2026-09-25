# AdGuard Home DNS Service
# layers/nixos/services/adguard.nix
{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.layers.layer-20.services.config.adguard;
in
{
  options.layers.layer-20.services.config.adguard = {
    enable = mkEnableOption "AdGuard Home DNS filtering";

    port = mkOption {
      type = types.port;
      default = 3002;
      description = "Web interface port";
    };

    dnsPort = mkOption {
      type = types.port;
      default = 53;
      description = "DNS server port";
    };

    bindHosts = mkOption {
      type = types.listOf types.str;
      default = [ "0.0.0.0" ];
      description = "IP addresses AdGuard Home should bind its DNS server to. Default 0.0.0.0 all interfaces. Override to specific IPs if port 53 conflicts with podman aardvark-dns.";
    };

    dhcp = mkOption {
      type = types.bool;
      default = false;
      description = "Enable AdGuard Home DHCP server";
    };

    lanInterface = mkOption {
      type = types.str;
      default = "eth1";
      description = "LAN interface for DHCP";
    };

    gatewayIp = mkOption {
      type = types.str;
      default = "192.168.1.54";
      description = "Luffy's LAN IP (for DNS rewrites and DHCP gateway field)";
    };

    subnet = mkOption {
      type = types.str;
      default = "192.168.1.0/24";
      description = "LAN subnet";
    };

    dhcpRange = mkOption {
      type = types.listOf types.str;
      default = [
        "192.168.1.100"
        "192.168.1.250"
      ];
      description = "DHCP lease range (only used if dhcp = true)";
    };
  };

  config = mkIf cfg.enable {
    nfp.services.adguard = {
      enable = true;
      host = "luffy";
      bind = "127.0.0.1";
      inherit (cfg) port;
      tailnetName = "adguard";
      tls = "headscale";
      healthcheck = {
        enable = true;
        path = "/control/stats";
        expectedStatus = [
          200
          401
        ];
      };
      homepage = {
        enable = true;
        category = "zoro";
        order = 10;
        title = "AdGuard Home";
        subtitle = "First Mate's Shield";
        icon = "adguard";
        metric = {
          mode = "native-api";
          adapter = "adguard";
          fields = [
            "queriesToday"
            "blockedCount"
            "blockedPercent"
          ];
        };
      };
    };

    # Disable systemd-resolved listener to free up port 53 for AdGuard Home
    services.resolved.settings = {
      Resolve = {
        DNSStubListener = "no";
      };
    };

    services.adguardhome = {
      enable = true;
      # Firewall handled explicitly below with CIDR-scoped rules (Tailnet + LAN + localhost only).
      # Do not open to WAN — task requires AdGuard never publicly exposed as open resolver.
      openFirewall = false;
      inherit (cfg) port;
      mutableSettings = true;
      allowDHCP = cfg.dhcp;
      settings = {
        dns = {
          # Listener: localhost + LAN + Tailnet-reachable. Sourced from fleetAddresses authority
          # for tailnet binding; cfg.bindHosts remains override but defaults tightened per task.
          # UDP 53 + TCP 53 both served by AdGuardHome on these binds.
          bind_hosts = cfg.bindHosts;
          port = cfg.dnsPort;
          # Bootstrap DNS for DoH/DoT hostname resolution (encryption happens at DoH/DoT layer,
          # not raw IP). WireGuard protects Tailnet transport separately.
          bootstrap_dns = [
            "9.9.9.9"
            "1.1.1.1"
          ];
          # Encrypted upstream transport: DoH (https://) and DoT (tls://) only.
          # Quad9 + Cloudflare DoH — both well-maintained, filtered at AdGuard level.
          upstream_dns = [
            "https://dns.quad9.net/dns-query"
            "https://cloudflare-dns.com/dns-query"
            "tls://dns.quad9.net"
          ];
        };
        filtering = {
          rewrites = [
            {
              # Headscale control plane moved back to luffy (2026-09-15);
              # must resolve to luffy LAN (Caddy :443 -> :8086), not nami.
              # 2026-09-23: stale nami IP here broke LAN bootstrap.
              domain = "headscale.lovelain.duckdns.org";
              answer = cfg.gatewayIp;
            }
            {
              domain = "mission-control.lovelain.duckdns.org";
              answer = "47.254.90.69";
            }
            {
              domain = "*.lovelain.duckdns.org";
              answer = cfg.gatewayIp;
            }
          ];
          # IMPORTANT: nfp.nix must NOT be claimed by AdGuard rewrites or local authoritative
          # zone — it remains resolvable by Headscale MagicDNS only. No nfp.nix rewrite here
          # proves no DNS loop and correct forwarding integration.
        };
        filters = [
          {
            enabled = true;
            url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_9.txt";
            name = "AdGuard DNS filter";
          }
          {
            enabled = true;
            url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_11.txt";
            name = "AdGuard DNS filter (mobile)";
          }
          {
            enabled = true;
            url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
            name = "AdGuard Base filter";
          }
          {
            enabled = true;
            url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_2.txt";
            name = "AdGuard Base filter (mobile)";
          }
          # YouTube DNS filtering — best effort only. Document limitation: DNS cannot reliably
          # remove all in-video YouTube ads because ad/media delivery shares infrastructure.
          {
            enabled = true;
            url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_15.txt";
            name = "AdGuard Annoyances / YouTube (best-effort)";
          }
        ];
        dhcp = mkIf cfg.dhcp {
          enabled = true;
          interface = cfg.lanInterface;
          range = cfg.dhcpRange;
          lease_time = 86400;
          gateway = cfg.gatewayIp;
        };
      };
    };

    # AdGuard DNS (TCP+UDP 53) must be reachable from localhost, LAN, and
    # Tailnet — never WAN. NixOS has no CIDR-scoped port primitive, so add
    # idempotent iptables rules (2026-09-23: tailnet outage root cause was
    # port 53 firewalled everywhere except podman).
    networking.firewall.extraCommands = ''
      for _proto in udp tcp; do
        for _src in 127.0.0.0/8 ${cfg.subnet} ${config.layers.meta.fleetNetwork}; do
          iptables -C nixos-fw -p $_proto -s $_src --dport 53 -j nixos-fw-accept 2>/dev/null \
            || iptables -I nixos-fw 1 -p $_proto -s $_src --dport 53 -j nixos-fw-accept
        done
      done
    '';

    users.users.adguardhome = {
      isSystemUser = true;
      group = "adguardhome";
      description = "AdGuard Home Daemon User";
      home = "/var/lib/AdGuardHome";
    };
    users.groups.adguardhome = { };

    # Fix StateDirectory conflict with impermanence by using static user
    systemd.services.adguardhome = {
      after = [
        "network-online.target"
        "persist.mount"
      ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        DynamicUser = lib.mkForce false;
        User = lib.mkForce "adguardhome";
        Group = lib.mkForce "adguardhome";
        ReadWritePaths = lib.mkForce [ "/var/lib/AdGuardHome" ];
        Restart = lib.mkForce "always";
        RestartSec = lib.mkForce "10s";
        StartLimitIntervalSec = lib.mkForce 0;
      };
    };

    # Impermanence support
    environment.persistence."/persist" = mkIf config.layers.layer-10.system.config.impermanence.enable {
      directories = [
        {
          directory = "/var/lib/AdGuardHome";
          user = "adguardhome";
          group = "adguardhome";
          mode = "0700";
        }
      ];
    };
  };
}
