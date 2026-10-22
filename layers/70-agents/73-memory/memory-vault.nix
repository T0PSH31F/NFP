# Tier: 73-memory
# Module: memory-vault.nix
# Purpose: Memory Vault encrypted key-value store and memory snapshot manager.
# Option Path: layers.layer-73.memory.memory-vault
# Enabling Host Tags: pkb-node, ai-agent
# RAM Footprint: light (<300MB)
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  options.layers.layer-73.memory.memory-vault = {
    enable = mkEnableOption "Canonical Markdown Memory Vault with cross-machine sync";

    vaultPath = mkOption {
      type = types.str;
      default = "/home/t0psh31f/Notes/EverOS";
      description = "Path to the canonical markdown memory vault";
    };

    syncInterval = mkOption {
      type = types.str;
      default = "*:0/15";
      description = "Systemd timer schedule for cross-machine memory vault sync (15 min)";
    };

    remoteUrl = mkOption {
      type = types.str;
      default = "";
      description = "Remote git URL for mesh synchronization (e.g., git@luffy:/var/lib/memory/vault.git)";
    };
  };

  config =
    let
      cfg = config.layers.layer-73.memory.memory-vault;
      primaryUser = config.layers.meta.primaryUser or "t0psh31f";

      syncScript = pkgs.writeShellApplication {
        name = "memory-vault-sync";
        runtimeInputs = [
          pkgs.git
          pkgs.coreutils
          pkgs.openssh
        ];
        text = ''
          set -euo pipefail

          VAULT_DIR="${cfg.vaultPath}"

          if [ ! -d "$VAULT_DIR" ]; then
            echo "[memory-vault] Directory $VAULT_DIR does not exist. Creating..."
            mkdir -p "$VAULT_DIR"
          fi

          cd "$VAULT_DIR"

          # Initialize git repo if not already initialized
          if [ ! -d ".git" ]; then
            echo "[memory-vault] Initializing git repository in $VAULT_DIR..."
            git init -b main
            git config user.name "NFP Memory Agent"
            git config user.email "memory@nfp.internal"
          fi

          # Ensure seed directories exist
          for dir in knowledge decisions people projects inbox scratch; do
            mkdir -p "$dir"
            if [ ! -f "$dir/.gitkeep" ]; then
              touch "$dir/.gitkeep"
            fi
          done

          # Stage all changes
          git add -A

          # Commit if there are changes
          if ! git diff-index --quiet HEAD -- 2>/dev/null; then
            echo "[memory-vault] Committing memory vault changes..."
            git commit -m "auto(memory-vault): sync $(date -u +'%Y-%m-%dT%H:%M:%SZ')" || true
          fi

          # Sync with mesh remote if configured
          if [ -n "${cfg.remoteUrl}" ]; then
            if ! git remote | grep -q "^origin$"; then
              git remote add origin "${cfg.remoteUrl}" || true
            fi

            echo "[memory-vault] Pulling latest changes from remote..."
            git pull --rebase origin main 2>/dev/null || true

            echo "[memory-vault] Pushing to remote..."
            git push origin main 2>/dev/null || true
          fi

          echo "[memory-vault] Sync complete."
        '';
      };
    in
    mkIf cfg.enable {
      # Ensure memory group exists for user & service agent access
      users.groups.memory = { };

      # Add primary user and agents to memory group
      users.users = {
        t0psh31f.extraGroups = [ "memory" ];
      };

      # Impermanence persistence for memory vault
      environment.persistence."/persist" =
        mkIf (config.layers.layer-10.system.config.impermanence.enable or false)
          {
            directories = [
              "/var/lib/memory"
            ];
          };

      environment.systemPackages = [
        syncScript
      ];

      # Systemd tmpfiles, service and timer
      systemd = {
        tmpfiles.rules = [
          "d ${cfg.vaultPath} 0775 ${primaryUser} users -"
          "d ${cfg.vaultPath}/knowledge 0775 ${primaryUser} users -"
          "d ${cfg.vaultPath}/decisions 0775 ${primaryUser} users -"
          "d ${cfg.vaultPath}/people 0775 ${primaryUser} users -"
          "d ${cfg.vaultPath}/projects 0775 ${primaryUser} users -"
          "d ${cfg.vaultPath}/inbox 0775 ${primaryUser} users -"
          "d ${cfg.vaultPath}/scratch 0775 ${primaryUser} users -"
        ];

        services.memory-vault-sync = {
          description = "Sync canonical memory vault via Git mesh";
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${syncScript}/bin/memory-vault-sync";
            User = primaryUser;
            Group = "users";
            UMask = "0002";
          };
        };

        timers.memory-vault-sync = {
          description = "Timer for memory vault mesh synchronization";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = cfg.syncInterval;
            Persistent = true;
          };
        };
      };
    };
}
