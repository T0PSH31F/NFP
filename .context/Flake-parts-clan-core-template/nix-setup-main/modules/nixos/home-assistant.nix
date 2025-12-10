{
  config,
  lib,
  pkgs,
  ...
}: {
  options.homeAssistant = {
    enable = lib.mkEnableOption "Home Assistant smart home platform";

    subDomainName = lib.mkOption {
      type = lib.types.str;
      default = "home";
      description = "Subdomain for Home Assistant service";
    };

    baseDomainName = lib.mkOption {
      type = lib.types.str;
      default = "sipp.family";
      description = "Base domain name for Home Assistant service";
    };
  };

  config = lib.mkIf config.homeAssistant.enable {
    services.home-assistant = {
      enable = true;

      package = pkgs.unstable.home-assistant;
      config = null;
      lovelaceConfig = null;
      configDir = "/etc/home-assistant";
      extraComponents = [
        "backup"
        "default_config"

        "lifx"
        "homekit"
        "homekit_controller"
        "shelly"
        "bluetooth"
      ];
    };

    services.nginx.virtualHosts."${config.homeAssistant.subDomainName}.${config.homeAssistant.baseDomainName}" = {
      serverName = "${config.homeAssistant.subDomainName}.${config.homeAssistant.baseDomainName}";
      forceSSL = true;
      useACMEHost = config.homeAssistant.baseDomainName;
      locations."/" = {
        proxyPass = "http://localhost:8123";
        proxyWebsockets = true;
      };
    };
  };
}
