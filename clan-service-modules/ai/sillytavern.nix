{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.clan.services.ai.sillytavern;
in
{
  options.clan.services.ai.sillytavern = {
    enable = mkEnableOption "SillyTavern AI Frontend";
    port = mkOption {
      type = types.int;
      default = 8000;
      description = "Port to expose SillyTavern on";
    };
    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/sillytavern";
      description = "Data directory for SillyTavern";
    };
  };

  config = mkIf cfg.enable {
    # Container configuration
    virtualisation.oci-containers.containers.sillytavern = {
      image = "ghcr.io/sillytavern/sillytavern:latest";
      ports = [ "${toString cfg.port}:8000" ];
      volumes = [
        "${cfg.dataDir}:/home/node/app/data"
      ];
      environment = {
        TZ = "America/Los_Angeles";
      };
    };

    # Enable Docker/Podman
    virtualisation.docker.enable = true;
    virtualisation.oci-containers.backend = "docker";

    # Directory creation
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 root root -"
    ];

    # Firewall
    networking.firewall.allowedTCPPorts = [ cfg.port ];

    # Persistence
    environment.persistence."/persist" = mkIf config.system-config.impermanence.enable {
      directories = [ cfg.dataDir ];
    };
  };
}
