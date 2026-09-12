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
        inherit (cfg) port;
        address = "0.0.0.0";
        root = cfg.rootDir;
        database = "/var/lib/filebrowser/data/filebrowser.db";
      };
    };

    users.users.filebrowser = {
      isSystemUser = true;
      group = "filebrowser";
      uid = 984;
      description = "FileBrowser Daemon";
    };
    users.groups.filebrowser = { };

    # Persistence
    environment.persistence."/persist" = mkIf config.layers.layer-10.system.config.impermanence.enable {
      directories = [ cfg.rootDir ];
    };
  };
}
