# Tier: 77-dash-desk-ui
# Module: ollama-ui.nix
# Purpose: Minimal web interface for local Ollama instances.
# Option Path: services.ai-services.ollama-ui
# Enabling Host Tags: desktop, workstation, homelab
# RAM Footprint: medium (300MB-1GB)
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  options.services.ai-services.ollama-ui = {
    enable = mkEnableOption "NextJS Ollama LLM UI";

    port = mkOption {
      type = types.int;
      default = 3004;
      description = "Ollama UI port";
    };
  };

  config =
    let
      cfg = config.services.ai-services.ollama-ui;
    in
    mkIf cfg.enable {
      users.users.nextjs-ollama-llm-ui = {
        group = "nextjs-ollama-llm-ui";
        isSystemUser = true;
        description = "NextJS Ollama LLM UI Service User";
        home = "/var/lib/nextjs-ollama-llm-ui";
        createHome = true;
      };
      users.groups.nextjs-ollama-llm-ui = { };

      systemd.services.nextjs-ollama-llm-ui = {
        description = "NextJS Ollama LLM UI";
        wantedBy = [ "multi-user.target" ];
        after = [
          "network.target"
          "ollama.service"
        ];
        serviceConfig = {
          ExecStart = "${pkgs.nextjs-ollama-llm-ui}/bin/nextjs-ollama-llm-ui";
          User = "nextjs-ollama-llm-ui";
          Group = "nextjs-ollama-llm-ui";
          WorkingDirectory = "/var/lib/nextjs-ollama-llm-ui";
          Environment = [
            "PORT=${toString cfg.port}"
            "OLLAMA_URL=http://localhost:11434"
          ];
        };
      };

      networking.firewall.allowedTCPPorts = [ cfg.port ];

      environment.persistence."/persist" =
        mkIf (config.layers.layer-10.system.config.impermanence.enable or false)
          {
            directories = [
              {
                directory = "/var/lib/nextjs-ollama-llm-ui";
                user = "nextjs-ollama-llm-ui";
                group = "nextjs-ollama-llm-ui";
                mode = "0750";
              }
            ];
          };
    };
}
