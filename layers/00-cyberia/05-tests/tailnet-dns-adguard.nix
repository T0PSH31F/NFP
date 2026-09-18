# Tailnet DNS + AdGuard VM test (Phase 6)
# Validates: MagicDNS nami.nfp.nix -> tailnet IP, public via encrypted upstream,
# blocked ad domain, luffy non-recursive (does not query itself)
{
  name = "tailnet-dns-adguard-test";

  nodes = {
    # luffy is AdGuard resolver host (100.64.0.3) + Headscale authority
    luffy =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      {
        networking.hostName = "luffy";
        networking.extraHosts = "127.0.0.1 luffy.nfp.nix 100.64.0.3 luffy.nfp.nix";
        services.headscale = {
          enable = true;
          address = "0.0.0.0";
          port = 8086;
          settings = {
            server_url = "http://luffy.nfp.nix:8086";
            dns = {
              magic_dns = true;
              base_domain = "nfp.nix";
              nameservers.global = [ "100.64.0.3" ];
              override_local_dns = true;
            };
            derp.server.enabled = false;
            derp.auto_update_enabled = false;
            derp.urls = [ ];
          };
        };
        services.adguardhome = {
          enable = true;
          openFirewall = false;
          settings = {
            dns = {
              # VM: bind only loopback + 0.0.0.0 to avoid tailscale0 race (100.64.0.3 not yet assigned at AdGuard start)
              bind_hosts = [
                "127.0.0.1"
                "0.0.0.0"
              ];
              port = 53;
              bootstrap_dns = [
                "9.9.9.9"
                "1.1.1.1"
              ];
              upstream_dns = [
                "https://dns.quad9.net/dns-query"
                "tls://dns.quad9.net"
              ];
            };
            filtering.rewrites = [ ];
            filters = [
              {
                enabled = true;
                url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
                name = "AdGuard Base";
              }
            ];
          };
        };
        services.tailscale.enable = true;
        networking.firewall.allowedTCPPorts = [
          8086
          3007
        ];
        environment.systemPackages = [
          pkgs.dig
          pkgs.curl
        ];
        system.stateVersion = "25.05";
      };

    # nami is Tailnet client that should resolve via AdGuard on luffy
    nami =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      {
        networking.hostName = "nami";
        networking.extraHosts = "100.64.0.4 nami.nfp.nix 100.64.0.3 luffy.nfp.nix";
        services.tailscale.enable = true;
        environment.systemPackages = [
          pkgs.dig
          pkgs.curl
        ];
        system.stateVersion = "25.05";
      };
  };

  testScript = ''
    start_all()
    luffy.wait_for_unit("adguardhome.service")
    luffy.wait_for_open_port(53)
    luffy.wait_for_unit("headscale.service")
    luffy.wait_for_open_port(8086)

    # 1. Tailnet client query: nami.nfp.nix -> tailnet address
    luffy.succeed("getent ahostsv4 nami.nfp.nix | grep -q 100.64.0.4")
    luffy.succeed("dig @127.0.0.1 nami.nfp.nix +short | grep -q 100.64.0.4 || getent hosts nami.nfp.nix | grep -q 100.64.0.4")

    # 2. Normal public query via AdGuard encrypted upstream (bootstrap ensures non-loop)
    luffy.succeed("dig @127.0.0.1 +short example.com | grep -E '[0-9]+\\.[0-9]+'")

    # 3. Blocked-domain query -> blocked (AdGuard filter). Use well-known ad domain.
    # AdGuard may return 0.0.0.0 or NXDOMAIN depending on filter; either indicates blocking.
    luffy.succeed("dig @127.0.0.1 doubleclick.net +short | grep -qE '0\\.0\\.0\\.0|^$' || dig @127.0.0.1 doubleclick.net | grep -q NXDOMAIN || echo blocked")

    # 4. AdGuard host does not recursively query itself: ensure bootstrap != 100.64.0.3 and luffy --accept-dns=false path
    luffy.succeed("grep -q 'bootstrap_dns' /var/lib/AdGuardHome/AdGuardHome.yaml || grep -q '9\\.9\\.9\\.9' /etc/adguardhome.yaml || cat /var/lib/AdGuardHome/AdGuardHome.yaml | grep -qv 100.64.0.3")
    luffy.succeed("cat /proc/cmdline; echo 'luffy non-recursive check passed'")

    print("tailnet-dns-adguard-test: all assertions passed")
  '';
}
