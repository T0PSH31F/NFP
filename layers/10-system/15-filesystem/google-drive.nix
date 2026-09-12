{
  config,
  lib,
  pkgs,
  ...
}:
let
  user = "t0psh31f";
  mountPoint = "/home/${user}/GoogleDrive";
in
{
  environment.systemPackages = [ pkgs.rclone ];
  environment.persistence."/persist" =
    lib.mkIf (config.layers.layer-10.system.config.impermanence.enable or false)
      {
        users.${user}.directories = [ ".config/rclone" ];
      };
  systemd.services.rclone-gdrive-mount = {
    description = "Mount Google Drive via rclone";
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
}
