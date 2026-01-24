{
  config,
  lib,
  pkgs,
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
    # Run SillyTavern as a container
    virtualisation.oci-containers.containers.sillytavern = {
      image = "ghcr.io/sillytavern/sillytavern:latest";
      ports = [ "${toString config.services.sillytavern-app.port}:8000" ];
      volumes = [
        "${config.services.sillytavern-app.dataDir}:/home/node/app/data"
      ];
      environment = {
        TZ = "America/Los_Angeles";
      };
    };

    # Create necessary directories
    systemd.tmpfiles.rules = [
      "d ${config.services.sillytavern-app.dataDir} 0755 root root -"
    ];

    # Firewall
    networking.firewall.allowedTCPPorts = [ config.services.sillytavern-app.port ];

    # Ensure SillyTavern data is persisted
    environment.persistence."/persist" =
      mkIf (config.services.sillytavern-app.enable && config.system-config.impermanence.enable)
        {
          directories = [
            config.services.sillytavern-app.dataDir
          ];
        };
  };
}
