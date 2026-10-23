{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.layers.layer-20.services.config.ci.auto-update;
in
{
  options.layers.layer-20.services.config.ci.auto-update = {
    enable = lib.mkEnableOption "Auto-update timers for flake inputs";
  };

  config = lib.mkIf cfg.enable {
    systemd = {
      # ── Services ───────────────────────────────────────────────────
      services = {
        # Weekly: update ALL flake inputs
        nfp-auto-update = {
          description = "Update all NFP flake inputs and push";
          path = with pkgs; [
            nix
            git
            openssh
          ];
          serviceConfig = {
            Type = "oneshot";
            User = "root";
            ExecStart = "${pkgs.writeShellScript "nfp-auto-update" ''
              set -e

              # RAM Pre-flight Check (< 75% cap)
              TOTAL_RAM=$(awk '/MemTotal:/ { print $2 }' /proc/meminfo)
              AVAIL_RAM=$(awk '/MemAvailable:/ { print $2 }' /proc/meminfo)
              USED_PCT=$(( ((TOTAL_RAM - AVAIL_RAM) * 100) / TOTAL_RAM ))

              if [ "$USED_PCT" -ge 75 ]; then
                echo "Pre-flight aborted: System RAM usage at ''${USED_PCT}% (>= 75% threshold)." >&2
                exit 1
              fi

              cd /home/t0psh31f/Clan/NFP
              nix flake update
              git add flake.lock
              if ! git diff --cached --quiet; then
                git commit -m "chore: auto-update flake inputs"
                git push origin main
              fi
            ''}";
          };
        };

        # Daily: update nixpkgs-ai only (faster AI package cadence)
        nfp-update-ai = {
          description = "Update nixpkgs-ai input and push";
          path = with pkgs; [
            nix
            git
            openssh
            gawk
          ];
          serviceConfig = {
            Type = "oneshot";
            User = "root";
            ExecStart = "${pkgs.writeShellScript "nfp-update-ai" ''
              set -e

              # RAM Pre-flight Check (< 75% cap)
              TOTAL_RAM=$(awk '/MemTotal:/ { print $2 }' /proc/meminfo)
              AVAIL_RAM=$(awk '/MemAvailable:/ { print $2 }' /proc/meminfo)
              USED_PCT=$(( ((TOTAL_RAM - AVAIL_RAM) * 100) / TOTAL_RAM ))

              if [ "$USED_PCT" -ge 75 ]; then
                echo "Pre-flight aborted: System RAM usage at ''${USED_PCT}% (>= 75% threshold)." >&2
                exit 1
              fi

              cd /home/t0psh31f/Clan/NFP
              nix flake update nixpkgs-ai
              git add flake.lock
              if ! git diff --cached --quiet; then
                git commit -m "chore: auto-update nixpkgs-ai"
                git push origin main
              fi
            ''}";
          };
        };
      };

      # ── Timers ─────────────────────────────────────────────────────
      timers = {
        nfp-auto-update = {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "weekly";
            Persistent = true;
          };
        };

        nfp-update-ai = {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "daily";
            Persistent = true;
          };
        };
      };
    };
  };
}
