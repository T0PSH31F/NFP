{
  config,
  lib,
  pkgs,
  ...
}:
let
  user = "t0psh31f";
  mountPoint = "/home/${user}/GoogleDrive";
  cfg = config.layers.layer-10.system.config.google-drive;
in
{
  options.layers.layer-10.system.config.google-drive = {
    # System mount is deprecated in favor of home-manager user service:
    # layers.layer-50.home.cli.services.rclone.enable
    systemMount.enable = lib.mkEnableOption "Legacy system-level Google Drive rclone mount (deprecated)";
  };

  config = {
    environment.systemPackages = [ pkgs.rclone ];
    environment.persistence."/persist" =
      lib.mkIf (config.layers.layer-10.system.config.impermanence.enable or false)
        {
          users.${user}.directories = [ ".config/rclone" ];
        };
    systemd.services.rclone-gdrive-mount = lib.mkIf cfg.systemMount.enable {
      description = "Mount Google Drive via rclone (system-level - deprecated)";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        User = user;
        Environment = "PATH=/run/wrappers/bin";
        ExecStartPre = [
          "-/run/wrappers/bin/fusermount3 -u ${mountPoint}"
          "-/run/wrappers/bin/fusermount -u ${mountPoint}"
          "${pkgs.coreutils}/bin/mkdir -p ${mountPoint}"
        ];
        ExecStart = "${pkgs.rclone}/bin/rclone mount gdrive: ${mountPoint} --vfs-cache-mode writes --vfs-cache-max-size 2G";
        ExecStop = "-/run/wrappers/bin/fusermount3 -u ${mountPoint}";
        Restart = "on-failure";
      };
    };
  };
}
