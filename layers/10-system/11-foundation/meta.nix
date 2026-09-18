{ config, lib, ... }:
{
  options.layers.meta = {
    primaryUser = lib.mkOption {
      type = lib.types.str;
      default = "t0psh31f";
      description = "Primary user for home-manager integration";
    };
    # Canonical domain authorities — split by semantic plane.
    # publicDomain: only for public DNS/ACME/Caddy/WAN routes.
    # tailnetDomain: only for Headscale base_domain, MagicDNS hosts, Tailnet-only services.
    publicDomain = lib.mkOption {
      type = lib.types.str;
      default = "lovelain.duckdns.org";
      description = "Public/WAN/Caddy/ACME domain (e.g. *.lovelain.duckdns.org)";
    };
    tailnetDomain = lib.mkOption {
      type = lib.types.str;
      default = "nfp.nix";
      description = "Tailnet MagicDNS suffix for Headscale base_domain and internal fleet hosts (e.g. *.nfp.nix)";
    };
    domain = lib.mkOption {
      type = lib.types.str;
      default = "lovelain.duckdns.org";
      description = "DEPRECATED generic domain alias — use publicDomain (WAN/Caddy) or tailnetDomain (Headscale/MagicDNS) explicitly.";
    };
    fleetNetwork = lib.mkOption {
      type = lib.types.str;
      default = "100.64.0.0/10";
      description = "Internal fleet network CIDR (Tailscale 100.64.0.0/10, sequential allocation)";
    };
    # Fleet address authority — single source of Tailnet-reachable DNS per machine.
    # Topology config, not secret. Sourced once here, consumed by Headscale global DNS, monitoring, etc.
    fleetAddresses = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {
        z0r0 = "100.64.0.1";
        luffy = "100.64.0.3";
        nami = "100.64.0.4";
      };
      description = "Declarative Tailnet IPv4 per fleet host (Headscale 100.64.0.0/10). Single authority for Tailnet DNS & global resolver.";
    };
    tailnetAddress = lib.mkOption {
      type = lib.types.str;
      default = "100.64.0.3";
      description = "This machine's Tailnet IPv4 (convenience alias — prefer fleetAddresses.<host>)";
    };
  };

  # Cross-domain safety assertions — generic domain must match one of the authorities
  config.assertions = [
    {
      assertion = config.layers.meta.publicDomain == "lovelain.duckdns.org";
      message = "layers.meta.publicDomain must be lovelain.duckdns.org (WAN/ACME authority)";
    }
    {
      assertion = config.layers.meta.tailnetDomain == "nfp.nix";
      message = "layers.meta.tailnetDomain must be nfp.nix (Headscale MagicDNS authority)";
    }
  ];
}
