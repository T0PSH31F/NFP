# Tier: 76-orchestrators
# Module: mission-control.nix
# Purpose: Mission Control agent fleet status, task dispatch, and telemetry dashboard.
# Option Path: layers.layer-76.orchestrators.mission-control
# Enabling Host Tags: agent-orchestrator, homelab
# RAM Footprint: medium (300MB-1GB)
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  imports = [
    (lib.mkRenamedOptionModule
      [ "services" "ai-services" "mission-control" "enable" ]
      [ "layers" "layer-76" "orchestrators" "mission-control" "enable" ]
    )
    (lib.mkRenamedOptionModule
      [ "services" "ai-services" "mission-control" "port" ]
      [ "layers" "layer-76" "orchestrators" "mission-control" "port" ]
    )
    (lib.mkRenamedOptionModule
      [ "layers" "layer-20" "services" "mission-control" "enable" ]
      [ "layers" "layer-76" "orchestrators" "mission-control" "enable" ]
    )
    (lib.mkRenamedOptionModule
      [ "layers" "layer-20" "services" "mission-control" "port" ]
      [ "layers" "layer-76" "orchestrators" "mission-control" "port" ]
    )
  ];

  options.layers.layer-76.orchestrators.mission-control = {
    enable = mkEnableOption "Mission Control — self-hosted AI agent control plane";

    port = mkOption {
      type = types.port;
      default = 3099;
      description = "Port for Mission Control web UI (3000 conflicts with Hermes Workspace)";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/mission-control";
      description = "Persistent data directory";
    };
  };

  config =
    let
      cfg = config.layers.layer-76.orchestrators.mission-control;
    in
    mkIf cfg.enable {
      assertions = [
        {
          assertion =
            !(config.fileSystems."/" ? fsType && config.fileSystems."/".fsType == "tmpfs")
            || (config.layers.layer-10.system.config.impermanence.enable or false);
          message = "services.ai-services.mission-control requires impermanence to be enabled (config.layers.layer-10.system.config.impermanence.enable = true) on machines with tmpfs root to prevent data loss on reboot.";
        }
      ];

      virtualisation.oci-containers.containers.mission-control = {
        image = "ghcr.io/builderz-labs/mission-control@sha256:6c411ac4bfccf3e72f0cc4736dab9560ff2a5496ff38a5c797f98f758d8855d2";
        ports = [ "${toString cfg.port}:3000" ];
        volumes = [
          "${cfg.dataDir}:/app/.data"
          "/home/t0psh31f/.gemini/config/skills:/app/skills:ro"
          "/var/lib/hermes:/var/lib/hermes:ro"
        ];
        environment = {
          MISSION_CONTROL_DATA_DIR = "/app/.data";
          HERMES_GATEWAY_URL = config.layers.layer-20.endpoints.hermes-gateway.baseUrl;
        };
        extraOptions = [
          "--userns=keep-id"
        ];
      };

      networking.firewall.allowedTCPPorts = [ cfg.port ];

      systemd.tmpfiles.rules = [
        "d ${cfg.dataDir} 0777 root root -"
        "d /home/t0psh31f/.gemini/config/skills 0755 t0psh31f users -"
        "d /var/lib/hermes 0755 root root -"
      ];

      environment.persistence."/persist" =
        mkIf (config.layers.layer-10.system.config.impermanence.enable or false)
          {
            directories = [
              {
                directory = cfg.dataDir;
                user = "root";
                group = "root";
                mode = "0777";
              }
            ];
          };
    };
}
