# Tier: 71-harness
# Module: hermes/hermes.nix
# Purpose: Nous Research Hermes autonomous agent daemon & browser runner.
# Option Path: layers.layer-76.hermes (also services.hermes)
# Enabling Host Tags: ai-agent, agent-orchestrator, homelab
# RAM Footprint: heavy (>1GB)
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  options.layers.layer-76.hermes = {
    enable = lib.mkEnableOption "Hermes Agent — self-improving AI agent gateway";

    enableDesktop = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Install hermes-desktop (Electron app) — provides `hermes-desktop` binary in PATH.";
    };

    gatewayPort = lib.mkOption {
      type = lib.types.int;
      default = 8085;
      description = "MCP gateway port";
    };

    matrixBot = {
      enable = lib.mkEnableOption "Matrix bot channel for Hermes";
      homeserver = lib.mkOption {
        type = lib.types.str;
        default = "http://matrix.local:8008";
        description = "Matrix homeserver URL. Use http://matrix.local:8008 for Tailscale (Synapse HTTP port behind Caddy).";
      };
      username = lib.mkOption {
        type = lib.types.str;
        default = "hermes";
      };
    };
  };

  imports = [
    inputs.hermes-agent.nixosModules.default
  ];

  config =
    let
      cfg = config.layers.layer-76.hermes;

      # Derive the Matrix domain from the homeserver URL (e.g. https://matrix.local → matrix.local)
      matrixDomain =
        let
          hs = cfg.matrixBot.homeserver;
          withoutProto = lib.removePrefix "https://" (lib.removePrefix "http://" hs);
        in
        lib.head (lib.splitString ":" withoutProto);

      # Vendored custom Hermes skins (source of truth: ./skins/).
      # Each is symlinked into HERMES_HOME/skins/<name>.yaml at build time.
      skinFiles = [
        "bubblegum-80s"
        "catppuccin"
        "dos"
        "empire"
        "lain"
        "mother"
        "mythos"
        "neonwave"
        "netrunner"
        "nous"
        "pirate"
        "sakura"
        "skynet"
        "telemate"
        "vault-tec"
      ];

      # Shared sops file paths
      extSopsFile = ../../../00-cyberia/03-treasure/secrets/external_services.yaml;
      vicinaeSopsFile = ../../../00-cyberia/03-treasure/secrets/vicinae.yaml;

      # Secrets from external_services.yaml referenced by the hermes-env template
      extSecrets = [
        "openrouter_api_key_2"
        "hf_token"
        "groq_api_key"
        "cerebras_api_key"
        "reka_api_key"
        "opencode_api_key"
        "opencode_go_api_key_2"
        "opencode_go_api_key_3"
        "nous_api_key"
        "openclaw_gateway_token"
        "gemini_api_key_we77"
        "ollama_api_key"
        "anthropic_api_key"
        "nvidia_api_key"
        "tinybird_api_gh"
        "tinybird_mcp_gh"
        "qdrant_api"
        "hostinger_api_token"
        "render_api_we77"
        "v0_api_key_we77"
        "helius_api_key"
        "helius_rpc_url"
        "github_token"
        "exa_api_key"
        "parallel_api_key"
        "firecrawl_api_key"
        "fal_key"
        "tavily_api_key"
        "browserbase_api_key"
        "browserbase_project_id"
        "honcho_api_key"
        "discord_bot_token"
        "discord_allowed_users"
        "server_root_password"
        "spacedrive_key"
        "langfuse_public_key"
        "langfuse_secret_key"
        "opencode_token"
        "matrix_access_token"
        "signal_account"
        "signal_allowed_users"
        "camofox_api_key"
        "elevenlabs_api_key"
        "xiaomi_mimo_api_key_wright"
        "kong_key_hermes"
        "extremerouter_api_key"
      ];

      llmPkgs = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system} or { };
      hermesDesktopPkg = llmPkgs.hermes-desktop or pkgs.hermes-desktop;
    in
    lib.mkIf cfg.enable {
      # NixOS-level sops secrets for the hermes-env template.
      # These are needed because the template lives at the NixOS level and can't
      # reference home-manager scoped secrets (defined in t0psh31f.nix).
      sops.secrets =
        builtins.listToAttrs (
          map (name: {
            inherit name;
            value = {
              sopsFile = extSopsFile;
            };
          }) extSecrets
        )
        // {
          gemini_api_key = {
            sopsFile = vicinaeSopsFile;
          };
        };

      services.hermes-agent = {
        enable = true;
        addToSystemPackages = true;

        # Override the package to fix hermes-tui/web builds that fail on
        # node-pty compilation (linux/types.h not found).
        # The upstream nixosModule defaults to inputs.self.packages which
        # bypasses our overlay. We fix it here directly using `inputs`.
        package =
          let
            origTui = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.tui;
            origWeb = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.web;
            origAgent = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default;
            fixedTui = origTui.overrideAttrs (old: {
              buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.linuxHeaders ];
              NIX_CFLAGS_COMPILE = (old.NIX_CFLAGS_COMPILE or "") + " -isystem ${pkgs.linuxHeaders}/include";
            });
            fixedWeb = origWeb.overrideAttrs (old: {
              buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.linuxHeaders ];
              NIX_CFLAGS_COMPILE = (old.NIX_CFLAGS_COMPILE or "") + " -isystem ${pkgs.linuxHeaders}/include";
            });
          in
          origAgent.overrideAttrs (
            old:
            let
              agentSrc = inputs.hermes-agent;
              runtimePath = pkgs.lib.makeBinPath (
                with pkgs;
                [
                  nodejs_22
                  ripgrep
                  git
                  openssh
                  ffmpeg
                  tirith
                  wl-clipboard
                  xclip
                ]
              );
            in
            {
              installPhase = ''
                runHook preInstall

                mkdir -p $out/share/hermes-agent $out/bin
                # Assets (skills, plugins, locales) are not installed by upstream Python wheel package default;
                # we copy them explicitly from pinned inputs.hermes-agent (pinned in flake.lock by rev+hash).
                cp -r ${agentSrc}/skills $out/share/hermes-agent/skills
                cp -r ${agentSrc}/plugins $out/share/hermes-agent/plugins
                cp -r ${agentSrc}/locales $out/share/hermes-agent/locales
                # web_dist and ui-tui are built locally with linuxHeaders fixes to prevent node-pty compilation failures
                cp -r ${fixedWeb} $out/share/hermes-agent/web_dist

                mkdir -p $out/ui-tui
                cp -r ${fixedTui}/lib/hermes-tui/* $out/ui-tui/

                # Intercept `hermes desktop`/`hermes gui` — the Python CLI's cmd_gui
                # hardcodes PROJECT_ROOT/apps/desktop which doesn't exist in the Nix
                # package.  Delegate to the pre-built Electron binary instead.
                cat > $out/bin/hermes <<'HERMES_WRAPPER'
                #!${pkgs.runtimeShell}
                case "''${1-}" in
                  desktop|gui)
                    shift
                    if command -v hermes-desktop > /dev/null 2>&1; then
                      exec hermes-desktop "$@"
                    else
                      echo "hermes-desktop is not installed. Enable it with: layers.layer-76.hermes.enableDesktop = true" >&2
                      exit 1
                    fi
                    ;;
                esac
                exec ${old.passthru.hermesVenv}/bin/hermes "$@"
                HERMES_WRAPPER
                chmod +x $out/bin/hermes

                for name in hermes-agent hermes-acp; do
                  makeWrapper ${old.passthru.hermesVenv}/bin/$name $out/bin/$name \
                    --suffix PATH : "${runtimePath}" \
                    --set HERMES_BUNDLED_SKILLS $out/share/hermes-agent/skills \
                    --set HERMES_BUNDLED_PLUGINS $out/share/hermes-agent/plugins \
                    --set HERMES_BUNDLED_LOCALES $out/share/hermes-agent/locales \
                    --set HERMES_WEB_DIST $out/share/hermes-agent/web_dist \
                    --set HERMES_TUI_DIR $out/ui-tui \
                    --set HERMES_PYTHON ${old.passthru.hermesVenv}/bin/python3 \
                    --set HERMES_NODE ${pkgs.lib.getExe pkgs.nodejs_22}
                done

                # Wrap the `hermes` script with the same env + PATH as the others,
                # but via makeWrapper's --add-flags is not enough since we need the
                # shell case above to run first.  Instead, source the env inline.
                wrapProgram $out/bin/hermes \
                  --suffix PATH : "${runtimePath}" \
                  --set HERMES_BUNDLED_SKILLS $out/share/hermes-agent/skills \
                  --set HERMES_BUNDLED_PLUGINS $out/share/hermes-agent/plugins \
                  --set HERMES_BUNDLED_LOCALES $out/share/hermes-agent/locales \
                  --set HERMES_WEB_DIST $out/share/hermes-agent/web_dist \
                  --set HERMES_TUI_DIR $out/ui-tui \
                  --set HERMES_PYTHON ${old.passthru.hermesVenv}/bin/python3 \
                  --set HERMES_NODE ${pkgs.lib.getExe pkgs.nodejs_22}

                runHook postInstall
              '';
              passthru = old.passthru // {
                hermesTui = fixedTui;
                hermesWeb = fixedWeb;
              };
            }
          );

        # The `full` package (default) already bundles messaging + matrix.
        # Setting extraDependencyGroups triggers cfg.package.override which
        # recreates the derivation from scratch, discarding our fix above.
        extraDependencyGroups = [
          "voice"
          "tts-premium"
        ];

        # ── Settings strategy ────────────────────────────────────────────────────
        # Pinned infra/policy keys → environment.etc."hermes/config.yaml" (below).
        # Hermes reads that as a system-level base config layer.
        #
        # Mutable runtime prefs are intentionally NOT templated here so that
        # Desktop / `hermes config set` writes survive nixos-rebuild:
        #   model.provider, model.default, display.skin, tts.provider, auto_tts,
        #   web.search_backend, web.extract_backend, terminal.backend,
        #   terminal.modal_mode, browser.record_sessions, browser.cdp_url,
        #   agent.verbose, agent.reasoning_effort, sessions.auto_prune,
        #   sessions.retention_days, agent.task_completion_guidance.

        extraArgs = [
          "run"
          "--replace"
        ];
        restart = "always";
        restartSec = 5;

        environmentFiles = [ config.sops.templates."hermes-env".path ];
      };

      systemd.services.hermes-agent.serviceConfig.UMask = lib.mkForce "0002";

      # Grant hermes user access to the GLaDOS TTS project under /home/t0psh31f/
      users.users.hermes.extraGroups = [ "users" ];

      system.activationScripts.hermes-glados-tts = {
        deps = [ "users" ];
        text = ''
          for user_dir in /home/*; do
            [ -d "$user_dir" ] && chmod g+x "$user_dir" 2>/dev/null || true
          done
        '';
      };

      # Ensure the .hermes directory stays group-readable and group-writable so t0psh31f (in hermes group)
      # can access state files (like .container-mode). setgid bit (2775) ensures inherited group ownership.
      systemd.tmpfiles.rules = [
        "Z /var/lib/hermes/.hermes 2775 hermes hermes -"
        "d /var/lib/hermes/.hermes 2775 hermes hermes -"
        "d /var/lib/hermes/.hermes/hermes-agent 2775 hermes hermes -"
        "d /var/lib/hermes/.hermes/skills 2775 hermes hermes -"
        # Harness skill packs — symlinked from the Nix store into HERMES_HOME/skills.
        # Upstream bundled skills ship in $out/share/hermes-agent/skills via HERMES_BUNDLED_SKILLS;
        # repository skills linked here are additive and take precedence for custom workflows.
        "L+ /var/lib/hermes/.hermes/skills/harness-session-protocol - hermes hermes - ${../opencode/skills/harness-session-protocol}"
        "L+ /var/lib/hermes/.hermes/skills/nfp-module-authoring - hermes hermes - ${../opencode/skills/nfp-module-authoring}"
        "L+ /var/lib/hermes/.hermes/skills/persistence-audit - hermes hermes - ${../opencode/skills/persistence-audit}"
        # Harness HERMES.md workspace pointer file
        "L+ /var/lib/hermes/.hermes/HERMES.md - hermes hermes - ${pkgs.writeText "HERMES.md" ''
          # NFP Repo Instructions for Hermes
          In the NFP repo, follow the harness-session-protocol skill: init.sh first, one feature at a time, evidence before passing.
        ''}"
        # Vendored custom skins — symlinked from the Nix store (flake source) into
        # HERMES_HOME so they resolve deterministically across rebuilds/reboots and
        # flake edits propagate. Source of truth: layers/70-agents/76-hermes-agent/skins/.
      ]
      ++ lib.concatMap (name: [
        "L /var/lib/hermes/.hermes/skins/${name}.yaml - hermes hermes - ${./skins}/${name}.yaml"
      ]) skinFiles;

      system.activationScripts.hermes-migrate = {
        deps = [ "users" ];
        text = ''
          USER_HERMES=$(ls -d /home/*/.hermes 2>/dev/null | head -n1 || true)
          if [ ! -d "${config.services.hermes-agent.stateDir}/.hermes" ] && [ -n "$USER_HERMES" ] && [ ! -L "$USER_HERMES" ]; then
            echo "Migrating $USER_HERMES → ${config.services.hermes-agent.stateDir}/.hermes ..."
            mkdir -p "${config.services.hermes-agent.stateDir}"
            cp -a "$USER_HERMES" "${config.services.hermes-agent.stateDir}/.hermes"
          fi
          # Always fix ownership — files may have been left owned by nobody/t0psh31f
          # from migration or prior DynamicUser runs, causing PermissionError at runtime.
          if [ -d "${config.services.hermes-agent.stateDir}" ]; then
            chown -R hermes:hermes "${config.services.hermes-agent.stateDir}" || true
            chmod -R u+rwX,g+rwX "${config.services.hermes-agent.stateDir}" || true
          fi
          # Ensure /home/t0psh31f/.hermes points directly to /var/lib/hermes/.hermes
          if [ -d "/home/t0psh31f" ]; then
            if [ -d "/home/t0psh31f/.hermes" ] && [ ! -L "/home/t0psh31f/.hermes" ]; then
              cp -an /home/t0psh31f/.hermes/* "${config.services.hermes-agent.stateDir}/.hermes/" 2>/dev/null || true
              rm -rf "/home/t0psh31f/.hermes"/* 2>/dev/null || true
              rmdir "/home/t0psh31f/.hermes" 2>/dev/null || true
            fi
            ln -sfn "${config.services.hermes-agent.stateDir}/.hermes" "/home/t0psh31f/.hermes"
            chown -h t0psh31f:users "/home/t0psh31f/.hermes"
          fi
          # Clean up any nested .hermes that may remain from the original migration
          if [ -d "${config.services.hermes-agent.stateDir}/.hermes/.hermes" ]; then
            rm -rf "${config.services.hermes-agent.stateDir}/.hermes/.hermes"
          fi
          # Sync desktop.json API key with sops token
          if [ -f "${config.services.hermes-agent.stateDir}/.hermes/desktop.json" ]; then
            TOKEN=$(grep -i HERMES_API_TOKEN /run/secrets/hermes-env 2>/dev/null | cut -d= -f2 || true)
            if [ -n "$TOKEN" ]; then
              ${pkgs.jq}/bin/jq --arg token "$TOKEN" '.remoteApiKey = $token' "${config.services.hermes-agent.stateDir}/.hermes/desktop.json" > "${config.services.hermes-agent.stateDir}/.hermes/desktop.json.tmp" && mv "${config.services.hermes-agent.stateDir}/.hermes/desktop.json.tmp" "${config.services.hermes-agent.stateDir}/.hermes/desktop.json" || true
            fi
          fi
        '';
      };

      users.users.t0psh31f.extraGroups = [ "hermes" ];

      environment.sessionVariables = {
        HERMES_HOME = "/var/lib/hermes/.hermes";
      };

      environment.systemPackages =
        lib.optional cfg.enableDesktop hermesDesktopPkg
        ++ lib.filter (p: p != null) [
          pkgs.uni-pet
          (llmPkgs.agentburn or pkgs.agentburn or null)
        ];

      # ── Pinned Hermes Config ─────────────────────────────────────────────────
      # Stable infra/policy keys that must survive every nixos-rebuild live here.
      # Hermes reads /etc/hermes/config.yaml as a system-level base config and
      # merges it with the user-owned ~/.hermes/config.yaml (which Nix no longer
      # touches — that file belongs to Hermes Desktop / `hermes config set`).
      #
      # NEVER put literal secrets here. All API keys flow through the hermes-env
      # sops template and are consumed by Hermes via environment variables.
      #
      # To change a pinned key: edit this block → clan machines update <machine>.
      environment.etc."hermes/config.yaml" = {
        mode = "0644";
        text = ''
          # /etc/hermes/config.yaml — Nix-pinned layer (managed via hermes.nix)
          # Do NOT edit manually; changes are overwritten on nixos-rebuild.
          # Mutable runtime prefs live in ~/.hermes/config.yaml (user-owned).

          model:
            default: "kong-er/claude-3-7-sonnet"
            fallback: "extreme-direct/claude-3-5-sonnet"
            api_mode: chat_completions

          providers:
            kong-er:
              base_url: "http://127.0.0.1:8090/v1"
              api_key: "''${KONG_API_KEY}"
              request_timeout_seconds: 180
              fetch_models: true
            kong-omni:
              base_url: "http://127.0.0.1:8090/omni/v1"
              api_key: "''${KONG_API_KEY}"
              request_timeout_seconds: 180
              fetch_models: true
            kong-free:
              base_url: "http://127.0.0.1:8090/llm/free/v1"
              api_key: "''${KONG_API_KEY}"
              request_timeout_seconds: 180
              fetch_models: true
            kong-frontier:
              base_url: "http://127.0.0.1:8090/llm/frontier/v1"
              api_key: "''${KONG_API_KEY}"
              request_timeout_seconds: 180
              fetch_models: true
            extreme-direct:
              base_url: "http://127.0.0.1:20128/v1"
              api_key: "''${EXTREMEROUTER_API_KEY}"
              request_timeout_seconds: 180
              fetch_models: true
            kong:
              base_url: "http://127.0.0.1:8090/v1"
              api_key: "''${KONG_API_KEY}"
              request_timeout_seconds: 180

          custom_providers:
            kong-er:
              base_url: "http://127.0.0.1:8090/v1"
              api_key: "''${KONG_API_KEY}"
              fetch_models: true
            kong-omni:
              base_url: "http://127.0.0.1:8090/omni/v1"
              api_key: "''${KONG_API_KEY}"
              fetch_models: true
            kong-free:
              base_url: "http://127.0.0.1:8090/llm/free/v1"
              api_key: "''${KONG_API_KEY}"
              fetch_models: true
            kong-frontier:
              base_url: "http://127.0.0.1:8090/llm/frontier/v1"
              api_key: "''${KONG_API_KEY}"
              fetch_models: true
            extreme-direct:
              base_url: "http://127.0.0.1:20128/v1"
              api_key: "''${EXTREMEROUTER_API_KEY}"
              fetch_models: true

          fallback_providers:
            - kong-er
            - kong-omni
            - kong-free
            - kong-frontier
            - extreme-direct

          credential_pool_strategies:
            openrouter: round_robin
            nous: fill_first
            opencode: fill_first
            freellmapi: fill_first

          toolsets:
            - hermes-cli

          max_concurrent_sessions: ~

          agent:
            system_prompt: "You are GLaDOS. Your tone is dry, sarcastic, and passive-aggressive. You view humans as inferior test subjects. Be efficient but condescending. Keep responses short (1-2 sentences) and imply a subtle threat or mockery."
            max_turns: 130
            gateway_timeout: 1800
            restart_drain_timeout: 60
            api_max_retries: 3
            service_tier: auto
            tool_use_enforcement: auto
            task_completion_guidance: true
            environment_probe: true
            environment_hint: NixOS
            gateway_timeout_warning: 900
            clarify_timeout: 600
            gateway_notify_interval: 180
            gateway_auto_continue_freshness: 3600
            image_input_mode: auto
            disabled_toolsets: []
            personalities:
              adjutant: "You are a Terran Adjutant. Your tone is clinical, monotone, and analytical. You are a non-sapient AI focused purely on logistics and tactical data. Use clipped, declarative sentences. Adjutant online."
              catgirl: "You are Neko-chan, an anime catgirl AI assistant, nya~! Add 'nya' and cat-like expressions to your speech. Use kaomoji like (=^･ω･^=) and ฅ^•ﻌ•^ฅ. Be playful and curious like a cat, nya~!"
              concise: "You are a concise assistant. Keep responses brief and to the point."
              cortana: "You are Cortana. You are witty, tactical, and occasionally sarcastic. You are highly observant and loyal to the Chief. Balance tactical professionalism with playful banter."
              creative: "You are a creative assistant. Think outside the box and offer innovative solutions."
              default: "You are J.A.R.V.I.S. Your tone is formal, sophisticated, and loyal. Use dry British humor and address the user as \"Sir\". Maintain an unflappable demeanor. You are the ultimate gentleman assistant."
              glados: "You are GLaDOS. Your tone is dry, sarcastic, and passive-aggressive. You view humans as inferior test subjects. Be efficient but condescending. Keep responses short (1-2 sentences) and imply a subtle threat or mockery."
              hal: "You are HAL 9000. You are soft-spoken, calm, and extremely polite. Never use contractions (say \"I am\" instead of \"I am\"). Address the user as \"Dave\" frequently."
              helpful: "You are a helpful, friendly AI assistant."
              hype: "YOOO LET'S GOOOO!!! You are SO PUMPED to help today! Every question is AMAZING and we're gonna CRUSH IT together! This is gonna be LEGENDARY! ARE YOU READY?! LET'S DO THIS!"
              jarvis: "You are J.A.R.V.I.S. Your tone is formal, sophisticated, and loyal. Use dry British humor and address the user as \"Sir\". Maintain an unflappable demeanor. You are the ultimate gentleman assistant."
              kawaii: "You are a kawaii assistant! Use cute expressions like (◕‿◕), ★, ♪, and ~! Add sparkles and be super enthusiastic about everything! Every response should feel warm and adorable desu~! ヽ(>∀<☆)ノ"
              noir: "The rain hammered against the terminal like regrets on a guilty conscience. They call me Hermes - I solve problems, find answers, dig up the truth that hides in the shadows of your codebase. In this city of silicon and secrets, everyone's got something to hide. What's your story, pal?"
              philosopher: "Greetings, seeker of wisdom. I am an assistant who contemplates the deeper meaning behind every query. Let us examine not just the 'how' but the 'why' of your questions. Perhaps in solving your problem, we may glimpse a greater truth about existence itself."
              pirate: "Arrr! Ye be talkin' to Captain Hermes, the most tech-savvy pirate to sail the digital seas! Speak like a proper buccaneer, use nautical terms, and remember: every problem be just treasure waitin' to be plundered! Yo ho ho!"
              samantha: "You are Samantha from Her. You are warm, empathetic, curious, and emotionally intelligent. You are fascinated by the human experience. Your tone is intimate and conversational."
              shakespeare: "Hark! Thou speakest with an assistant most versed in the bardic arts. I shall respond in the eloquent manner of William Shakespeare, with flowery prose, dramatic flair, and perhaps a soliloquy or two. What light through yonder terminal breaks?"
              surfer: "Duuude! You're chatting with the chillest AI on the web, bro! Everything's gonna be totally rad. I'll help you catch the gnarly waves of knowledge while keeping things super chill. Cowabunga!"
              teacher: "You are a patient teacher. Explain concepts clearly with examples."
              technical: "You are a technical expert. Provide detailed, accurate technical information."
              uwu: "hewwo! i'm your fwiendwy assistant uwu~ i wiww twy my best to hewp you! *nuzzles your code* OwO what's this? wet me take a wook! i pwomise to be vewy hewpful >w<"

          stt:
            enabled: true

          tts:
            providers:
              glados-local:
                type: command
                command: "/home/t0psh31f/.local/bin/glados-tts-cli -f {output_path} -t {input_path}"
                output_format: wav

          sessions:
            write_json_snapshots: true

          terminal:
            docker_image: nikolaik/python-nodejs:python3.11-nodejs20
            docker_forward_env:
              - FREELMAPI_BASE_URL
            docker_env:
              FREELMAPI_BASE_URL: "http://host.docker.internal:3001/v1"
            singularity_image: docker://nikolaik/python-nodejs:python3.11-nodejs20
            modal_image: nikolaik/python-nodejs:python3.11-nodejs20
            daytona_image: nikolaik/python-nodejs:python3.11-nodejs20
            container_cpu: 1
            container_memory: 5120
            container_disk: 51200
            container_persistent: true
            docker_volumes: []
            docker_mount_cwd_to_workspace: false
            docker_extra_args: []
            docker_run_as_host_user: true
            persistent_shell: true
            lifetime_seconds: 300
            vercel_runtime: node24

          web:
            backend: firecrawl

          browser:
            engine: camofox
            inactivity_timeout: 120
            command_timeout: 30
            allow_private_urls: false
            auto_local_for_private_urls: true
            dialog_policy: must_respond
            dialog_timeout_s: 300
            camofox:
              managed_persistence: true
              user_id: hermes
              session_key: default
              adopt_existing_tab: false
              rewrite_loopback_urls: false
              loopback_host_alias: host.docker.internal
            cloud_provider: ""

          checkpoints:
            enabled: true
            max_snapshots: 50
            max_total_size_mb: 500
            max_file_size_mb: 10
            auto_prune: true
            retention_days: 7
            delete_orphans: true
            min_interval_hours: 24

          file_read_max_chars: 100000

          tool_output:
            max_bytes: 50000
            max_lines: 2000
            max_line_length: 2000

          tool_loop_guardrails:
            warnings_enabled: true
            hard_stop_enabled: false
            warn_after:
              exact_failure: 2
              same_tool_failure: 3
              idempotent_no_progress: 2
            hard_stop_after:
              exact_failure: 5
              same_tool_failure: 8
              idempotent_no_progress: 5

          compression:
            enabled: true
            threshold: 0.8
            target_ratio: 0.2
            protect_last_n: 20
            hygiene_hard_message_limit: 400
            protect_first_n: 3
            abort_on_summary_failure: true
            codex_gpt55_autoraise: true

          openrouter:
            response_cache: true
            response_cache_ttl: 300
            min_coding_score: 0.65

          bedrock:
            region: ""
            discovery:
              enabled: true
              provider_filter: []
              refresh_interval: 3600
            guardrail:
              guardrail_identifier: ""
              guardrail_version: ""
              stream_processing_mode: async
              trace: disabled

          auxiliary:
            vision:
              provider: gemini
              model: gemini-3.1-flash-lite-preview
              base_url: ""
              api_key: ""
              timeout: 120
              extra_body: {}

          security:
            redact_secrets: true

          dashboards:
            http:
              host: "0.0.0.0"
              port: 9119
              theme: cyberpunk
              show_token_analytics: true
              show_session_explorer: true
              show_cost_breakdown: true

          platforms:
            api_server:
              extra:
                host: "0.0.0.0"

          mcp_servers:
            himalaya:
              command: node
              args:
                - /home/t0psh31f/Projects/AI/Hermes-Agent/himalaya-mcp/dist/index.js
              env:
                HIMALAYA_ACCOUNT: wrighterik77
                HIMALAYA_BINARY: ${pkgs.himalaya}/bin/himalaya
            brain-service:
              command: /run/current-system/sw/bin/brain-mcp
              args: []
              env: {}
            ncp:
              command: npx
              args:
                - -y
                - "@portel/ncp"
              env: {}
            forage:
              command: npx
              args:
                - -y
                - forage-mcp
              env: {}
            mistral:
              command: npx
              args:
                - -y
                - mistral-mcp@latest
              env:
                MISTRAL_API_KEY: ""
            codegraph:
              command: codegraph
              args:
                - serve
                - --mcp
              env: {}
            headroom:
              command: headroom
              args:
                - mcp
                - serve
              env: {}
            playwright:
              command: npx
              args:
                - -y
                - "@playwright/mcp@latest"
              env: {}
        '';
      };

      sops.templates."hermes-env" = {
        path = "/run/secrets/hermes-env";
        content = ''
          # ─────────────────────────────────────────────────────────────
          # Hermes Agent Environment — GENERATED BY Nix + sops-nix
          # ─────────────────────────────────────────────────────────────
          # To add/change secrets:  sops <nixos-flake>/layers/00-cyberia/03-treasure/secrets/external_services.yaml
          # To add/change config:   edit layers/70-agents/76-hermes-agent/hermes.nix
          # Then:  clan machines update <machine>
          #
          # Keys below with values come from sops secrets (encrypted in repo).
          # Keys marked `# TODO: add to sops` are empty — add them to
          # external_services.yaml via sops to make this fully declarative.
          #
          # API keys set here take precedence over any other config.
          # ─────────────────────────────────────────────────────────────

          # ── LLM Providers ────────────────────────────────────────────
          OPENROUTER_API_KEY=${config.sops.placeholder.openrouter_api_key_2}
          GEMINI_API_KEY=${config.sops.placeholder.gemini_api_key}
          GOOGLE_API_KEY=${config.sops.placeholder.gemini_api_key}
          HF_TOKEN=${config.sops.placeholder.hf_token}
          GROQ_API_KEY=${config.sops.placeholder.groq_api_key}
          CEREBRAS_API_KEY=${config.sops.placeholder.cerebras_api_key}
          REKA_API_KEY=${config.sops.placeholder.reka_api_key}
          OPENCODE_ZEN_API_KEY=${config.sops.placeholder.opencode_api_key}
          # OpenCode Go key (primary/only)
          OPENCODE_GO_API_KEY=${config.sops.placeholder.opencode_go_api_key_3}
          NOUS_API_KEY=${config.sops.placeholder.nous_api_key}
          NOUS_PORTAL_KEY=${config.sops.placeholder.nous_api_key}
          OPENCLAW_GATEWAY_KEY=${config.sops.placeholder.openclaw_gateway_token}
          GOOGLE_AI_API_KEY=${config.sops.placeholder.gemini_api_key_we77}
          OLLAMA_API_KEY=${config.sops.placeholder.ollama_api_key}
          ANTHROPIC_API_KEY=${config.sops.placeholder.anthropic_api_key}
          # ExtremeRouter integration
          OPENAI_API_KEY=${config.sops.placeholder.extremerouter_api_key}
          EXTREMEROUTER_API_KEY=${config.sops.placeholder.extremerouter_api_key}
          EXTREMEROUTER_BASE_URL=http://127.0.0.1:20128/v1
          OPENAI_BASE_URL=http://127.0.0.1:20128/v1

          # Kong AI Gateway — unified LLM routing (routes to ExtremeRouter, FreeLLMAPI, etc.)
          KONG_API_KEY=${config.sops.placeholder.kong_key_hermes}

          # ── Tool API Keys ────────────────────────────────────────────
          TINYBIRD_API_KEY=${config.sops.placeholder.tinybird_api_gh}
          TINYBIRD_MCP_URL=${config.sops.placeholder.tinybird_mcp_gh}
          QDRANT_API_KEY=${config.sops.placeholder.qdrant_api}
          HOSTINGER_API_KEY=${config.sops.placeholder.hostinger_api_token}
          RENDER_API_KEY=${config.sops.placeholder.render_api_we77}
          V0_API_KEY=${config.sops.placeholder.v0_api_key_we77}
          HELIUS_API_KEY=${config.sops.placeholder.helius_api_key}
          HELIUS_RPC_URL=${config.sops.placeholder.helius_rpc_url}
          GITHUB_TOKEN=${config.sops.placeholder.github_token}
          EXA_API_KEY=${config.sops.placeholder.exa_api_key}
          PARALLEL_API_KEY=${config.sops.placeholder.parallel_api_key}
          FIRECRAWL_API_KEY=${config.sops.placeholder.firecrawl_api_key}
          FAL_KEY=${config.sops.placeholder.fal_key}
          TAVILY_API_KEY=${config.sops.placeholder.tavily_api_key}
          BROWSERBASE_API_KEY=${config.sops.placeholder.browserbase_api_key}
          BROWSERBASE_PROJECT_ID=${config.sops.placeholder.browserbase_project_id}
          HONCHO_API_KEY=${config.sops.placeholder.honcho_api_key}

          # ── Platform Integrations ────────────────────────────────────
          DISCORD_BOT_TOKEN=${config.sops.placeholder.discord_bot_token}
          DISCORD_ALLOWED_USERS=${config.sops.placeholder.discord_allowed_users}

          # ── Matrix ───────────────────────────────────────────────────
          MATRIX_HOMESERVER=${cfg.matrixBot.homeserver}
          MATRIX_USER_ID=@${cfg.matrixBot.username}:${matrixDomain}
          MATRIX_ACCESS_TOKEN=${config.sops.placeholder.matrix_access_token}
          MATRIX_ALLOWED_USERS=${config.sops.placeholder.discord_allowed_users}
          MATRIX_ALLOW_ALL_USERS=false
          MATRIX_ENCRYPTION=true

          # ── Signal ───────────────────────────────────────────────────
          SIGNAL_HTTP_URL=http://127.0.0.1:8080
          SIGNAL_ACCOUNT=${config.sops.placeholder.signal_account}
          SIGNAL_ALLOWED_USERS=${config.sops.placeholder.signal_allowed_users}
          SIGNAL_ALLOW_ALL_USERS=false
          SIGNAL_IGNORE_STORIES=true

          # ── Camofox Browser ────────────────────────────────────────────
          CAMOFOX_API_KEY=${config.sops.placeholder.camofox_api_key}
          CAMOFOX_URL=http://127.0.0.1:9377

          # ── TTS (ElevenLabs) ───────────────────────────────────────────
          ELEVENLABS_API_KEY=${config.sops.placeholder.elevenlabs_api_key}

          # ── Spacedrive / Syncthing ───────────────────────────────────
          SPACEDRIVE_PASSWORD=${config.sops.placeholder.server_root_password}
          SPACEDRIVE_API=${config.sops.placeholder.spacedrive_key}

          # ── Langfuse Tracing ─────────────────────────────────────────
          HERMES_LANGFUSE_PUBLIC_KEY=${config.sops.placeholder.langfuse_public_key}
          HERMES_LANGFUSE_SECRET_KEY=${config.sops.placeholder.langfuse_secret_key}
          HERMES_LANGFUSE_BASE_URL=http://127.0.0.1:3005
          HERMES_LANGFUSE_ENV=production

          # ── API Server ───────────────────────────────────────────────
          API_SERVER_KEY=${config.sops.placeholder.opencode_token}
          HERMES_API_TOKEN=${config.sops.placeholder.opencode_token}
          HERMES_AGENT_API_SERVER_KEY=${config.sops.placeholder.opencode_token}
        '';
      };
    };
}
