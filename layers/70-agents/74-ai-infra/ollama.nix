# Tier: 74-ai-infra
# Module: ollama.nix
# Purpose: Ollama local LLM inference manager supporting GGUF model libraries.
# Option Path: services.ai-services.ollama
# Enabling Host Tags: gpu-compute, ai-server
# RAM Footprint: heavy (>1GB)
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  options.services.ai-services.ollama = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Ollama local LLM server";
    };

    acceleration = mkOption {
      type = types.nullOr (
        types.enum [
          "cuda"
          "rocm"
          false
        ]
      );
      default = null;
      description = "GPU acceleration (cuda, rocm, or false)";
    };

    models = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Models to preload";
      example = [
        "llama3.2"
        "codellama"
      ];
    };
  };

  config =
    let
      cfg = config.services.ai-services.ollama;
    in
    mkMerge [
      {
        nfp.services.ollama = {
          inherit (cfg) enable;
          host = "nami";
          port = 11434;
          homepage = {
            enable = false; # Backend API — accessed through Open WebUI or oterm
          };
          healthcheck = {
            enable = true;
            path = "/api/version";
            expectedStatus = 200;
          };
        };
      }
      (mkIf cfg.enable {
        services.ollama = {
          enable = true;
          package = pkgs.ollama-vulkan;
          loadModels = cfg.models;
        };

        systemd.services.ollama.serviceConfig = {
          DynamicUser = lib.mkForce false;
          User = "ollama";
          Group = "ollama";
          ProtectHome = lib.mkForce false;
          StateDirectory = lib.mkForce [ ];
          ReadWritePaths = [ "/var/lib/ollama" ];
        };

        users.users.ollama = {
          group = "ollama";
          isSystemUser = true;
          description = "Ollama Service User";
          home = "/var/lib/ollama";
          createHome = true;
        };
        users.groups.ollama = { };

        networking.firewall.allowedTCPPorts = [ 11434 ];

        environment.persistence."/persist" =
          mkIf (config.layers.layer-10.system.config.impermanence.enable or false)
            {
              directories = [
                {
                  directory = "/var/lib/ollama";
                  user = "ollama";
                  group = "ollama";
                  mode = "0750";
                }
              ];
              users.t0psh31f = {
                directories = [ ".ollama" ];
              };
            };
      })
    ];
}
