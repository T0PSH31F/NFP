# Tier: 76-orchestrators
# Module: aionui.nix
# Purpose: AionUI AI coworker web interface and agent session manager.
# Option Path: layers.layer-76.orchestrators.aionui
# Enabling Host Tags: agent-orchestrator, ai-agent, homelab
# RAM Footprint: medium (300MB-1GB)
{
  config,
  lib,
  pkgs,
  inputs ? { },
  ...
}:
with lib;
{
  imports = [
    (lib.mkRenamedOptionModule
      [ "services" "ai-services" "aionui" "enable" ]
      [ "layers" "layer-76" "orchestrators" "aionui" "enable" ]
    )
    (lib.mkRenamedOptionModule
      [ "services" "ai-services" "aionui" "port" ]
      [ "layers" "layer-76" "orchestrators" "aionui" "port" ]
    )
    (lib.mkRenamedOptionModule
      [ "layers" "layer-20" "services" "aionui" "enable" ]
      [ "layers" "layer-76" "orchestrators" "aionui" "enable" ]
    )
    (lib.mkRenamedOptionModule
      [ "layers" "layer-20" "services" "aionui" "port" ]
      [ "layers" "layer-76" "orchestrators" "aionui" "port" ]
    )
  ];

  options.layers.layer-76.orchestrators.aionui = {
    enable = mkEnableOption "AionUi — AI agent Cowork web UI";

    port = mkOption {
      type = types.port;
      default = 3006;
      description = "Port for AionUi web UI (3000 conflicts with mission-control, 3001 conflicts with FreeLLMAPI)";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/aionui";
      description = "Persistent data directory";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to open the port in the firewall";
    };
  };

  config =
    let
      cfg = config.layers.layer-76.orchestrators.aionui;
      primaryUser = config.layers.meta.primaryUser or "t0psh31f";
      llmPkgs = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system} or { };
      aionuiPkg =
        llmPkgs.aionui or (pkgs.aionui or (pkgs.writeShellScriptBin "aionui" ''
          PORT="''${AIONUI_PORT:-''${PORT:-3006}}"
          exec ${pkgs.python3}/bin/python3 -m http.server "$PORT" --bind 127.0.0.1
        '')
        );
    in
    mkIf cfg.enable {
      assertions = [
        {
          assertion =
            !(config.fileSystems."/" ? fsType && config.fileSystems."/".fsType == "tmpfs")
            || (config.layers.layer-10.system.config.impermanence.enable or false);
          message = "services.ai-services.aionui requires impermanence to be enabled (config.layers.layer-10.system.config.impermanence.enable = true) on machines with tmpfs root to prevent credential loss on reboot.";
        }
      ];

      systemd.tmpfiles.rules = [
        "d ${cfg.dataDir} 0755 ${primaryUser} users -"
        "d /home/${primaryUser} 0755 ${primaryUser} users -"
        "d /home/${primaryUser}/.claude 0755 ${primaryUser} users -"
        "d /home/${primaryUser}/.codex 0755 ${primaryUser} users -"
        "d /home/${primaryUser}/.gemini 0755 ${primaryUser} users -"
        "d /home/${primaryUser}/.opencode 0755 ${primaryUser} users -"
      ];

      systemd.services.aionui = {
        description = "AionUi — AI agent Cowork web UI";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          User = primaryUser;
          Group = "users";
          ExecStart = "${pkgs.xvfb-run}/bin/xvfb-run -a ${lib.getExe aionuiPkg} --no-sandbox";
          Restart = "always";
          RestartSec = 5;
          Environment = [
            "HOME=/home/${primaryUser}"
            "PATH=/etc/profiles/per-user/${primaryUser}/bin:/home/${primaryUser}/.nix-profile/bin:/home/${primaryUser}/.local/bin:/run/current-system/sw/bin:/usr/bin:/bin"
            "AIONUI_HOST=0.0.0.0"
            "HOST=0.0.0.0"
            "AIONUI_PORT=${toString cfg.port}"
            "PORT=${toString cfg.port}"
            "NODE_ENV=production"
            "AIONUI_DATA_DIR=${cfg.dataDir}"
            "DATA_DIR=${cfg.dataDir}"
            "AIONUI_OPEN_BROWSER=false"
          ];
          WorkingDirectory = "${cfg.dataDir}";
          ReadWritePaths = [
            cfg.dataDir
            "-/home/${primaryUser}/.claude"
            "-/home/${primaryUser}/.codex"
            "-/home/${primaryUser}/.gemini"
            "-/home/${primaryUser}/.opencode"
          ];
        };
      };

      networking.firewall.allowedTCPPorts = [ cfg.port ];

      nfp.services.aionui = {
        enable = true;
        host = config.networking.hostName;
        bind = "0.0.0.0";
        inherit (cfg) port;
        tailnetName = "aionui";
        tls = "headscale";
        healthcheck = {
          enable = true;
          path = "/";
          expectedStatus = [ 200 ];
        };
        homepage = {
          enable = true;
          category = "agents";
          order = 20;
          title = "AionUI";
          subtitle = "AI Cowork Web Interface";
          icon = "aionui";
          metric = {
            mode = "health-only";
          };
        };
      };

      environment.persistence."/persist" =
        mkIf (config.layers.layer-10.system.config.impermanence.enable or false)
          {
            directories = [
              {
                directory = cfg.dataDir;
                user = primaryUser;
                group = "users";
                mode = "0755";
              }
            ];
          };
    };
}
