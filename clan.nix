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

    # SANJI — Dell Precision 7680 (desktop workstation, control-plane, local inference, agent orchestrator)
    # Always-on services: Kong, Omniroute, FreeLLMAPI, FreeLLMPool, Ollama, Polyfloor
    sanji = {
      tags = [
        "desktop"
        "workstation"
        "laptop"
        "development"
        "ai-router"
        "ai-inference"
        "agent-orchestrator"
      ];
      deploy.targetHost = "root@192.168.1.68";
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
              server_tld = "matrix.lovelain.duckdns.org";
              app_domain = "element.lovelain.duckdns.org";
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
              inputs.nixos-passthru-cache.nixosModules.nixos-passthru-cache
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
          {
            inputs,
            pkgs,
            lib,
            ...
          }:
          {
            imports = [
              inputs.nixarr.nixosModules.default
              inputs.nixos-telemetry.nixosModules.default
              inputs.nixos-passthru-cache.nixosModules.nixos-passthru-cache
            ];

            # nixarr-py rebuild: nixarr/lib/nixarr-py/python-deps.nix keys a
            # Jellyfin OpenAPI-spec hash table that stops at 10.11.11, but
            # current nixpkgs ships jellyfin 12.2. Every nixarr settings-sync
            # unit (prowlarr, radarr, sonarr, …) forces nixarr-py, so luffy
            # fails to evaluate with `attribute '"12.2"' missing`.
            #
            # jellyfin-py is only a generated API client for Jellyfin<->radarr
            # app-config mapping, so building it against the newest spec nixarr
            # actually hashes (10.11.11) is safe. The real Jellyfin *server*
            # stays at 12.2 — only the API-client input spec is pinned back.
            nixarr.nixarr-py.package = lib.mkForce (
              pkgs.python3Packages.buildPythonPackage {
                pname = "nixarr-py";
                version = "0.1.0";
                pyproject = true;
                src = inputs.nixarr.outPath + "/nixarr/lib/nixarr-py";
                build-system = [ pkgs.python3Packages.setuptools ];
                dependencies = pkgs.callPackage (inputs.nixarr.outPath + "/nixarr/lib/nixarr-py/python-deps.nix") {
                  jellyfin = pkgs.jellyfin.overrideAttrs (_old: {
                    version = "10.11.11";
                    __intentionallyOverridingVersion = true;
                  });
                };
              }
            );
          }
        )
      ];
    };

    sanji = {
      machine.tags = machinesInventory.sanji.tags;
      imports = [
        ./machines/sanji/default.nix
        ./all-layers.nix
        (
          { inputs, ... }:
          {
            imports = [
              inputs.nixarr.nixosModules.default
              inputs.nixos-telemetry.nixosModules.default
              inputs.nixos-passthru-cache.nixosModules.nixos-passthru-cache
            ];
          }
        )
      ];
    };
  };
}
