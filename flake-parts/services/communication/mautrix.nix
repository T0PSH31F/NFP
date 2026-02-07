{
  config,
  lib,
  ...
}:
with lib;
{
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

    instagram = {
      enable = mkEnableOption "Mautrix-Instagram bridge (via mautrix-meta)";
      port = mkOption {
        type = types.int;
        default = 29330;
        description = "Port for Instagram bridge";
      };
    };

    facebook = {
      enable = mkEnableOption "Mautrix-Facebook bridge (via mautrix-meta)";
      port = mkOption {
        type = types.int;
        default = 29319;
        description = "Port for Facebook bridge";
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
    # ============================================================================
    # NATIVE NIXOS SERVICES
    # ============================================================================

    # Mautrix-Telegram (Native)
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

    # Mautrix-WhatsApp (Native)
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

    # Mautrix-Signal (Native)
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

    # Mautrix-Discord (Native)
    services.mautrix-discord = mkIf config.services.mautrix-bridges.discord.enable {
      enable = true;
      settings = {
        homeserver = {
          address = config.services.mautrix-bridges.homeserverUrl;
          domain = config.services.mautrix-bridges.homeserverDomain;
        };
        appservice = {
          address = "http://localhost:${toString config.services.mautrix-bridges.discord.port}";
          port = config.services.mautrix-bridges.discord.port;
          database = {
            type = "postgres";
            uri = "postgresql:///mautrix-discord?host=/run/postgresql";
          };
        };
        bridge = {
          permissions = {
            "*" = "relay";
            ${config.services.mautrix-bridges.homeserverDomain} = "user";
          };
        };
      };
    };

    # Mautrix-Meta for Instagram (Native)
    services.mautrix-meta.instances.instagram = mkIf config.services.mautrix-bridges.instagram.enable {
      enable = true;
      settings = {
        homeserver = {
          address = config.services.mautrix-bridges.homeserverUrl;
          domain = config.services.mautrix-bridges.homeserverDomain;
        };
        appservice = {
          address = "http://localhost:${toString config.services.mautrix-bridges.instagram.port}";
          port = config.services.mautrix-bridges.instagram.port;
          database = {
            type = "postgres";
            uri = "postgresql:///mautrix-instagram?host=/run/postgresql";
          };
        };
        bridge = {
          permissions = {
            "*" = "relay";
            ${config.services.mautrix-bridges.homeserverDomain} = "user";
          };
        };
      };
    };

    # Mautrix-Meta for Facebook (Native)
    services.mautrix-meta.instances.facebook = mkIf config.services.mautrix-bridges.facebook.enable {
      enable = true;
      settings = {
        homeserver = {
          address = config.services.mautrix-bridges.homeserverUrl;
          domain = config.services.mautrix-bridges.homeserverDomain;
        };
        appservice = {
          address = "http://localhost:${toString config.services.mautrix-bridges.facebook.port}";
          port = config.services.mautrix-bridges.facebook.port;
          database = {
            type = "postgres";
            uri = "postgresql:///mautrix-facebook?host=/run/postgresql";
          };
        };
        bridge = {
          permissions = {
            "*" = "relay";
            ${config.services.mautrix-bridges.homeserverDomain} = "user";
          };
        };
      };
    };

    # ============================================================================
    # CONTAINER-BASED SERVICES (No native NixOS modules yet)
    # ============================================================================

    virtualisation.oci-containers.containers = mkMerge [
      (mkIf config.services.mautrix-bridges.slack.enable {
        mautrix-slack = {
          image = "dock.mau.dev/mautrix/slack:latest";
          ports = [ "${toString config.services.mautrix-bridges.slack.port}:29335" ];
          volumes = [
            "/var/lib/mautrix-slack:/data"
          ];
          environment = {
            TZ = "America/Los_Angeles";
          };
        };
      })

      (mkIf config.services.mautrix-bridges.googlechat.enable {
        mautrix-googlechat = {
          image = "dock.mau.dev/mautrix/googlechat:latest";
          ports = [ "${toString config.services.mautrix-bridges.googlechat.port}:29320" ];
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
          ports = [ "${toString config.services.mautrix-bridges.twitter.port}:8080" ];
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
          ports = [ "${toString config.services.mautrix-bridges.gmessages.port}:29336" ];
          volumes = [
            "/var/lib/mautrix-gmessages:/data"
          ];
          environment = {
            TZ = "America/Los_Angeles";
          };
        };
      })
    ];

    # ============================================================================
    # POSTGRESQL DATABASES
    # ============================================================================

    services.postgresql = {
      enable = true;
      ensureDatabases =
        (optional config.services.mautrix-bridges.telegram.enable "mautrix-telegram")
        ++ (optional config.services.mautrix-bridges.whatsapp.enable "mautrix-whatsapp")
        ++ (optional config.services.mautrix-bridges.signal.enable "mautrix-signal")
        ++ (optional config.services.mautrix-bridges.discord.enable "mautrix-discord")
        ++ (optional config.services.mautrix-bridges.instagram.enable "mautrix-instagram")
        ++ (optional config.services.mautrix-bridges.facebook.enable "mautrix-facebook");

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
        })
        ++ (optional config.services.mautrix-bridges.discord.enable {
          name = "mautrix-discord";
          ensureDBOwnership = true;
        })
        ++ (optional config.services.mautrix-bridges.instagram.enable {
          name = "mautrix-instagram";
          ensureDBOwnership = true;
        })
        ++ (optional config.services.mautrix-bridges.facebook.enable {
          name = "mautrix-facebook";
          ensureDBOwnership = true;
        });
    };

    # Create data directories for container-based bridges
    systemd.tmpfiles.rules =
      (optional config.services.mautrix-bridges.slack.enable "d /var/lib/mautrix-slack 0755 root root -")
      ++ (optional config.services.mautrix-bridges.googlechat.enable "d /var/lib/mautrix-googlechat 0755 root root -")
      ++ (optional config.services.mautrix-bridges.twitter.enable "d /var/lib/mautrix-twitter 0755 root root -")
      ++ (optional config.services.mautrix-bridges.gmessages.enable "d /var/lib/mautrix-gmessages 0755 root root -");

    # Enable Docker only for container-based bridges
    virtualisation.docker.enable = mkIf (
      config.services.mautrix-bridges.slack.enable
      || config.services.mautrix-bridges.googlechat.enable
      || config.services.mautrix-bridges.twitter.enable
      || config.services.mautrix-bridges.gmessages.enable
    ) true;

    virtualisation.oci-containers.backend = mkIf (
      config.services.mautrix-bridges.slack.enable
      || config.services.mautrix-bridges.googlechat.enable
      || config.services.mautrix-bridges.twitter.enable
      || config.services.mautrix-bridges.gmessages.enable
    ) "docker";

    # Ensure Matrix bridges data is persisted
    environment.persistence."/persist" =
      mkIf (config.services.mautrix-bridges.enable && (config.system-config.impermanence.enable or false))
        {
          directories = [
            "/var/lib/mautrix-telegram"
            "/var/lib/mautrix-whatsapp"
            "/var/lib/mautrix-signal"
            "/var/lib/mautrix-discord"
          ]
          ++ (optional config.services.mautrix-bridges.instagram.enable "/var/lib/mautrix-meta-instagram")
          ++ (optional config.services.mautrix-bridges.facebook.enable "/var/lib/mautrix-meta-facebook")
          ++ (optional config.services.mautrix-bridges.slack.enable "/var/lib/mautrix-slack")
          ++ (optional config.services.mautrix-bridges.googlechat.enable "/var/lib/mautrix-googlechat")
          ++ (optional config.services.mautrix-bridges.twitter.enable "/var/lib/mautrix-twitter")
          ++ (optional config.services.mautrix-bridges.gmessages.enable "/var/lib/mautrix-gmessages");
        };
  };
}
