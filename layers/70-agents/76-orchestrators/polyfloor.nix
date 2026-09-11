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
  polyfloorPkg = polyfloorFlake.packages.${pkgs.system}.default;
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
  #   - polyfloor-secrets.nix          → cfg.enable, cfg.port (sops "polyfloor-env")
  #   - 20-services/21-networking/endpoints.nix
  #       → config.services.ai-services.polyfloor.port `or` 8001
  # Keep a minimal mirror so they keep evaluating while the fleet migrates to
  # the upstream `services.polyfloor`. The mirror is driven from the upstream
  # option: set `services.polyfloor.enable = true` on a host and this shim
  # follows. Do not set `services.ai-services.polyfloor.*` directly on hosts.
  options.services.ai-services.polyfloor = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Legacy compat mirror of services.polyfloor.enable (read from the upstream option).";
    };
    port = mkOption {
      type = types.port;
      default = 8001;
      description = "Legacy compat mirror of services.polyfloor.port (read from the upstream option).";
    };
  };

  config = mkIf config.services.polyfloor.enable {
    # ── NFP defaults for the upstream module ────────────────────────
    services.polyfloor = {
      # Backend daemon built from the flake input.
      package = polyfloorPkg;
      host = "127.0.0.1";
      port = 8001;
      dataDir = "/var/lib/polyfloor";

      # Polyfloor talks to any OpenAI-compatible router. It enumerates models
      # via:
      #     GET  {routerEndpoint}/models          → grouped free|fast|reasoning|frontier
      # and runs agent inference via:
      #     POST {routerEndpoint}/chat/completions
      #
      # The NFP Kong gateway (78-llm-routers/kong-gateway.nix) exposes both:
      #   - route "v1-models"  → GET  /v1/models         → coding router
      #   - route "v1-chat"    → POST /v1/chat/completions → coding router
      # Kong proxy default port is 8090 (admin 8091). Alternatives:
      #   - LiteLLM      (78-llm-routers/litellm.nix,  port 4000, OpenAI /v1/models)
      #   - ExtremeRouter (78-llm-routers/extreme-router.nix, port 20128, /v1/*)
      # Polyfloor's own default (http://127.0.0.1:4000/v1) already matches LiteLLM.
      routerEndpoint = "http://127.0.0.1:8090/v1";

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
      # staticDir = polyfloorFlake.packages.${pkgs.system}.frontend;
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
  };
}
