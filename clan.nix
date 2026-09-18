_:
let
  machinesInventory = {
    # Z0R0 — Desktop workstation (dev, gaming, inference)
    # Always-on services: none (ExtremeRouter enabled directly in machine config)
    z0r0 = {
      tags = [
        "desktop"
        "workstation"
        "laptop"
        "development"
        "gaming"
        "ai-agent"
        "intel-12th-gen"
      ];
      deploy.targetHost = "root@127.0.0.1";
    };

    # LUFFY — Homelab server + local GUI desktop (memory, media, private data)
    # Always-on services: brain-service, Honcho, Matrix, n8n, Kavita, media
    # Desktop: retains local Noctalia-Hyprland GUI via desktop tag (hybrid server+desktop)
    luffy = {
      tags = [
        "server"
        "homelab"
        "desktop"
        "ai-agent"
        "ai-server"
        "pkb-node"
        "gpu-compute"
        "cache-server"
        "media"
        "intel-9th-gen"
      ];
      deploy.targetHost = "root@192.168.1.54"; # Direct LAN target (Tailscale 100.72.46.75 / luffy.nfp.nix fallback)
    };

    # NAMI — Cloud control-plane (always-on AI gateway, agent orchestration, media)
    # Always-on services: Kong, Omniroute, ExtremeRouter, Mission Control, Paperclip, Homepage, Headscale
    # Memory services stay on luffy for privacy.
    nami = {
      tags = [
        "server"
        "homelab"
        "network-router"
        "ai-router"
        "agent-orchestrator"
        "media"
      ];
      deploy.targetHost = "root@47.254.90.69"; # Alibaba VPS (US West-1)
    };

  };
in
{
  imports = [
    # ./clan-service-layers/default.nix # Removed due to class mismatch (clan.service vs clan)
  ];

  meta.name = "NFP";

  inventory = {
    machines = machinesInventory;
    instances = {
      wifi = {
        module = {
          name = "wifi";
          input = "clan-core";
        };
        roles.default.machines = {
          z0r0 = {
            settings = {
              networks.home = {
                enable = true;
                autoConnect = true;
                keyMgmt = "wpa-psk";
              };
            };
          };
          luffy = {
            settings = {
              networks.home = {
                enable = true;
                autoConnect = true;
                keyMgmt = "wpa-psk";
              };
            };
          };
        };
      };

      nix-cache = {
        module = {
          name = "nix-cache";
          input = "self";
        };
        roles.server.machines.luffy = { };
        # DISABLED: luffy offline (last seen 28d ago) — http://luffy.d:5000
        # was first substituter causing 5s timeout on every path lookup.
        # Re-enable when luffy comes back online.
        # roles.client.machines.z0r0 = { };
      };

      matrix-synapse = {
        module = {
          name = "matrix-synapse";
          input = "self";
        };
        roles.default.machines = {
          luffy = {
            settings = {
              server_tld = "matrix.local";
              app_domain = "element.local";
              acmeEmail = "admin@lovelain.duckdns.org";
              users.t0psh31f = {
                admin = true;
              };
              users.hermes = {
                admin = false;
              };
            };
          };
        };
      };

    };
  };

  # Tags-as-data: ALL layers + tag profiles imported unconditionally.
  # Tags control enablement via lib.mkIf guards, not import-site control flow.
  machines = {
    z0r0 = {
      machine.tags = machinesInventory.z0r0.tags;
      imports = [
        ./machines/z0r0/default.nix
        ./all-layers.nix
        (
          { inputs, ... }:
          {
            imports = [
              inputs.nixarr.nixosModules.default
              inputs.nixos-telemetry.nixosModules.default
            ];
          }
        )
      ];
    };

    luffy = {
      machine.tags = machinesInventory.luffy.tags;
      imports = [
        ./machines/luffy/default.nix
        ./all-layers.nix
        (
          { inputs, ... }:
          {
            imports = [
              inputs.nixarr.nixosModules.default
              inputs.nixos-telemetry.nixosModules.default
            ];
          }
        )
      ];
    };

    nami = {
      machine.tags = machinesInventory.nami.tags;
      imports = [
        ./machines/nami/default.nix
        ./server-layers.nix # headless: all layers EXCEPT 13-users (no HM profile)
        (
          { inputs, ... }:
          {
            imports = [
              inputs.nixarr.nixosModules.default
              inputs.nixos-telemetry.nixosModules.default
            ];
          }
        )
      ];
    };
  };
}
