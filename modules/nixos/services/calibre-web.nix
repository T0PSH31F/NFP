{
  config,
  lib,
  ...
}:
with lib;
{
  options.services.calibre-web-app = {
    enable = mkEnableOption "Calibre-Web service";

    port = mkOption {
      type = types.int;
      default = 8083;
      description = "Calibre-Web port";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/calibre-web";
      description = "Data directory for Calibre-Web";
    };

    libraryPath = mkOption {
      type = types.str;
      default = "/var/lib/calibre";
      description = "Path to Calibre library";
    };
  };

  config = mkIf config.services.calibre-web-app.enable {
    # Run Calibre-Web as a container
    virtualisation.oci-containers.containers.calibre-web = {
      image = "lscr.io/linuxserver/calibre-web:latest";
      ports = [ "${toString config.services.calibre-web-app.port}:8083" ];
      volumes = [
        "${config.services.calibre-web-app.dataDir}:/config"
        "${config.services.calibre-web-app.libraryPath}:/books"
      ];
      environment = {
        PUID = "1000";
        PGID = "100";
        TZ = "America/Los_Angeles";
      };
    };

    # Create necessary directories
    systemd.tmpfiles.rules = [
      "d ${config.services.calibre-web-app.dataDir} 0755 root root -"
      "d ${config.services.calibre-web-app.libraryPath} 0755 root root -"
    ];

    # Firewall
    networking.firewall.allowedTCPPorts = [ config.services.calibre-web-app.port ];

    # Ensure data is persisted
    environment.persistence."/persist" = mkIf config.system-config.impermanence.enable {
      directories = [
        config.services.calibre-web-app.dataDir
        config.services.calibre-web-app.libraryPath
      ];
    };
  };
}
