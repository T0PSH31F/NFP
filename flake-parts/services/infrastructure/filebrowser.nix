{ config, lib, ... }:
with lib;
let
  cfg = config.services.filebrowser-app;
in
{
  options.services.filebrowser-app = {
    enable = mkEnableOption "FileBrowser web interface";
    port = mkOption {
      type = types.port;
      default = 8085;
    };
    rootDir = mkOption {
      type = types.str;
      default = "/var/lib/filebrowser";
    };
  };

  config = mkIf cfg.enable {
    services.filebrowser = {
      enable = true;
      openFirewall = true;
      settings = {
        port = cfg.port;
        address = "0.0.0.0";
        root = cfg.rootDir;
        database = "/var/lib/filebrowser/data/filebrowser.db";
      };
    };
  };
}
