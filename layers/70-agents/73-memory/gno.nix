# Tier: 73-memory
# Module: gno.nix
# Purpose: GNO (Gnosis Knowledge Node) graph-based knowledge lookup daemon.
# Option Path: layers.layer-73.memory.gno
# Enabling Host Tags: pkb-node, homelab
# RAM Footprint: medium (300MB-1GB)
{
  config,
  lib,
  ...
}:
with lib;
{
  options.layers.layer-73.memory.gno = {
    enable = mkEnableOption "gno — local knowledge engine (hybrid search, graph, verified answers)";

    port = mkOption {
      type = types.port;
      default = 3456;
      description = "gno web UI / REST API / MCP service port";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/gno";
      description = "Persistent data directory (sqlite-vec store, config, embeddings cache)";
    };

    corpusDir = mkOption {
      type = types.str;
      default = "/var/lib/gno/corpus";
      description = "Source corpus directory — gno indexes from here. Mount or sync remote docs here.";
    };

    image = mkOption {
      type = types.str;
      default = "ghcr.io/gmickel/gno:latest";
      description = "gno container image (Bun runtime). Pin to SHA for production.";
    };
  };

  config =
    let
      cfg = config.layers.layer-73.memory.gno;
    in
    mkIf cfg.enable {
      # Create data + corpus directories
      systemd.tmpfiles.rules = [
        "d ${cfg.dataDir} 0755 t0psh31f users -"
        "d ${cfg.dataDir}/store 0755 t0psh31f users -"
        "d ${cfg.corpusDir} 0755 t0psh31f users -"
        "d ${cfg.dataDir}/.gno 0755 t0psh31f users -"
      ];

      # OCI container — gno serves its own web UI + API + MCP via Bun
      virtualisation.oci-containers.containers.gno = {
        inherit (cfg) image;
        ports = [
          "127.0.0.1:${toString cfg.port}:3456"
        ];
        volumes = [
          "${cfg.dataDir}/store:/root/gno/store"
          "${cfg.dataDir}/.gno:/root/.gno"
          "${cfg.corpusDir}:/root/gno/corpus:ro"
        ];
        environment = {
          GNO_HTTP_PORT = "3456";
          GNO_DATA_DIR = "/root/gno/store";
          GNO_HOME = "/root/.gno";
          NODE_ENV = "production";
        };
        extraOptions = [
          "--health-cmd"
          "curl -sf http://127.0.0.1:3456/health || exit 1"
          "--health-interval"
          "30s"
          "--health-timeout"
          "5s"
          "--health-start-period"
          "30s"
          "--health-retries"
          "3"
          "--memory"
          "2g"
          "--pids-limit"
          "512"
          "--security-opt=no-new-privileges:true"
        ];
        autoStart = true;
      };

      # Firewall: gno port on loopback only (Tailscale reverse-proxy fronts it)
      # networking.firewall.allowedTCPPorts = [ cfg.port ];  # only if exposed externally

      # Impermanence
      environment.persistence."/persist" =
        mkIf (config.layers.layer-10.system.config.impermanence.enable or false)
          {
            directories = [
              {
                directory = cfg.dataDir;
                user = "t0psh31f";
                group = "users";
                mode = "0755";
              }
            ];
          };
    };
}
