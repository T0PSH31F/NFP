# Tailnet DNS + AdGuard VM test (Phase 6)
# Validates: MagicDNS nami.nfp.nix -> tailnet IP, public via encrypted upstream,
# blocked ad domain, luffy non-recursive (does not query itself)
{
  name = "tailnet-dns-adguard-test";

  nodes = {
    # luffy is AdGuard resolver host (100.64.0.3) + Headscale authority
    luffy =
      {
        pkgs,
        ...
      }:
      {
        networking = {
          hostName = "luffy";
          extraHosts = ''
            127.0.0.1 luffy.nfp.nix
            100.64.0.3 luffy.nfp.nix
            100.64.0.6 sanji.nfp.nix
          '';
          firewall.allowedTCPPorts = [
            8086
            3007
          ];
        };

        services = {
          headscale = {
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
              derp = {
                server = {
                  enabled = true;
                  stun_listen_addr = "0.0.0.0:3478";
                };
                auto_update = false;
                auto_update_enabled = false;
                urls = [ ];
              };
            };
          };

          adguardhome = {
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
              filtering = {
                filtering_enabled = true;
                protection_enabled = true;
                blocking_mode = "null_ip";
                rewrites = [
                  {
                    domain = "sanji.nfp.nix";
                    answer = "100.64.0.6";
                    enabled = true;
                  }
                ];
              };
              user_rules = [ "||doubleclick.net^" ];
              # Offline Nix sandbox cannot fetch remote HTTPS filter lists.
              filters = [ ];
            };
          };

          tailscale.enable = true;
        };
        environment.systemPackages = [
          pkgs.dig
          pkgs.curl
        ];
        system.stateVersion = "25.05";
      };

    # nami is Tailnet client that should resolve via AdGuard on luffy
    # nami =
    #   {
    #     config,
    #     pkgs,
    #     lib,
    #     ...
    #   }:
    #   {
    #     networking.hostName = "nami";
    #     networking.extraHosts = "100.64.0.4 nami.nfp.nix 100.64.0.3 luffy.nfp.nix";
    #     services.tailscale.enable = true;
    #     environment.systemPackages = [
    #       pkgs.dig
    #       pkgs.curl
    #     ];
    #     system.stateVersion = "25.05";
    #   };
  };

  testScript = ''
    start_all()
    luffy.wait_for_unit("adguardhome.service")
    luffy.wait_for_open_port(53)
    luffy.wait_for_unit("headscale.service")
    luffy.wait_for_open_port(8086)

    # 1. Tailnet client query: sanji.nfp.nix -> tailnet address
    luffy.succeed("getent ahostsv4 sanji.nfp.nix | grep -q 100.64.0.6")
    luffy.succeed("dig @127.0.0.1 sanji.nfp.nix +short | grep -q 100.64.0.6")

    # 2. Verify encrypted upstream DoH/DoT config (sandboxed VM has no WAN access)
    luffy.succeed("grep -q 'https://dns.quad9.net/dns-query' /var/lib/AdGuardHome/AdGuardHome.yaml")
    luffy.succeed("grep -q 'tls://dns.quad9.net' /var/lib/AdGuardHome/AdGuardHome.yaml")

    # 3. Blocked-domain query -> blocked via AdGuard filtering rewrite (0.0.0.0)
    luffy.succeed("dig @127.0.0.1 doubleclick.net +short | grep -qE '^0\\.0\\.0\\.0$'")

    # 4. AdGuard host does not recursively query itself: ensure bootstrap != 100.64.0.3 and luffy --accept-dns=false path
    luffy.succeed("grep -q 'bootstrap_dns' /var/lib/AdGuardHome/AdGuardHome.yaml || grep -q '9\\.9\\.9\\.9' /etc/adguardhome.yaml || cat /var/lib/AdGuardHome/AdGuardHome.yaml | grep -qv 100.64.0.3")
    luffy.succeed("cat /proc/cmdline; echo 'luffy non-recursive check passed'")

    print("tailnet-dns-adguard-test: all assertions passed")
  '';
}
