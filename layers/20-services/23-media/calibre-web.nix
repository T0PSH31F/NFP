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
      default = 7119;
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
    nfp.services.calibre-web = {
      enable = true;
      host = "luffy";
      bind = "127.0.0.1";
      port = config.services.calibre-web-app.port;
      tailnetName = "calibre-web";
      tls = "headscale";
      healthcheck = {
        enable = true;
        path = "/";
        expectedStatus = [
          200
          302
        ];
      };
      homepage = {
        enable = true;
        category = "robin";
        order = 15;
        title = "Calibre-Web";
        subtitle = "Ancient Poneglyphs Library";
        icon = "calibre-web";
        metric = {
          mode = "health-only";
        };
      };
    };

    # Native NixOS Calibre-Web service
    services.calibre-web = {
      enable = true;
      listen.port = config.services.calibre-web-app.port;
      listen.ip = "0.0.0.0";
      dataDir = config.services.calibre-web-app.dataDir;

      options = {
        calibreLibrary = config.services.calibre-web-app.libraryPath;
        enableBookUploading = true;
        enableBookConversion = true;
      };
    };

    # Create necessary directories
    systemd.tmpfiles.rules = [
      "d ${config.services.calibre-web-app.dataDir} 0755 calibre-web calibre-web -"
      "d ${config.services.calibre-web-app.libraryPath} 0755 calibre-web calibre-web -"
    ];

    # Firewall
    networking.firewall.allowedTCPPorts = [ config.services.calibre-web-app.port ];

    # Ensure data is persisted
    environment.persistence."/persist" = mkIf config.layers.layer-10.system.config.impermanence.enable {
      directories = [
        {
          directory = config.services.calibre-web-app.dataDir;
          user = "calibre-web";
          group = "calibre-web";
          mode = "0755";
        }
        {
          directory = config.services.calibre-web-app.libraryPath;
          user = "calibre-web";
          group = "calibre-web";
          mode = "0755";
        }
      ];
    };
  };
}
