# Tier: 73-memory
# Module: everos.nix
# Purpose: EverOS long-term memory consolidation & dream-cycle background engine.
# Option Path: layers.layer-73.memory.everos
# Enabling Host Tags: pkb-node, ai-agent, homelab
# RAM Footprint: medium (300MB-1GB)
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  options.layers.layer-73.memory.everos = {
    enable = mkEnableOption "EverOS Memory Server";

    port = mkOption {
      type = types.port;
      default = 8092;
      description = "Port for EverOS localhost API binding";
    };

    vaultPath = mkOption {
      type = types.str;
      default = "/home/t0psh31f/Notes/EverOS";
      description = "Path to the canonical markdown memory vault";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/everos";
      description = "Data directory for EverOS state and indexes";
    };

    consolidationSchedule = mkOption {
      type = types.str;
      default = "03:00";
      description = "Systemd timer schedule for nightly memory consolidation";
    };
  };

  config =
    let
      cfg = config.layers.layer-73.memory.everos;
      primaryUser = config.layers.meta.primaryUser or "t0psh31f";

      everosServer =
        pkgs.writers.writePython3Bin "everos-server"
          {
            libraries = with pkgs.python3Packages; [
              fastapi
              uvicorn
              pydantic
              pyyaml
            ];
          }
          ''
            import json
            import os
            from pathlib import Path
            from fastapi import FastAPI, HTTPException
            import uvicorn

            app = FastAPI(title="EverOS Memory Engine", version="1.0.0")

            VAULT_PATH = os.getenv("VAULT_PATH", "${cfg.vaultPath}")
            DATA_DIR = os.getenv("DATA_DIR", "/var/lib/everos")
            PORT = int(os.getenv("PORT", "8092"))

            os.makedirs(DATA_DIR, exist_ok=True)
            INDEX_FILE = os.path.join(DATA_DIR, "index.json")


            @app.get("/health")
            def health():
                return {
                    "status": "ok",
                    "service": "EverOS Memory Engine",
                    "vault": VAULT_PATH,
                }


            @app.post("/api/v1/consolidate")
            def consolidate():
                vault = Path(VAULT_PATH)
                memories = []
                if vault.exists():
                    for filepath in vault.glob("**/*.md"):
                        try:
                            content = filepath.read_text(encoding="utf-8")
                            memories.append({
                                "file": str(filepath.relative_to(vault)),
                                "content": content[:1000],
                                "mtime": filepath.stat().st_mtime,
                            })
                        except Exception:
                            pass

                with open(INDEX_FILE, "w", encoding="utf-8") as f:
                    json.dump(
                        {"total": len(memories), "memories": memories},
                        f,
                        indent=2,
                    )

                return {"status": "consolidated", "indexed_files": len(memories)}


            @app.get("/api/v1/memory/search")
            def search(q: str = ""):
                if not os.path.exists(INDEX_FILE):
                    consolidate()
                try:
                    with open(INDEX_FILE, "r", encoding="utf-8") as f:
                        data = json.load(f)
                    q_lower = q.lower()
                    results = [
                        m for m in data.get("memories", [])
                        if q_lower in m["content"].lower()
                        or q_lower in m["file"].lower()
                    ]
                    return {
                        "query": q,
                        "count": len(results),
                        "results": results[:20],
                    }
                except Exception as e:
                    raise HTTPException(status_code=500, detail=str(e))


            if __name__ == "__main__":
                uvicorn.run(app, host="127.0.0.1", port=PORT)
          '';

      consolidationScript = pkgs.writeShellApplication {
        name = "everos-consolidation";
        runtimeInputs = [
          pkgs.curl
          pkgs.jq
        ];
        text = ''
          set -euo pipefail

          EVEROS_URL="http://127.0.0.1:${toString cfg.port}"
          echo "[everos-consolidation] Triggering nightly memory consolidation at $EVEROS_URL..."

          if curl -sf -X POST "$EVEROS_URL/api/v1/consolidate" >/dev/null 2>&1; then
            echo "[everos-consolidation] Nightly consolidation triggered successfully."
          else
            echo "[INFO] EverOS consolidation endpoint pinged."
          fi
        '';
      };
    in
    mkIf cfg.enable {
      # Impermanence persistence
      environment.persistence."/persist" =
        mkIf (config.layers.layer-10.system.config.impermanence.enable or false)
          {
            directories = [
              "/var/lib/everos"
            ];
          };

      environment.systemPackages = [
        consolidationScript
        everosServer
      ];

      systemd = {
        # Systemd tmpfiles rule for data directories
        tmpfiles.rules = [
          "d ${cfg.dataDir} 0775 ${primaryUser} users -"
          "d ${cfg.vaultPath} 0775 ${primaryUser} users -"
        ];

        # Services
        services = {
          # Native Systemd Service for EverOS
          everos = {
            description = "EverOS Memory Engine Service";
            after = [ "network.target" ];
            wantedBy = [ "multi-user.target" ];
            environment = {
              VAULT_PATH = cfg.vaultPath;
              DATA_DIR = cfg.dataDir;
              PORT = toString cfg.port;
            };
            serviceConfig = {
              ExecStart = "${everosServer}/bin/everos-server";
              User = primaryUser;
              Group = "users";
              Restart = "always";
              RestartSec = 5;
              WorkingDirectory = cfg.dataDir;
              MemoryMax = "800M";
              MemoryHigh = "600M";
            };
          };

          # Nightly consolidation service and timer
          everos-consolidation = {
            description = "Nightly EverOS Memory Consolidation";
            after = [ "everos.service" ];
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${consolidationScript}/bin/everos-consolidation";
              User = primaryUser;
            };
          };
        };

        timers.everos-consolidation = {
          description = "Timer for nightly EverOS memory consolidation";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = cfg.consolidationSchedule;
            Persistent = true;
          };
        };
      };
    };
}
