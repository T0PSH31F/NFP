# Tier: 10-system
# Module: jarvis-core.nix
# Purpose: Enterprise Jarvis Operating System (v2.1.0-ENT) Core Schema & Declarative Infrastructure.
#          Defines reusable options.jarvis.* parameters (customer profile, desktop choice,
#          deployment target, declarative white-labeling/branding, JWT role quotas,
#          progressive trust provisioning, and Litestream backup pipeline).
# Option Path: jarvis / layers.layer-10.system.config.jarvis-core
# Enabling Host Tags: workstation, server, ai-agent
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.jarvis;
  l10Cfg = config.layers.layer-10.system.config.jarvis-core;
  effectiveEnable = cfg.enable || l10Cfg.enable;

  brandingManifest = pkgs.writeText "jarvis-branding.json" (
    builtins.toJSON {
      version = "2.1.0-ENT";
      inherit (cfg) customerName customerSlug deploymentTarget;
      branding = {
        inherit (cfg.branding)
          enable
          productName
          primaryColor
          accentColor
          supportContact
          personaName
          ;
        logoPath = if cfg.branding.logoPath != null then toString cfg.branding.logoPath else "";
      };
      quotas = cfg.quotas.roles;
    }
  );
in
{
  options = {
    layers.layer-10.system.config.jarvis-core = {
      enable = mkEnableOption "Enterprise Jarvis Operating System Core Engine (layer-10 alias)";
    };

    jarvis = {
      enable = mkEnableOption "Enterprise Jarvis Operating System (jarvis-core v2.1.0-ENT)";

      version = mkOption {
        type = types.str;
        default = "2.1.0-ENT";
        description = "Semantic release version of jarvis-core";
      };

      customerName = mkOption {
        type = types.str;
        default = "Enterprise Default";
        description = "Human-readable customer or organization name";
      };

      customerSlug = mkOption {
        type = types.str;
        default = "default-org";
        description = "URL/DNS-safe customer identifier slug";
      };

      desktopChoice = mkOption {
        type = types.enum [
          "headless"
          "hyprland"
          "niri"
          "umbriel"
        ];
        default = "umbriel";
        description = "Target Wayland compositor or headless server mode";
      };

      deploymentTarget = mkOption {
        type = types.enum [
          "bare-metal-iso"
          "proxmox-qcow2"
          "podman-stack"
          "workstation"
          "vps-appliance"
        ];
        default = "workstation";
        description = "Hardware/virtualization deployment target profile";
      };

      stateDir = mkOption {
        type = types.str;
        default = "/var/lib/jarvis";
        description = "Canonical persistent state directory for Jarvis SQLite WAL & vaults";
      };

      scratchDir = mkOption {
        type = types.str;
        default = "/workspace/scratch";
        description = "Isolated scratchpad directory for sandboxed bwrap sub-agents";
      };

      branding = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable declarative white-labeling across PWA, TUI, A2UI cards, and voice";
        };

        productName = mkOption {
          type = types.str;
          default = "Jarvis Enterprise OS";
          description = "White-labeled product title";
        };

        logoPath = mkOption {
          type = types.nullOr (types.either types.path types.str);
          default = null;
          description = "Path to organization logo asset injected into PWA & reports";
        };

        primaryColor = mkOption {
          type = types.str;
          default = "#0A2540";
          description = "Primary hex color for PWA shell and A2UI action cards";
        };

        accentColor = mkOption {
          type = types.str;
          default = "#00D4B6";
          description = "Secondary accent hex color for telemetry highlights";
        };

        supportContact = mkOption {
          type = types.str;
          default = "ops@jarvis-enterprise.local";
          description = "Support email or contact rendered in footers and incident cards";
        };

        personaName = mkOption {
          type = types.str;
          default = "J.A.R.V.I.S.";
          description = "Default voice and conversational assistant identity";
        };
      };

      quotas = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable JWT scoped multi-tenant role budget enforcement";
        };

        roles = mkOption {
          type = types.attrsOf (
            types.submodule {
              options = {
                tier0Unlimited = mkOption {
                  type = types.bool;
                  default = true;
                  description = "Allow unlimited Tier 0 (Local Ollama) execution";
                };
                tier1DailyUsd = mkOption {
                  type = types.float;
                  default = 1.0;
                  description = "Daily USD cap for Tier 1 cloud pool";
                };
                tier2MonthlyUsd = mkOption {
                  type = types.float;
                  default = 0.0;
                  description = "Monthly USD cap for Tier 2 frontier models (0 = disabled)";
                };
              };
            }
          );
          default = {
            junior = {
              tier0Unlimited = true;
              tier1DailyUsd = 1.0;
              tier2MonthlyUsd = 0.0;
            };
            senior = {
              tier0Unlimited = true;
              tier1DailyUsd = 10.0;
              tier2MonthlyUsd = 150.0;
            };
            exec = {
              tier0Unlimited = true;
              tier1DailyUsd = 100.0;
              tier2MonthlyUsd = 1000.0;
            };
          };
          description = "Role-based token budget limits enforced by ExtremeRouter & Jev";
        };
      };

      backup = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable continuous Litestream SQLite WAL replication";
        };

        replicaUrl = mkOption {
          type = types.str;
          default = "file:///mnt/nas/backups/jarvis-enterprise";
          description = "Target Litestream replica destination (file:// or s3://)";
        };

        monthlyFeeUsd = mkOption {
          type = types.float;
          default = 499.0;
          description = "Monthly SLA / lease fee used by Langfuse ROI statement calculator";
        };
      };
    };
  };

  config = mkIf effectiveEnable {
    environment.etc."jarvis/branding.json".source = brandingManifest;

    systemd.tmpfiles.rules = [
      "d ${cfg.stateDir} 0750 root root -"
      "d ${cfg.stateDir}/memory 0750 root root -"
      "d ${cfg.stateDir}/reports 0750 root root -"
      "d ${cfg.scratchDir} 0770 root root -"
    ];
  };
}
