# Tier: 76-orchestrators
# Module: polyfloor.nix
# Purpose: Polyfloor — autonomous multi-company enterprise engine with a GBA/DS
#          department-store UI. Imports the upstream flake's
#          `nixosModules.default` and points it at the NFP LLM router.
# Option Path: services.polyfloor            (upstream module, from the flake)
#              services.ai-services.polyfloor (legacy compat shim — see below)
# Enabling Host Tags: agent-orchestrator, homelab
# RAM Footprint: heavy (>1GB)
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
let
  polyfloorFlake = inputs.polyfloor;
  polyfloorPkg = polyfloorFlake.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  # ── Import the upstream Polyfloor flake module ────────────────────
  # This provides `services.polyfloor` (enable, package, host, port, dataDir,
  # openFirewall, environmentFile, routerEndpoint, defaultHrModel, staticDir)
  # and the hardened systemd service (DynamicUser, ProtectSystem=strict, …).
  # We no longer vendor a pinned `fetchFromGitHub` build here — the flake input
  # `github:T0PSH31F/Polyfloor` is the single source of truth.
  imports = [ polyfloorFlake.nixosModules.default ];

  # ── Legacy compatibility shim ─────────────────────────────────────
  # Two sibling modules still reference the old option path
  # `services.ai-services.polyfloor`:
  #   - polyfloor-secrets.nix          → cfg.enable (sops "polyfloor-env")
  #   - 20-services/21-networking/endpoints.nix (now uses services.polyfloor.port directly)
  # Keep a minimal mirror so they keep evaluating while the fleet migrates to
  # the upstream `services.polyfloor`. The mirror is driven from the upstream
  # option: set `services.polyfloor.enable = true` on a host and this shim
  # follows. Do not set `services.ai-services.polyfloor.*` directly on hosts.
  # Authoritative port is services.polyfloor.port (mkDefault 7777 below), NOT a
  # duplicate constant — legacy shim mirrors that authoritative value.
  options.services.ai-services.polyfloor = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Legacy compat mirror of services.polyfloor.enable (read from the upstream option).";
    };
    port = mkOption {
      type = types.port;
      default = 7777;
      description = "Legacy compat mirror of services.polyfloor.port (mirrors authoritative services.polyfloor.port).";
    };
  };

  config = mkMerge [
    {
      services.polyfloor.port = mkDefault 7777;
    }
    (mkIf config.services.polyfloor.enable {
      # ── NFP defaults for the upstream module ────────────────────────
      services.polyfloor = {
        # Backend daemon built from the flake input.
        package = polyfloorPkg;
        host = lib.mkForce "0.0.0.0"; # Tailnet-reachable (firewall restricts to tailscale0/loopback via trustedInterfaces) — healthcheck probes nami.nfp.nix:7777
        dataDir = "/var/lib/polyfloor";

        # Polyfloor talks to any OpenAI-compatible router. It enumerates models
        # via:
        #     GET  {routerEndpoint}/models          → grouped free|fast|reasoning|frontier
        # and runs agent inference via:
        #     POST {routerEndpoint}/chat/completions
        #
        # Kong path multiplexer endpoints available (port 8090):
        #   - kong-er:       http://127.0.0.1:8090/v1 (ExtremeRouter)
        #   - kong-omni:     http://127.0.0.1:8090/omni/v1 (OmniRoute - TODO: when merged)
        #   - kong-free:     http://127.0.0.1:8090/llm/free/v1 (FreeLLMPool)
        #   - kong-frontier: http://127.0.0.1:8090/llm/frontier/v1 (Manifest)
        #   - extreme-direct: http://127.0.0.1:20128/v1 (ER direct backup)
        routerEndpoint = "http://127.0.0.1:8090/v1";

        # Health: GET http://127.0.0.1:7777/healthz -> {"status":"ok"} (also /metrics Prometheus)
        # Tailnet: polyfloor.lovelain.duckdns.org is intentionally NOT exposed via public Caddy 80/443.
        # It is reachable only via Tailscale: http://nami.nfp.nix:7777 or via Caddy on tailscale0 when proxied.
        # Headscale ACL: tag:control-plane (includes polyfloor) is group:admin-only, so only t0psh31f@nfp.nix can reach 7777 via tailnet. http://127.0.0.1:7777/healthz -> {"status":"ok"}  (also /metrics Prometheus)

        # Default HR orchestrator model: Xiaomi MiMo-V2.5 Pro.
        defaultHrModel = "mimo-v2.5-pro";

        # sops-rendered environment file (see polyfloor-secrets.nix, template
        # "polyfloor-env"). Secrets are read from *_FILE paths, never raw values.
        # When Kong consumer auth is enabled, add POLYFLOOR_ROUTER_API_KEY_FILE
        # to that env file pointing at a Kong consumer key (sops file secret).
        environmentFile = config.sops.templates."polyfloor-env".path;

        # Serve the built frontend SPA. Set this to the built frontend package
        # path once `inputs.polyfloor.packages.${system}.frontend` builds
        # (its npmDepsHash is currently a placeholder upstream). Left unset so
        # the backend runs API-only by default.
        # staticDir = polyfloorFlake.packages.${pkgs.stdenv.hostPlatform.system}.frontend;
      };

      # Mirror the upstream enable/port into the legacy option path so the
      # sibling modules above keep evaluating.
      services.ai-services.polyfloor.enable = config.services.polyfloor.enable;
      services.ai-services.polyfloor.port = config.services.polyfloor.port;

      # Persist per-company state across reboots when impermanence is enabled
      # (matches the previous vendored module's behaviour).
      environment.persistence."/persist" =
        mkIf (config.layers.layer-10.system.config.impermanence.enable or false)
          {
            directories = [
              {
                directory = config.services.polyfloor.dataDir;
                user = "polyfloor";
                group = "polyfloor";
                mode = "0750";
              }
            ];
          };

      # Tailnet contract: polyfloor.lovelain.duckdns.org via Tailscale only (Headscale ACL tag:control-plane)
      # Caddy on nami will proxy polyfloor.lovelain.duckdns.org -> 127.0.0.1:7777 but firewall + Headscale ensures only tailnet can reach 7777
      # Health: fleet-healthcheck probes /healthz on 7777
      nfp.services.polyfloor = {
        enable = true;
        host = "nami";
        port = config.services.polyfloor.port;
        healthcheck = {
          enable = true;
          path = "/healthz";
          expectedStatus = 200;
        };
        homepage = {
          enable = true;
          category = "agents";
          order = 10;
          title = "Polyfloor";
          subtitle = "Multi-Agent Orchestrator";
          icon = "polyfloor";
          metric = {
            mode = "health-only";
          };
        };
      };
    })
  ];
}
