# Tier: 76-orchestrators
# Module: paperclip.nix
# Purpose: Paperclip multi-agent swarm task queuing and goal tracking engine.
# Option Path: layers.layer-76.orchestrators.paperclip
# Enabling Host Tags: agent-orchestrator, homelab
# RAM Footprint: medium (300MB-1GB)
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
{
  imports = [
    (lib.mkRenamedOptionModule
      [ "services" "ai-services" "paperclip" "enable" ]
      [ "layers" "layer-76" "orchestrators" "paperclip" "enable" ]
    )
    (lib.mkRenamedOptionModule
      [ "services" "ai-services" "paperclip" "port" ]
      [ "layers" "layer-76" "orchestrators" "paperclip" "port" ]
    )
    (lib.mkRenamedOptionModule
      [ "layers" "layer-20" "services" "paperclip" "enable" ]
      [ "layers" "layer-76" "orchestrators" "paperclip" "enable" ]
    )
    (lib.mkRenamedOptionModule
      [ "layers" "layer-20" "services" "paperclip" "port" ]
      [ "layers" "layer-76" "orchestrators" "paperclip" "port" ]
    )
  ];

  options.layers.layer-76.orchestrators.paperclip = {
    enable = mkEnableOption "Paperclip — orchestrate AI agent teams";

    port = mkOption {
      type = types.port;
      default = 3101;
      description = "Port for Paperclip web UI";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/paperclip";
      description = "Persistent data directory";
    };

    databaseUrl = mkOption {
      type = types.str;
      default = "postgres://paperclip:paperclip@localhost:5432/paperclip";
      description = "PostgreSQL connection string (requires services.ai-services.postgresql)";
    };

    authSecret = mkOption {
      type = types.str;
      default = "";
      description = "Deprecated inline secret; managed via clan.core.vars.generators.paperclip";
    };

    remoteHost = mkOption {
      type = types.str;
      default = "luffy.nfp.nix";
      description = "Central fleet host running the single Paperclip instance that all machines patch into";
    };

    client.enable = mkOption {
      type = types.bool;
      default =
        builtins.elem "ai-agent" (config.machine.tags or [ ])
        || builtins.elem "agent-orchestrator" (config.machine.tags or [ ])
        || config.layers.layer-76.orchestrators.paperclip.enable;
      description = "Configure this machine's CLI and agent harnesses to patch into the central Paperclip instance on luffy";
    };
  };

  config =
    let
      cfg = config.layers.layer-76.orchestrators.paperclip;
      primaryUser = config.layers.meta.primaryUser or "t0psh31f";
      remoteUrl = "http://${cfg.remoteHost}:${toString cfg.port}";
      allowedHosts = [
        "luffy"
        "luffy.nfp.nix"
        "paperclip.nfp.nix"
        "paperclip.lovelain.duckdns.org"
        "100.64.0.3"
        "192.168.1.54"
        "localhost"
        "127.0.0.1"
      ];
      paperclipPkg =
        inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.paperclip or (
          if (inputs ? llm-agents && inputs.llm-agents ? outPath) then
            let
              pkgPath = "${inputs.llm-agents}/packages/paperclip/package.nix";
            in
            if builtins.pathExists pkgPath then
              pkgs.callPackage pkgPath {
                flake = inputs.llm-agents;
                mkUpdater = _args: null;
              }
            else
              pkgs.paperclip or (pkgs.writeShellScriptBin "paperclip" ''
                echo "Starting fallback Paperclip daemon..."
                exec ${pkgs.python3}/bin/python3 -m http.server "${toString cfg.port}" --bind "0.0.0.0"
              '')
          else
            pkgs.paperclip or (pkgs.writeShellScriptBin "paperclip" ''
              echo "Starting fallback Paperclip daemon..."
              exec ${pkgs.python3}/bin/python3 -m http.server "${toString cfg.port}" --bind "0.0.0.0"
            '')
        );
    in
    mkMerge [
      (mkIf cfg.client.enable {
        environment = {
          systemPackages = [ paperclipPkg ];
          variables = {
            PAPERCLIP_URL = remoteUrl;
            PAPERCLIP_API_URL = remoteUrl;
          };
          etc."paperclip/fleet-client.json".text = builtins.toJSON {
            apiBase = remoteUrl;
            host = cfg.remoteHost;
            inherit (cfg) port;
          };
        };
      })

      (mkIf cfg.enable {
        clan.core.vars.generators.paperclip = {
          files = {
            "paperclip.env".secret = true;
            "auth-secret".secret = true;
          };
          script = ''
            AUTH_SECRET=$(${pkgs.openssl}/bin/openssl rand -hex 32)
            MASTER_KEY=$(${pkgs.openssl}/bin/openssl rand -base64 32)
            printf "%s" "$AUTH_SECRET" > "$out/auth-secret"
            cat <<EOF > "$out/paperclip.env"
            BETTER_AUTH_SECRET=$AUTH_SECRET
            PAPERCLIP_SECRETS_MASTER_KEY=$MASTER_KEY
            EOF
          '';
        };

        nfp.services.paperclip = {
          enable = true;
          host = config.networking.hostName;
          bind = "0.0.0.0";
          inherit (cfg) port;
          tailnetName = "paperclip";
          tls = "headscale";
          healthcheck = {
            enable = true;
            path = "/api/health";
            expectedStatus = [ 200 ];
          };
          homepage = {
            enable = true;
            category = "luffy";
            order = 26;
            title = "Paperclip";
            subtitle = "Swarm Control Plane";
            icon = "paperclip";
            metric = {
              mode = "native-api";
              adapter = "paperclip";
              fields = [
                "deploymentMode"
                "bootstrapStatus"
                "dbBackup"
              ];
            };
          };
        };

        services.postgresql = mkIf (config.services.postgresql.enable or false) {
          ensureDatabases = [ "paperclip" ];
          ensureUsers = [
            {
              name = "paperclip";
              ensureDBOwnership = true;
            }
          ];
        };

        systemd.tmpfiles.rules = [
          "d ${cfg.dataDir} 0755 root root -"
        ];

        systemd.services.paperclip = {
          description = "Paperclip — orchestrate AI agent teams";
          after = [
            "network.target"
            "postgresql.service"
          ];
          wants = optional (config.services.postgresql.enable or false) "postgresql.service";
          wantedBy = [ "multi-user.target" ];

          serviceConfig = {
            User = "root";
            Group = "root";
            EnvironmentFile = [
              config.clan.core.vars.generators.paperclip.files."paperclip.env".path
            ];
            ExecStartPre = pkgs.writeShellScript "paperclip-init" ''
              mkdir -p /root/.paperclip/instances/default
              cat << 'EOF' > /root/.paperclip/instances/default/config.json
              {
                "$meta": {
                  "version": 1,
                  "updatedAt": "2026-01-01T00:00:00.000Z",
                  "source": "configure"
                },
                "database": {
                  "mode": "postgres",
                  "connectionString": "${cfg.databaseUrl}"
                },
                "logging": { "mode": "file" },
                "server": {
                  "deploymentMode": "authenticated",
                  "exposure": "private",
                  "bind": "lan",
                  "host": "0.0.0.0",
                  "port": ${toString cfg.port},
                  "allowedHostnames": ${builtins.toJSON allowedHosts},
                  "serveUi": true
                }
              }
              EOF
              cat << 'EOF' > /root/.paperclip/context.json
              {
                "version": 1,
                "currentProfile": "default",
                "profiles": {
                  "default": {
                    "apiBase": "${remoteUrl}"
                  }
                }
              }
              EOF
            '';
            ExecStart = "${lib.getExe paperclipPkg} run";
            Restart = "on-failure";
            RestartSec = "30s";
            WorkingDirectory = cfg.dataDir;
            Environment = [
              "HOST=0.0.0.0"
              "PORT=${toString cfg.port}"
              "PAPERCLIP_BIND=lan"
              "NODE_ENV=production"
              "SERVE_UI=true"
              "DATABASE_URL=${cfg.databaseUrl}"
              "PAPERCLIP_DEPLOYMENT_MODE=authenticated"
              "PAPERCLIP_DEPLOYMENT_EXPOSURE=private"
              "PAPERCLIP_PUBLIC_URL=http://${config.networking.hostName}.nfp.nix:${toString cfg.port}"
              "PAPERCLIP_AUTH_PUBLIC_BASE_URL=http://${config.networking.hostName}.nfp.nix:${toString cfg.port}"
              "BETTER_AUTH_URL=http://${config.networking.hostName}.nfp.nix:${toString cfg.port}"
              "PAPERCLIP_ALLOWED_HOSTNAMES=${lib.concatStringsSep "," allowedHosts}"
              "PATH=/run/current-system/sw/bin:/etc/profiles/per-user/${primaryUser}/bin:/home/${primaryUser}/.nix-profile/bin:/home/${primaryUser}/.local/bin:/run/wrappers/bin:/usr/bin:/bin"
              "HOME=/home/${primaryUser}"
            ];
          };
        };

        networking.firewall.allowedTCPPorts = [ cfg.port ];

        environment.persistence."/persist" =
          mkIf (config.layers.layer-10.system.config.impermanence.enable or false)
            {
              directories = [
                {
                  directory = cfg.dataDir;
                  user = "root";
                  group = "root";
                  mode = "0755";
                }
              ];
            };
      })
    ];
}
