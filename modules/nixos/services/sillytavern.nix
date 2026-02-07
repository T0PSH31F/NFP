{
  config,
  lib,
  ...
}:
with lib;
{
  options.services.sillytavern-app = {
    enable = mkEnableOption "SillyTavern service";

    port = mkOption {
      type = types.int;
      default = 8000;
      description = "SillyTavern port";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/sillytavern";
      description = "Data directory for SillyTavern";
    };
  };

  config = mkIf config.services.sillytavern-app.enable {
    # Native NixOS SillyTavern service
    services.sillytavern = {
      enable = true;
      port = config.services.sillytavern-app.port;
      listen = true; # Listen on all interfaces
    };

    # Firewall
    networking.firewall.allowedTCPPorts = [ config.services.sillytavern-app.port ];

    # Ensure data is persisted
    environment.persistence."/persist" = mkIf config.system-config.impermanence.enable {
      directories = [
        {
          directory = "/var/lib/sillytavern";
          user = "sillytavern";
          group = "sillytavern";
          mode = "0755";
        }
      ];
    };
  };
}
