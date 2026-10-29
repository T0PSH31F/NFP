# Tier: 40-desktop
# Module: screenpipe.nix
# Purpose: Passive desktop perception daemon capturing window metadata, grim keyframes, and local OCR.
# Option Path: layers.layer-40.desktop.screenpipe
# Enabling Host Tags: desktop, workstation
# RAM Footprint: light (<150MB)
{
  config,
  lib,
  pkgs,
  osConfig ? config,
  ...
}:
with lib;
let
  cfg = config.layers.layer-40.desktop.screenpipe;
  primaryUser = osConfig.layers.meta.primaryUser or "t0psh31f";

  screenpipeScript = pkgs.writeShellScriptBin "nfp-screenpipe" ''
    set -euo pipefail
    exec ${pkgs.python3}/bin/python3 ${./screenpipe.py} "$@"
  '';
in
{
  imports = [
    (lib.mkAliasOptionModule [ "services" "screenpipe" ] [ "layers" "layer-40" "desktop" "screenpipe" ])
  ];

  options.layers.layer-40.desktop.screenpipe = {
    enable = mkEnableOption "Screen-Pipe Passive Desktop Perception Daemon";

    dbPath = mkOption {
      type = types.str;
      default = "/home/${primaryUser}/.local/share/jarvis/screenpipe.db";
      description = "Path to SQLite database storing desktop activity and perception frames.";
    };

    interval = mkOption {
      type = types.int;
      default = 15;
      description = "Polling interval in seconds when Hyprland IPC socket is unavailable.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      screenpipeScript
      pkgs.grim
      pkgs.tesseract5
    ];

    systemd.tmpfiles.rules = [
      "d /home/${primaryUser}/.local/share/jarvis 0775 ${primaryUser} users -"
      "d /tmp/screenpipe 0775 ${primaryUser} users -"
    ];

    systemd.user.services.nfp-screenpipe = {
      description = "NFP Screen-Pipe Passive Desktop Perception Daemon";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      path = [
        pkgs.bash
        pkgs.coreutils
        pkgs.grim
        pkgs.tesseract5
        pkgs.hyprland
        pkgs.jq
        pkgs.python3
      ];
      environment = {
        SCREENPIPE_DB = cfg.dbPath;
        SCREENPIPE_SCRATCH_DIR = "/tmp/screenpipe";
      };
      serviceConfig = {
        ExecStart = "${pkgs.python3}/bin/python3 ${./screenpipe.py} --watch --db ${cfg.dbPath} --interval ${toString cfg.interval}";
        Restart = "always";
        RestartSec = "5s";
      };
    };
  };
}
