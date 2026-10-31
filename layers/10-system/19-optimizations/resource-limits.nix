# flake-parts/system/resource-limits.nix
# Purpose:
# - Stabilize system by capping background service resources
# - Prevent memory starvation (OOM/Thrashing)
# - Ensure interactive session (Hyprland/Editor) remains responsive

{
  config,
  lib,
  ...
}:

let
  cfg = config.layers.layer-10.system.config.resource-limits;
in
{
  options.layers.layer-10.system.config.resource-limits = {
    enable = lib.mkEnableOption "System-wide resource limits for background services";
  };

  config = lib.mkIf cfg.enable {
    systemd = {
      # Define a background slice for all non-interactive services
      slices.background = {
        description = "Background Services Slice";
        sliceConfig = {
          CPUWeight = 20; # Lower priority (Default is 100)
          IOWeight = 20;
          # Prevent background services from eating all memory
          MemoryHigh = "8G";
          MemoryMax = "10G";
        };
      };

      # Apply slice and individual limits to known heavy services
      services = {
        # Matrix Synapse - Notoriously memory hungry
        matrix-synapse = {
          serviceConfig = {
            Slice = lib.mkForce "background.slice";
            MemoryHigh = "2G";
            MemoryMax = "3G";
          };
        };

        # n8n - NodeJS based automation
        n8n = {
          serviceConfig = {
            Slice = lib.mkForce "background.slice";
            MemoryHigh = "1G";
            MemoryMax = "2G";
          };
        };

        # Calibre-Web
        calibre-web = {
          serviceConfig = {
            Slice = lib.mkForce "background.slice";
            MemoryHigh = "512M";
            MemoryMax = "1G";
          };
        };

        # AI Services (Common ones)
        chromadb = {
          serviceConfig = {
            Slice = lib.mkForce "background.slice";
            MemoryHigh = "1G";
            MemoryMax = "2G";
          };
        };

        localai = {
          serviceConfig = {
            Slice = lib.mkForce "background.slice";
            MemoryHigh = "4G";
            MemoryMax = "6G";
          };
        };

        # Ollama local inference manager (prevents memory thrashing / desktop lockup)
        ollama = {
          serviceConfig = {
            Slice = lib.mkForce "background.slice";
            MemoryHigh = "6G";
            MemoryMax = "7500M";
          };
        };

        # Jarvis & autonomous agent background daemons
        nfp-task-watcher = {
          serviceConfig = {
            Slice = lib.mkForce "background.slice";
            MemoryHigh = "512M";
            MemoryMax = "1G";
          };
        };

        nfp-jev-classifier = {
          serviceConfig = {
            Slice = lib.mkForce "background.slice";
            MemoryHigh = "512M";
            MemoryMax = "1G";
          };
        };

        nfp-jarvis-dream-cycle = {
          serviceConfig = {
            Slice = lib.mkForce "background.slice";
            MemoryHigh = "1500M";
            MemoryMax = "2500M";
          };
        };

        email-triage-daemon = {
          serviceConfig = {
            Slice = lib.mkForce "background.slice";
            MemoryHigh = "512M";
            MemoryMax = "1G";
          };
        };

        pi-durable-daemon = {
          serviceConfig = {
            Slice = lib.mkForce "background.slice";
            MemoryHigh = "1G";
            MemoryMax = "2G";
          };
        };

        hermes-agent = {
          serviceConfig = {
            Slice = lib.mkForce "background.slice";
            MemoryHigh = "1G";
            MemoryMax = "2G";
          };
        };

        # Loki / Promtail / Prometheus
        loki = {
          serviceConfig = {
            Slice = lib.mkForce "background.slice";
            MemoryHigh = "512M";
            MemoryMax = "1G";
          };
        };

        prometheus = {
          serviceConfig = {
            Slice = lib.mkForce "background.slice";
            MemoryHigh = "1G";
            MemoryMax = "2G";
          };
        };

        # Syncthing peer-to-peer sync (compresses Go heap via memory pressure)
        syncthing = {
          serviceConfig = {
            Slice = lib.mkForce "background.slice";
            MemoryHigh = "800M";
            MemoryMax = "1200M";
          };
        };

        # Wyoming Faster-Whisper local voice recognition
        wyoming-faster-whisper-local = {
          serviceConfig = {
            Slice = lib.mkForce "background.slice";
            MemoryHigh = "1500M";
            MemoryMax = "2G";
          };
        };

        # GitHub Actions local runner
        github-runner-nfp-deployer = {
          serviceConfig = {
            Slice = lib.mkForce "background.slice";
            MemoryHigh = "2500M";
            MemoryMax = "3500M";
          };
        };

        # PostgreSQL + pgvector database
        postgresql = {
          serviceConfig = {
            Slice = lib.mkForce "background.slice";
            MemoryHigh = "1500M";
            MemoryMax = "2G";
          };
        };

        # Grafana metrics dashboard
        grafana = {
          serviceConfig = {
            Slice = lib.mkForce "background.slice";
            MemoryHigh = "400M";
            MemoryMax = "600M";
          };
        };
      };

      user.services.nfp-screenpipe = {
        serviceConfig = {
          MemoryHigh = "1500M";
          MemoryMax = "2G";
        };
      };
    };
  };
}
