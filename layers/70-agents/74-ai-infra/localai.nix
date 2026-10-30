# Tier: 74-ai-infra
# Module: localai.nix
# Purpose: Multi-modal local AI server supporting audio, vision, and text models.
# Option Path: services.ai-services.localai
# Enabling Host Tags: ai-server
# RAM Footprint: heavy (>1GB)
{
  config,
  lib,
  ...
}:
with lib;
{
  options.services.ai-services.localai = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable LocalAI service";
    };

    port = mkOption {
      type = types.int;
      default = 8081;
      description = "LocalAI port";
    };
  };

  config =
    let
      cfg = config.services.ai-services.localai;
    in
    mkIf cfg.enable {
      virtualisation = {
        podman.enable = true;
        oci-containers = {
          backend = "podman";
          containers.local-ai = {
            image = "quay.io/go-skynet/local-ai:latest";
            ports = [ "${toString cfg.port}:8080" ];
            volumes = [
              "local-ai-models:/models"
            ];
            environment = {
              THREADS = "4";
              CONTEXT_SIZE = "512";
            };
          };
        };
      };

      networking.firewall.allowedTCPPorts = [ cfg.port ];

      environment.persistence."/persist" =
        mkIf (config.layers.layer-10.system.config.impermanence.enable or false)
          {
            directories = [
              {
                directory = "/var/lib/localai";
                user = "root";
                group = "root";
                mode = "0750";
              }
            ];
          };
    };
}
