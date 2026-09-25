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
    # ── Weekly: update ALL flake inputs ──────────────────────────────
    systemd.services.nfp-auto-update = {
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

    systemd.timers.nfp-auto-update = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true;
      };
    };

    # ── Daily: update nixpkgs-ai only (faster AI package cadence) ───
    systemd.services.nfp-update-ai = {
      description = "Update nixpkgs-ai input and push";
      path = with pkgs; [
        nix
        git
        openssh
      ];
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        ExecStart = "${pkgs.writeShellScript "nfp-update-ai" ''
          set -e
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

    systemd.timers.nfp-update-ai = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
    };
  };
}
