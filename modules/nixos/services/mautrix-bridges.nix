{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options.services.mautrix-bridges = {
    enable = mkEnableOption "Mautrix bridges for Matrix";

    homeserverUrl = mkOption {
      type = types.str;
      default = "http://localhost:8008";
      description = "URL of the Matrix homeserver";
    };

    homeserverDomain = mkOption {
      type = types.str;
      default = "matrix.local";
      description = "Domain of the Matrix homeserver";
    };

    # Individual bridge toggles
    telegram = {
      enable = mkEnableOption "Mautrix-Telegram bridge";
      port = mkOption {
        type = types.int;
        default = 29317;
        description = "Port for Telegram bridge";
      };
    };

    whatsapp = {
      enable = mkEnableOption "Mautrix-WhatsApp bridge";
      port = mkOption {
        type = types.int;
        default = 29318;
        description = "Port for WhatsApp bridge";
      };
    };

    signal = {
      enable = mkEnableOption "Mautrix-Signal bridge";
      port = mkOption {
        type = types.int;
        default = 29328;
        description = "Port for Signal bridge";
      };
    };

    discord = {
      enable = mkEnableOption "Mautrix-Discord bridge";
      port = mkOption {
        type = types.int;
        default = 29334;
        description = "Port for Discord bridge";
      };
    };

    slack = {
      enable = mkEnableOption "Mautrix-Slack bridge";
      port = mkOption {
        type = types.int;
        default = 29335;
        description = "Port for Slack bridge";
      };
    };

    instagram = {
      enable = mkEnableOption "Mautrix-Instagram bridge";
      port = mkOption {
        type = types.int;
        default = 29330;
        description = "Port for Instagram bridge";
      };
    };

    facebook = {
      enable = mkEnableOption "Mautrix-Facebook bridge";
      port = mkOption {
        type = types.int;
        default = 29319;
        description = "Port for Facebook bridge";
      };
    };

    googlechat = {
      enable = mkEnableOption "Mautrix-Google Chat bridge";
      port = mkOption {
        type = types.int;
        default = 29320;
        description = "Port for Google Chat bridge";
      };
    };

    twitter = {
      enable = mkEnableOption "Mautrix-Twitter bridge";
      port = mkOption {
        type = types.int;
        default = 29327;
        description = "Port for Twitter bridge";
      };
    };

    gmessages = {
      enable = mkEnableOption "Mautrix-Google Messages bridge";
      port = mkOption {
        type = types.int;
        default = 29336;
        description = "Port for Google Messages bridge";
      };
    };
  };

  config = mkIf config.services.mautrix-bridges.enable {
    # Mautrix-Telegram
    services.mautrix-telegram = mkIf config.services.mautrix-bridges.telegram.enable {
      enable = true;
      settings = {
        homeserver = {
          address = config.services.mautrix-bridges.homeserverUrl;
          domain = config.services.mautrix-bridges.homeserverDomain;
        };
        appservice = {
          address = "http://localhost:${toString config.services.mautrix-bridges.telegram.port}";
          port = config.services.mautrix-bridges.telegram.port;
          database = "postgresql:///mautrix-telegram?host=/run/postgresql";
        };
        bridge = {
          permissions = {
            "*" = "relaybot";
            ${config.services.mautrix-bridges.homeserverDomain} = "user";
          };
        };
      };
    };

    # Mautrix-WhatsApp
    services.mautrix-whatsapp = mkIf config.services.mautrix-bridges.whatsapp.enable {
      enable = true;
      settings = {
        homeserver = {
          address = config.services.mautrix-bridges.homeserverUrl;
          domain = config.services.mautrix-bridges.homeserverDomain;
        };
        appservice = {
          address = "http://localhost:${toString config.services.mautrix-bridges.whatsapp.port}";
          port = config.services.mautrix-bridges.whatsapp.port;
          database = {
            type = "postgres";
            uri = "postgresql:///mautrix-whatsapp?host=/run/postgresql";
          };
        };
        bridge = {
          permissions = {
            "*" = "relaybot";
            ${config.services.mautrix-bridges.homeserverDomain} = "user";
          };
        };
      };
    };

    # Mautrix-Signal
    services.mautrix-signal = mkIf config.services.mautrix-bridges.signal.enable {
      enable = true;
      settings = {
        homeserver = {
          address = config.services.mautrix-bridges.homeserverUrl;
          domain = config.services.mautrix-bridges.homeserverDomain;
        };
        appservice = {
          address = "http://localhost:${toString config.services.mautrix-bridges.signal.port}";
          port = config.services.mautrix-bridges.signal.port;
          database = "postgresql:///mautrix-signal?host=/run/postgresql";
        };
        bridge = {
          permissions = {
            "*" = "relaybot";
            ${config.services.mautrix-bridges.homeserverDomain} = "user";
          };
        };
      };
    };

    # Note: Discord, Slack, Instagram, Facebook, Google Chat, Twitter, and Google Messages
    # bridges may need to be configured as containers or may not have native NixOS modules yet.
    # Container-based configuration for these bridges:

    virtualisation.oci-containers.containers = mkMerge [
      (mkIf config.services.mautrix-bridges.discord.enable {
        mautrix-discord = {
          image = "dock.mau.dev/mautrix/discord:latest";
          ports = ["${toString config.services.mautrix-bridges.discord.port}:29334"];
          volumes = [
            "/var/lib/mautrix-discord:/data"
          ];
          environment = {
            TZ = "America/Los_Angeles";
          };
        };
      })

      (mkIf config.services.mautrix-bridges.slack.enable {
        mautrix-slack = {
          image = "dock.mau.dev/mautrix/slack:latest";
          ports = ["${toString config.services.mautrix-bridges.slack.port}:29335"];
          volumes = [
            "/var/lib/mautrix-slack:/data"
          ];
          environment = {
            TZ = "America/Los_Angeles";
          };
        };
      })

      (mkIf config.services.mautrix-bridges.instagram.enable {
        mautrix-instagram = {
          image = "dock.mau.dev/mautrix/instagram:latest";
          ports = ["${toString config.services.mautrix-bridges.instagram.port}:29330"];
          volumes = [
            "/var/lib/mautrix-instagram:/data"
          ];
          environment = {
            TZ = "America/Los_Angeles";
          };
        };
      })

      (mkIf config.services.mautrix-bridges.facebook.enable {
        mautrix-facebook = {
          image = "dock.mau.dev/mautrix/facebook:latest";
          ports = ["${toString config.services.mautrix-bridges.facebook.port}:29319"];
          volumes = [
            "/var/lib/mautrix-facebook:/data"
          ];
          environment = {
            TZ = "America/Los_Angeles";
          };
        };
      })

      (mkIf config.services.mautrix-bridges.googlechat.enable {
        mautrix-googlechat = {
          image = "dock.mau.dev/mautrix/googlechat:latest";
          ports = ["${toString config.services.mautrix-bridges.googlechat.port}:29320"];
          volumes = [
            "/var/lib/mautrix-googlechat:/data"
          ];
          environment = {
            TZ = "America/Los_Angeles";
          };
        };
      })

      (mkIf config.services.mautrix-bridges.twitter.enable {
        mautrix-twitter = {
          image = "dock.mau.dev/mautrix/twitter:latest";
          ports = ["${toString config.services.mautrix-bridges.twitter.port}:8080"];
          volumes = [
            "/var/lib/mautrix-twitter:/data"
          ];
          environment = {
            TZ = "America/Los_Angeles";
          };
        };
      })

      (mkIf config.services.mautrix-bridges.gmessages.enable {
        mautrix-gmessages = {
          image = "dock.mau.dev/mautrix/gmessages:latest";
          ports = ["${toString config.services.mautrix-bridges.gmessages.port}:29336"];
          volumes = [
            "/var/lib/mautrix-gmessages:/data"
          ];
          environment = {
            TZ = "America/Los_Angeles";
          };
        };
      })
    ];

    # PostgreSQL databases for native bridges
    services.postgresql = {
      enable = true;
      ensureDatabases =
        (optional config.services.mautrix-bridges.telegram.enable "mautrix-telegram")
        ++ (optional config.services.mautrix-bridges.whatsapp.enable "mautrix-whatsapp")
        ++ (optional config.services.mautrix-bridges.signal.enable "mautrix-signal");

      ensureUsers =
        (optional config.services.mautrix-bridges.telegram.enable {
          name = "mautrix-telegram";
          ensureDBOwnership = true;
        })
        ++ (optional config.services.mautrix-bridges.whatsapp.enable {
          name = "mautrix-whatsapp";
          ensureDBOwnership = true;
        })
        ++ (optional config.services.mautrix-bridges.signal.enable {
          name = "mautrix-signal";
          ensureDBOwnership = true;
        });
    };

    # Create data directories for container-based bridges
    systemd.tmpfiles.rules =
      (optional config.services.mautrix-bridges.discord.enable "d /var/lib/mautrix-discord 0755 root root -")
      ++ (optional config.services.mautrix-bridges.slack.enable "d /var/lib/mautrix-slack 0755 root root -")
      ++ (optional config.services.mautrix-bridges.instagram.enable "d /var/lib/mautrix-instagram 0755 root root -")
      ++ (optional config.services.mautrix-bridges.facebook.enable "d /var/lib/mautrix-facebook 0755 root root -")
      ++ (optional config.services.mautrix-bridges.googlechat.enable "d /var/lib/mautrix-googlechat 0755 root root -")
      ++ (optional config.services.mautrix-bridges.twitter.enable "d /var/lib/mautrix-twitter 0755 root root -")
      ++ (optional config.services.mautrix-bridges.gmessages.enable "d /var/lib/mautrix-gmessages 0755 root root -");

    # Enable Docker for container-based bridges
    virtualisation.docker.enable =
      mkIf (
        config.services.mautrix-bridges.discord.enable
        || config.services.mautrix-bridges.slack.enable
        || config.services.mautrix-bridges.instagram.enable
        || config.services.mautrix-bridges.facebook.enable
        || config.services.mautrix-bridges.googlechat.enable
        || config.services.mautrix-bridges.twitter.enable
        || config.services.mautrix-bridges.gmessages.enable
      )
      true;

    virtualisation.oci-containers.backend = "docker";
  };
}
