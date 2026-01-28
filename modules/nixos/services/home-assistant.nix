{
  config,
  lib,
  ...
}:
with lib;
{
  options.services.home-assistant-server = {
    enable = mkEnableOption "Home Assistant server";

    port = mkOption {
      type = types.int;
      default = 8123;
      description = "Home Assistant port";
    };

    configDir = mkOption {
      type = types.str;
      default = "/var/lib/hass";
      description = "Configuration directory for Home Assistant";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = true;
      description = "Open firewall for Home Assistant";
    };
  };

  config = mkIf config.services.home-assistant-server.enable {
    services.home-assistant = {
      enable = true;

      extraComponents = [
        # Common integrations
        "esphome"
        "met"
        "radio_browser"
        "moon"
        "sun"
        "cast"
        "spotify"
        "bluetooth"
        "zeroconf"
        "ssdp"
        "usb"
      ];

      config = {
        default_config = { };

        http = {
          server_port = config.services.home-assistant-server.port;
          trusted_proxies = [
            "127.0.0.1"
            "::1"
          ];
        };

        homeassistant = {
          name = "Home";
          unit_system = "metric";
          time_zone = "America/Los_Angeles";
        };
      };
    };

    # Firewall
    networking.firewall.allowedTCPPorts = mkIf config.services.home-assistant-server.openFirewall [
      config.services.home-assistant-server.port
    ];

    # Ensure Home Assistant data is persisted
    environment.persistence."/persist" =
      mkIf (config.services.home-assistant-server.enable && config.system-config.impermanence.enable)
        {
          directories = [
            "/var/lib/hass"
          ];
        };
  };
}
