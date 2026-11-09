{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.layers.layer-50.home.cli.services.rclone;
in
{
  options.layers.layer-50.home.cli.services.rclone = {
    enable = mkEnableOption "Rclone Google Drive mount service";
    remoteName = mkOption {
      type = types.str;
      default = "gdrive";
      description = "The name of the rclone remote to mount.";
    };
  };

  home = mkIf cfg.enable {
    home.packages = with pkgs; [
      rclone
      fuse
    ];

    systemd.user.services.rclone-gdrive = {
      Unit = {
        Description = "Rclone Google Drive mount";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };

      Service = {
        Type = "simple";
        ExecStartPre = "/run/current-system/sw/bin/mkdir -p %h/GoogleDrive";
        ExecStart = "${pkgs.rclone}/bin/rclone mount ${cfg.remoteName}: %h/GoogleDrive --vfs-cache-mode full --vfs-cache-max-size 10G --vfs-cache-max-age 72h --vfs-read-ahead 128M --dir-cache-time 24h --vfs-fast-fingerprint";
        ExecStop = "/run/wrappers/bin/fusermount3 -u %h/GoogleDrive";
        Restart = "on-failure";
        RestartSec = "10s";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
