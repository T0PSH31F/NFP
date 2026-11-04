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

    openFirewall = mkEnableOption "opening port in the firewall for AionUi";

    remoteHost = mkOption {
      type = types.str;
      default = "luffy.nfp.nix";
      description = "Central fleet host running the single AionUI instance that all machines patch into";
    };

    client.enable = mkOption {
      type = types.bool;
      default =
        builtins.elem "ai-agent" (config.machine.tags or [ ])
        || builtins.elem "agent-orchestrator" (config.machine.tags or [ ])
        || config.layers.layer-76.orchestrators.aionui.enable;
      description = "Configure this machine to patch into the central AionUI instance on luffy";
    };
  };

  config =
    let
      cfg = config.layers.layer-76.orchestrators.aionui;
      remoteUrl = "http://${cfg.remoteHost}:${toString cfg.port}";
      primaryUser = config.layers.meta.primaryUser or "t0psh31f";
      llmPkgs = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system} or { };
      rawAionuiPkg =
        llmPkgs.aionui or (pkgs.aionui or (pkgs.writeShellScriptBin "aionui" ''
          PORT="''${AIONUI_PORT:-''${PORT:-3006}}"
          exec ${pkgs.python3}/bin/python3 -m http.server "$PORT" --bind 0.0.0.0
        '')
        );
      aionuiPkg =
        if rawAionuiPkg ? overrideAttrs then
          rawAionuiPkg.overrideAttrs (old: {
            preBuild = (old.preBuild or "") + ''
              for d in node_modules/.bun/better-sqlite3@*/node_modules/better-sqlite3/src; do
                if [ -d "$d" ]; then
                  chmod -R u+w "$d"
                  substituteInPlace "$d/better_sqlite3.cpp" \
                    --replace-quiet "v8::External::New(isolate, addon)" "v8::External::New(isolate, addon, v8::kExternalPointerTypeTagDefault)"
                  substituteInPlace "$d/util/macros.cpp" \
                    --replace-quiet "As<v8::External>()->Value()" "As<v8::External>()->Value(v8::kExternalPointerTypeTagDefault)"
                  sed -i 's/\b0,/nullptr,/g' "$d/util/helpers.cpp"
                fi
              done
            '';
          })
        else
          rawAionuiPkg;
      aioncoreSrc = pkgs.fetchurl {
        url = "https://github.com/iOfficeAI/AionCore/releases/download/v0.2.2/aioncore-v0.2.2-x86_64-unknown-linux-gnu.tar.gz";
        sha256 = "1c3f241c7deff8e9d6da189c1017e6b12df7b538a1f557276c79b3c33d257335";
      };
      aioncoreLibPath = lib.makeLibraryPath [
        pkgs.zlib
        pkgs.xz.out
        pkgs.stdenv.cc.cc.lib
      ];
      aioncorePkg = pkgs.runCommand "aioncore-0.2.2" { } ''
        mkdir -p $out/bin $out/libexec
        tar -xzf ${aioncoreSrc} -C $out/libexec
        chmod +x $out/libexec/aioncore
        cat << 'EOF' > $out/bin/aioncore
        #!/bin/sh
        exec ${pkgs.stdenv.cc.bintools.dynamicLinker} --library-path ${aioncoreLibPath} $out/libexec/aioncore "$@"
        EOF
        substituteInPlace $out/bin/aioncore --replace-quiet '$out' "$out"
        chmod +x $out/bin/aioncore
      '';
    in
    mkMerge [
      (mkIf cfg.client.enable {
        environment = {
          variables = {
            AIONUI_URL = remoteUrl;
            AIONUI_SERVER_URL = remoteUrl;
          };
          etc."aionui/fleet-client.json".text = builtins.toJSON {
            url = remoteUrl;
            host = cfg.remoteHost;
            inherit (cfg) port;
          };
        };
      })

      (mkIf cfg.enable {
        assertions = [
          {
            assertion =
              !(config.fileSystems."/" ? fsType && config.fileSystems."/".fsType == "tmpfs")
              || (config.layers.layer-10.system.config.impermanence.enable or false);
            message = "services.ai-services.aionui requires impermanence to be enabled (config.layers.layer-10.system.config.impermanence.enable = true) on machines with tmpfs root to prevent credential loss on reboot.";
          }
        ];

        clan.core.vars.generators.aionui = {
          files = {
            "aionui.env".secret = true;
            "admin-token".secret = true;
          };
          script = ''
            JWT_SECRET=$(${pkgs.openssl}/bin/openssl rand -hex 32)
            ADMIN_TOKEN=$(${pkgs.openssl}/bin/openssl rand -hex 24)
            printf "%s" "$ADMIN_TOKEN" > "$out/admin-token"
            cat <<EOF > "$out/aionui.env"
            AIONUI_JWT_SECRET=$JWT_SECRET
            AIONUI_SECRET_KEY=$JWT_SECRET
            AIONUI_ADMIN_TOKEN=$ADMIN_TOKEN
            EOF
          '';
        };

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
            EnvironmentFile = [
              config.clan.core.vars.generators.aionui.files."aionui.env".path
            ];
            ExecStartPre = pkgs.writeShellScript "aionui-init" ''
              mkdir -p /home/${primaryUser}/.config/AionUi
              cat << 'EOF' > /home/${primaryUser}/.config/AionUi/webui.config.json
              {
                "port": ${toString cfg.port},
                "allowRemote": true
              }
              EOF
              chown -R ${primaryUser}:users /home/${primaryUser}/.config/AionUi
            '';
            ExecStart = "${lib.getExe aionuiPkg} --ozone-platform=headless --disable-gpu --no-sandbox --webui --remote --port=${toString cfg.port}";
            Restart = "always";
            RestartSec = 5;
            Environment = [
              "HOME=/home/${primaryUser}"
              "PATH=${aioncorePkg}/bin:/etc/profiles/per-user/${primaryUser}/bin:/home/${primaryUser}/.nix-profile/bin:/home/${primaryUser}/.local/bin:/run/current-system/sw/bin:/usr/bin:/bin"
              "AIONUI_BACKEND_BIN=${aioncorePkg}/bin/aioncore"
              "AIONUI_HOST=0.0.0.0"
              "HOST=0.0.0.0"
              "AIONUI_ALLOW_REMOTE=true"
              "AIONUI_REMOTE=true"
              "AIONUI_PORT=${toString cfg.port}"
              "PORT=${toString cfg.port}"
              "NODE_ENV=production"
              "AIONUI_DATA_DIR=${cfg.dataDir}"
              "DATA_DIR=${cfg.dataDir}"
              "AIONUI_OPEN_BROWSER=false"
              "OPENAI_BASE_URL=http://z0r0.nfp.nix:20128/v1"
              "HERMES_GATEWAY_URL=${config.layers.layer-20.endpoints.hermes-gateway.baseUrl}"
              "PAPERCLIP_URL=${config.layers.layer-20.endpoints.paperclip.baseUrl}"
              "MISSION_CONTROL_URL=${config.layers.layer-20.endpoints.mission-control.baseUrl}"
            ];
            WorkingDirectory = "${cfg.dataDir}";
            ReadWritePaths = [
              cfg.dataDir
              "-/home/${primaryUser}/.config"
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
            category = "luffy";
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
      })
    ];
}
