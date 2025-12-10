{
  pkgs,
  config,
  ...
}: {
  services.samba.enable = true;

  sops.secrets.nas_username = {};
  sops.secrets.nas_password = {};
  sops.templates."cifs-credentials".content = ''
    username=${config.sops.placeholder.nas_username}
    password=${config.sops.placeholder.nas_password}
  '';
  fileSystems."/mnt/net-music" = {
    device = "//192.168.1.101/music";
    fsType = "cifs";

    options = [
      "noauto"
      "x-systemd.automount"
      "credentials=${config.sops.templates."cifs-credentials".path}"
    ];
  };
  fileSystems."/mnt/net-video" = {
    device = "//192.168.1.101/video";
    fsType = "cifs";

    options = [
      "noauto"
      "x-systemd.automount"
      "credentials=${config.sops.templates."cifs-credentials".path}"
    ];
  };

  fileSystems."/mnt/net-photo" = {
    device = "//192.168.1.101/photo";
    fsType = "cifs";
    options = [
      "noauto"
      "x-systemd.automount"
      "credentials=${config.sops.templates."cifs-credentials".path}"

      "noperm"
      "file_mode=0777"
      "dir_mode=0777"
    ];
  };

  fileSystems."/mnt/net-share" = {
    device = "//192.168.1.101/Family";
    fsType = "cifs";

    options = [
      "noauto"
      "x-systemd.automount"
      "credentials=${config.sops.templates."cifs-credentials".path}"
    ];
  };
}
