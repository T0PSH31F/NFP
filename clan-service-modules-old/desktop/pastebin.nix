{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.pastebin;
in
{
  options.services.pastebin = {
    enable = mkEnableOption "PrivateBin pastebin service";

    port = mkOption {
      type = types.port;
      default = 8889;
      description = "Port for PrivateBin web interface";
    };

    host = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Host address to bind to";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/privatebin";
      description = "Directory for PrivateBin data storage";
    };

    settings = mkOption {
      type = types.attrs;
      default = { };
      description = "Additional PrivateBin configuration";
    };
  };

  config = mkIf cfg.enable {
    services.privatebin = {
      enable = true;
      
      settings = mkMerge [
        {
          main = {
            name = "PrivateBin";
            discussion = true;
            opendiscussion = false;
            password = true;
            fileupload = false;
            burnafterreadingselected = false;
            defaultformatter = "plaintext";
            syntaxhighlightingtheme = "sons-of-obsidian";
            sizelimit = 10485760; # 10MB
            template = "bootstrap";
            languageselection = false;
            languagedefault = "en";
            urlshortener = "";
            qrcode = true;
            icon = "none";
            cspheader = "default-src 'none'; script-src 'self'; style-src 'self'; font-src 'self'; img-src 'self' data:; connect-src 'self'; base-uri 'self'; form-action 'self';";
            zerobincompatibility = false;
            httpwarning = true;
            compression = "zlib";
          };

          expire = {
            default = "1week";
          };

          expire_options = {
            "5min" = 300;
            "10min" = 600;
            "1hour" = 3600;
            "1day" = 86400;
            "1week" = 604800;
            "1month" = 2592000;
            "1year" = 31536000;
            never = 0;
          };

          formatter_options = {
            plaintext = "Plain Text";
            syntaxhighlighting = "Source Code";
            markdown = "Markdown";
          };

          traffic = {
            limit = 10;
            header = "X_FORWARDED_FOR";
            dir = "${cfg.dataDir}/traffic";
          };

          purge = {
            limit = 300;
            batchsize = 10;
            dir = "${cfg.dataDir}/purge";
          };

          model = {
            class = "Filesystem";
          };

          model_options = {
            dir = "${cfg.dataDir}/data";
          };
        }
        cfg.settings
      ];
    };

    # Nginx reverse proxy configuration
    services.nginx = {
      enable = true;
      virtualHosts."privatebin.local" = {
        listen = [
          {
            addr = cfg.host;
            port = cfg.port;
          }
        ];
        locations."/" = {
          proxyPass = "http://127.0.0.1:8080"; # PrivateBin default port
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };
      };
    };

    # Ensure data directory exists with correct permissions
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0750 nginx nginx -"
      "d ${cfg.dataDir}/data 0750 nginx nginx -"
      "d ${cfg.dataDir}/traffic 0750 nginx nginx -"
      "d ${cfg.dataDir}/purge 0750 nginx nginx -"
    ];

    # Firewall configuration (optional - only if you want external access)
    # networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
