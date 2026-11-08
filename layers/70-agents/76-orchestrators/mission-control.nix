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

    remoteHost = mkOption {
      type = types.str;
      default = "luffy.nfp.nix";
      description = "Central fleet host running the single Mission Control instance that all machines patch into";
    };

    client.enable = mkOption {
      type = types.bool;
      default =
        builtins.elem "ai-agent" (config.machine.tags or [ ])
        || builtins.elem "agent-orchestrator" (config.machine.tags or [ ])
        || config.layers.layer-76.orchestrators.mission-control.enable;
      description = "Configure this machine to patch into the central Mission Control instance on luffy";
    };
  };

  config =
    let
      cfg = config.layers.layer-76.orchestrators.mission-control;
      remoteUrl = "http://${cfg.remoteHost}:${toString cfg.port}";
    in
    mkMerge [
      (mkIf cfg.client.enable {
        environment = {
          variables = {
            MISSION_CONTROL_URL = remoteUrl;
          };
          etc."mission-control/fleet-client.json".text = builtins.toJSON {
            url = remoteUrl;
            host = cfg.remoteHost;
            inherit (cfg) port;
            fleetNodes = [
              "luffy.nfp.nix"
              "z0r0.nfp.nix"
              "sanji.nfp.nix"
            ];
          };
        };
      })

      (mkIf cfg.enable {
        assertions = [
          {
            assertion =
              !(config.fileSystems."/" ? fsType && config.fileSystems."/".fsType == "tmpfs")
              || (config.layers.layer-10.system.config.impermanence.enable or false);
            message = "services.ai-services.mission-control requires impermanence to be enabled (config.layers.layer-10.system.config.impermanence.enable = true) on machines with tmpfs root to prevent data loss on reboot.";
          }
        ];

        clan.core.vars.generators.mission-control = {
          files = {
            "mission-control.env".secret = true;
            "api-key".secret = true;
          };
          script = ''
            SECRET=$(${pkgs.openssl}/bin/openssl rand -hex 32)
            API_KEY=$(${pkgs.openssl}/bin/openssl rand -hex 24)
            printf "%s" "$API_KEY" > "$out/api-key"
            cat <<EOF > "$out/mission-control.env"
            MISSION_CONTROL_SECRET=$SECRET
            MISSION_CONTROL_API_KEY=$API_KEY
            API_KEY=$API_KEY
            AUTH_SECRET=$SECRET
            EOF
          '';
        };

        virtualisation.oci-containers.containers.mission-control = {
          image = "ghcr.io/builderz-labs/mission-control@sha256:6c411ac4bfccf3e72f0cc4736dab9560ff2a5496ff38a5c797f98f758d8855d2";
          ports = [ "${toString cfg.port}:3000" ];
          volumes = [
            "${cfg.dataDir}:/app/.data"
            "/home/t0psh31f/.gemini/config/skills:/app/skills:ro"
            "/var/lib/hermes:/var/lib/hermes:ro"
            "/run/current-system/sw/bin:/host/bin:ro"
            "/nix/store:/nix/store:ro"
            "/etc/profiles/per-user:/host/profiles:ro"
          ];
          environmentFiles = [
            config.clan.core.vars.generators.mission-control.files."mission-control.env".path
          ];
          environment = {
            PATH = "/host/bin:/host/profiles/t0psh31f/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin";
            MISSION_CONTROL_DATA_DIR = "/app/.data";
            MC_ALLOW_ANY_HOST = "true";
            MC_ALLOWED_HOSTS = "luffy,luffy.nfp.nix,mission-control.nfp.nix,mission.lovelain.duckdns.org,100.64.0.3,192.168.1.54,localhost,127.0.0.1";
            HERMES_GATEWAY_URL = config.layers.layer-20.endpoints.hermes-gateway.baseUrl;
            PAPERCLIP_URL = config.layers.layer-20.endpoints.paperclip.baseUrl;
            AIONUI_URL = config.layers.layer-20.endpoints.aionui.baseUrl;
            OPENAI_BASE_URL = "http://z0r0.nfp.nix:20128/v1";
            FLEET_NODES = "luffy.nfp.nix,z0r0.nfp.nix,sanji.nfp.nix";
          };
          extraOptions = [
            "--userns=keep-id"
          ];
        };

        networking.firewall.allowedTCPPorts = [ cfg.port ];

        nfp.services.mission-control = {
          enable = true;
          host = config.networking.hostName;
          bind = "0.0.0.0";
          inherit (cfg) port;
          tailnetName = "mission-control";
          tls = "headscale";
          healthcheck = {
            enable = true;
            path = "/";
            expectedStatus = [
              200
              307
            ];
          };
          homepage = {
            enable = true;
            category = "luffy";
            order = 28;
            title = "Mission Control";
            subtitle = "Autonomous Swarm Deck";
            icon = "mission-control";
            metric = {
              mode = "health-only";
            };
          };
        };

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
      })
    ];
}
