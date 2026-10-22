# Tier: 60-gui-programs
# Module: 68-communication/bitlbee.nix
# Purpose: BitlBee IRC gateway with plugins for Discord, Facebook, and Mastodon.
#          Note: Matrix has no native bitlbee plugin in nixpkgs; use a dedicated
#          bridge (e.g. mautrix-matrix via layer-20 services) for Matrix instead.
{
  config,
  lib,
  pkgs,
  osConfig ? config,
  ...
}:
let
  cfg = config.layers.layer-60.gui.communication.bitlbee;
  commEnabled = config.layers.layer-60.gui.communication.enable;
in
{
  options.layers.layer-60.gui.communication.bitlbee = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enable BitlBee — an IRC gateway that bridges Discord, Facebook,
        Mastodon, and XMPP/Jabber networks into a single IRC session.
      '';
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 6667;
      description = "Port BitlBee listens on (default IRC port: 6667).";
    };

    interface = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Interface to bind to. Keep 127.0.0.1 unless exposing to LAN.";
    };

    authMode = lib.mkOption {
      type = lib.types.enum [
        "Open"
        "Closed"
        "Registered"
      ];
      default = "Registered";
      description = ''
        Authentication mode:
          Open       – accept anyone, NickServ handles user auth.
          Closed     – require PASS on connect.
          Registered – only registered users may connect.
      '';
    };

    discord = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install bitlbee-discord plugin (token-based Discord gateway).";
    };

    facebook = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install bitlbee-facebook plugin (Messenger MQTT gateway).";
    };

    mastodon = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install bitlbee-mastodon plugin (Mastodon API gateway).";
    };

    extraSettings = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Additional lines inserted into the [settings] section of bitlbee.conf.";
    };

    extraDefaults = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Additional lines inserted into the [defaults] section of bitlbee.conf.";
    };
  };

  config = lib.mkIf (commEnabled && cfg.enable) {
    services.bitlbee = {
      enable = true;
      portNumber = cfg.port;
      inherit (cfg) interface;
      inherit (cfg) authMode;
      authBackend = "storage";

      # Native bitlbee plugins (compiled against bitlbee's plugin ABI)
      plugins = lib.flatten [
        (lib.optional cfg.discord pkgs.bitlbee-discord)
        (lib.optional cfg.mastodon pkgs.bitlbee-mastodon)
      ];

      # libpurple plugins (Facebook uses the purple ABI)
      libpurple_plugins = lib.flatten [
        (lib.optional cfg.facebook pkgs.bitlbee-facebook)
      ];

      inherit (cfg) extraSettings;
      inherit (cfg) extraDefaults;
    };

    # Open firewall only on loopback — IRC clients connect locally.
    # Uncomment and adjust if you expose BitlBee to a LAN IRC client:
    # networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
