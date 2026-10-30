# Tier: 74-ai-infra
# Module: vllm.nix
# Purpose: High-throughput distributed GPU inference engine for vLLM models.
# Option Path: services.vllm-server
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
  options.services.vllm-server = {
    enable = mkEnableOption "vLLM Inference Server";

    port = mkOption {
      type = types.port;
      default = 8086;
      description = "Port to listen on";
    };

    host = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Host address to bind to. Set to 127.0.0.1 to restrict access to localhost.";
    };

    openFirewall = mkEnableOption "opening ports in the firewall for vLLM";

    model = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Model to serve (Hugging Face repo or local path)";
      example = "meta-llama/Meta-Llama-3-8B-Instruct";
    };

    extraFlags = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Extra command-line flags to pass to vllm";
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
      description = "GPU acceleration type";
    };
  };

  config =
    let
      cfg = config.services.vllm-server;
      vllmPackage = if cfg.acceleration == "rocm" then pkgs.pkgsRocm.vllm or pkgs.vllm else pkgs.vllm;
    in
    mkIf cfg.enable {
      # 1. Package inclusion
      environment.systemPackages = [ vllmPackage ];

      # 2. Systemd Service
      systemd.services.vllm-server = {
        description = "vLLM Inference Server";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];

        serviceConfig = {
          ExecStart =
            let
              args = [
                "serve"
              ]
              ++ optional (cfg.model != null) (toString cfg.model)
              ++ [
                "--host"
                cfg.host
                "--port"
                (toString cfg.port)
              ]
              ++ cfg.extraFlags;
            in
            "${vllmPackage}/bin/vllm ${escapeShellArgs args}";

          User = "vllm";
          Group = "vllm";
          WorkingDirectory = "/var/lib/vllm";
          StateDirectory = "vllm";
          Restart = "on-failure";
          PrivateTmp = true;
        };
      };

      # 3. User definitions
      users.users.vllm = {
        group = "vllm";
        isSystemUser = true;
        description = "vLLM Server User";
        home = "/var/lib/vllm";
        createHome = true;
      };
      users.groups.vllm = { };

      # 4. Firewall
      networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];

      # 5. Impermanence
      environment.persistence."/persist" =
        mkIf (config.layers.layer-10.system.config.impermanence.enable or false)
          {
            directories = [
              {
                directory = "/var/lib/vllm";
                user = "vllm";
                group = "vllm";
                mode = "0750";
              }
            ];
          };
    };
}
