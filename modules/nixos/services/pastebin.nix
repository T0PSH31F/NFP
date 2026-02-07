{ config, lib, pkgs, ... }:

let
  cfg = config.services.pastebin;
in
{
  options.services.pastebin = {
    enable = lib.mkEnableOption "PrivateBin pastebin service";
    
    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Port for PrivateBin web interface";
    };
  };

  config = lib.mkIf cfg.enable {
    services.privatebin = {
      enable = true;
      settings = {
        main = {
          name = "PrivateBin";
          discussion = true;
          opendiscussion = false;
          password = true;
          fileupload = false;
          burnafterreadingselected = false;
          defaultformatter = "plaintext";
          syntaxhighlightingtheme = "sons-of-obsidian";
          sizelimit = 10485760;
          template = "bootstrap";
          notice = "";
          languageselection = false;
          languagedefault = "en";
          urlshortener = "";
          qrcode = true;
          icon = "none";
          cspheader = "default-src 'none'; manifest-src 'self'; connect-src * blob:; script-src 'self' 'unsafe-eval'; style-src 'self'; font-src 'self'; img-src 'self' data: blob:; media-src blob:; object-src blob:; sandbox allow-same-origin allow-scripts allow-forms allow-popups allow-modals allow-downloads";
          zerobincompatibility = false;
          httpwarning = true;
          compression = "zlib";
        };
        expire = {
          default = "1week";
        };
        traffic = {
          limit = 10;
          exempted = "127.0.0.1";
        };
        purge = {
          limit = 300;
          batchsize = 10;
        };
      };
    };

    # Nginx reverse proxy (optional)
    services.nginx = {
      enable = lib.mkDefault true;
      virtualHosts."paste.local" = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString cfg.port}";
        };
      };
    };
  };
}
