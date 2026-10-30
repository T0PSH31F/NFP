# flake-parts/users/t0psh31f.nix
{
  pkgs,
  config,
  inputs,
  ...
}:
{
  programs = {
    zsh.enable = true;
  };

  # System-level user settings managed via Clan core users module
  users.users.t0psh31f = {
    isNormalUser = true;
    home = "/home/t0psh31f";
    description = "t0psh31f";
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
      "input"
      "podman"
      "libvirtd"
      "media"
      "i2c"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJrQr8qxQTw45PNpsDNahVE23tpV3Zap+IKr6eVkL75Z t0psh31f@grandlix.gang"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDg4e32XqA2CyYsHyl+urGN1Soiz00DLgc+dkDw/uFCw luffy@agentaflow.com"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPpWmwkiOcnicpKOcE3kiJ4bYgiawDBQpcnmm1Ljics7 t0psh31f@sanji"
    ];
  };

  # Home Manager configuration for t0psh31f
  home-manager = {
    # Permanent fix for backup collisions: Automatically remove old backups before activation
    backupFileExtension = "hm-backup";
    backupCommand = "${pkgs.writeShellScript "hm-backup-cleanup" ''
      set -eu
      # Use the extension defined in backupFileExtension
      EXT="hm-backup"
      FILE="$1"
      BACKUP="$FILE.$EXT"

      # If a backup already exists, remove it so HM can create a new one
      if [ -e "$BACKUP" ]; then
        rm -rf "$BACKUP"
      fi
    ''}";
    extraSpecialArgs = { inherit inputs; };
    users.t0psh31f =
      let
        # Captured from the outer NixOS config (the top-level `config` of this
        # file), before it's shadowed below by the home-manager submodule's
        # own `config` argument.
        cliEnabled = config.layers.layer-50.cli.enable or true;
      in
      { config, lib, ... }:
      {
        imports = [
          ../../80-lib/81-helpers/hm-bridge.nix
          inputs.sops-nix.homeManagerModules.sops
          inputs.vicinae.homeManagerModules.default
        ];

        config = {
          _module.args.lib = lib.extend (
            _final: _prev: {
              hm = inputs.home-manager.lib.hm;
            }
          );

          sops = {
            age.keyFile = "/home/t0psh31f/.config/sops/age/keys.txt";

            secrets = {
              git_name = {
                sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/git.yaml;
                format = "yaml";
              };
              git_email = {
                sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/git.yaml;
                format = "yaml";
              };
            };
          };

          # Vicinae secrets (API keys, tokens, etc.)
          sops.secrets."vicinae.json" = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/vicinae.yaml;
            format = "yaml";
          };

          # AI/LLM API Keys
          sops.secrets.gemini_api_key = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/vicinae.yaml;
            format = "yaml";
          };
          sops.secrets.openrouter_api_key = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/vicinae.yaml;
            format = "yaml";
          };

          # External Services Secrets
          sops.secrets.server_root_password = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.spacedrive_key = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.openclaw_gateway_token = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.gemini_api_key_lovelain = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.gemini_api_key_we77 = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.openrouter_api_key_1 = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.openrouter_api_key_2 = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.openrouter_api_key_3 = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.groq_api_key = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.reka_api_key = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.cerebras_api_key = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.ai21_api_key = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.cohere_api_key = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.hf_token = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.jules_api_key_ll = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.v0_api_key_we77 = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.github_models_api = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.helius_api_key = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.helius_rpc_url = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.solsniper_x_api_consumer_key = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.solsniper_x_api_secret_key = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.solsniper_x_api_bearer_token = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.solsniper_x_api_client_id = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.solsniper_x_api_client_secret = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.supabase_password = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.supabase_api_key = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.lovelain_api_key_ext = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
            key = "lovelain_api_key";
          };
          sops.secrets.neon_postgres_api = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.cloudflare_workers_api_we77 = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.cloudflare_workers_api_lovelain = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.cloudflare_workers_api_lovelain_full = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.cloudflare_access_id = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.scaleway_gh_access_key = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.scaleway_gh_secret_key = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.scaleway_gh_org_id = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.scaleway_gh_project_id = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.render_api_we77 = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.apify_api_we77 = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.google_stitch_api_we77 = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.tinybird_api_gh = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.tinybird_mcp_gh = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.nexsos_api = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.hostinger_api_token_ext = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
            key = "hostinger_api_token";
          };
          sops.secrets.qdrant_api = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.google_oauth_lovelain_client_id = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.google_oauth_lovelain_client_secret = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.opencode_token = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.grafana_pass = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.beszel_lovelain_pass = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.maxkb_pass = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.browser_use_api = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.context7_api_we77 = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.tg_botfather_http = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };

          # ── Gmail App Passwords (for himalaya email client) ───────
          sops.secrets.gmail_app_password_wrighterik77 = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.gmail_app_password_lovelainautomations = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };

          # ── Hermes Agent API Keys ──────────────────────────────────
          sops.secrets.discord_bot_token = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.discord_allowed_users = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.github_token = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.opencode_api_key = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.nous_api_key = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.ollama_api_key = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.anthropic_api_key = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.browserbase_api_key = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.browserbase_project_id = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.exa_api_key = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.parallel_api_key = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.tavily_api_key = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.firecrawl_api_key = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.fal_key = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.honcho_api_key = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.nvidia_api_key = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.langfuse_public_key = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.langfuse_secret_key = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };

          # ── Kong AI Gateway & Primary Router Keys ──────────────────
          sops.secrets.kong_key_hermes = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.kong_key_hermes_voice = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.kong_key_voice = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.kong_key_pi = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.kong_key_opencode = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.kong_key_claude_code = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.kong_key_codex = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.extremerouter_api_key = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };
          sops.secrets.omniroute_api_key = {
            sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
          };

          # Note: rclone.conf is persisted dynamically via impermanence
          # (/persist/home/t0psh31f/.config/rclone/rclone.conf) to support interactive OAuth token refreshes.

          sops.templates."git-config".content = ''
            [user]
              name = ${config.sops.secrets.git_name.path}
              email = ${config.sops.secrets.git_email.path}
          '';

          # Include the sops-templated git identity here (not in
          # layers/50-cli-tui-programs/53-tools/git.nix), because this is the
          # actual home-manager submodule scope where `sops.templates` exists.
          programs.git.includes = [
            { path = config.sops.templates."git-config".path; }
          ];

          # Global .env file on Desktop for projects
          sops.templates."desktop-env" = {
            path = "${config.home.homeDirectory}/Desktop/.env";
            content = ''
              SERVER_ROOT_PASSWORD=${config.sops.placeholder.server_root_password}
              SPACEDRIVE_KEY=${config.sops.placeholder.spacedrive_key}
              OPENCLAW_GATEWAY_TOKEN=${config.sops.placeholder.openclaw_gateway_token}

              # AI Services
              GEMINI_API_KEY_LOVELAIN=${config.sops.placeholder.gemini_api_key_lovelain}
              GEMINI_API_KEY_WE77=${config.sops.placeholder.gemini_api_key_we77}
              OPENROUTER_API_KEY_1=${config.sops.placeholder.openrouter_api_key_1}
              OPENROUTER_API_KEY_2=${config.sops.placeholder.openrouter_api_key_2}
              OPENROUTER_API_KEY_3=${config.sops.placeholder.openrouter_api_key_3}
              GROQ_API_KEY=${config.sops.placeholder.groq_api_key}
              REKA_API_KEY=${config.sops.placeholder.reka_api_key}
              CEREBRAS_API_KEY=${config.sops.placeholder.cerebras_api_key}
              AI21_API_KEY=${config.sops.placeholder.ai21_api_key}
              COHERE_API_KEY=${config.sops.placeholder.cohere_api_key}
              HF_TOKEN=${config.sops.placeholder.hf_token}
              JULES_API_KEY_LL=${config.sops.placeholder.jules_api_key_ll}
              V0_API_KEY_WE=${config.sops.placeholder.v0_api_key_we77}
              GITHUB_MODELS_API=${config.sops.placeholder.github_models_api}

              # Infrastructure & Cloud
              HELIUS_API_KEY=${config.sops.placeholder.helius_api_key}
              SUPABASE_API_KEY=${config.sops.placeholder.supabase_api_key}
              CLOUDFLARE_ACCESS_ID=${config.sops.placeholder.cloudflare_access_id}
              CLOUDFLARE_LOVELAIN_WORKERS=${config.sops.placeholder.cloudflare_workers_api_lovelain}
              CLOUDFLARE_WE77_WORKERS=${config.sops.placeholder.cloudflare_workers_api_we77}
              SCW_GH_ACCESS_KEY=${config.sops.placeholder.scaleway_gh_access_key}
              SCW_GH_SECRET_KEY=${config.sops.placeholder.scaleway_gh_secret_key}
              RENDER_API_WE=${config.sops.placeholder.render_api_we77}
              APIFY_API_WE77=${config.sops.placeholder.apify_api_we77}
              TINYBIRD_API_GH=${config.sops.placeholder.tinybird_api_gh}
              STITCH_API_WE77=${config.sops.placeholder.google_stitch_api_we77}
              CONTEXT7_API_WE=${config.sops.placeholder.context7_api_we77}
              HOSTINGER_API_TOKEN=${config.sops.placeholder.hostinger_api_token_ext}
              QDRANT_API=${config.sops.placeholder.qdrant_api}
            '';
          };

          # Home configuration
          home = {
            stateVersion = "25.05";
            username = "t0psh31f";
            homeDirectory = "/home/t0psh31f";

            # Export API keys as environment variables
            sessionVariables = {
              GEMINI_API_KEY = "$(cat ${config.sops.secrets.gemini_api_key_we77.path})";
              OPENROUTER_API_KEY = "$(cat ${config.sops.secrets.openrouter_api_key.path})";
              KONG_API_KEY = "$(cat ${config.sops.secrets.kong_key_hermes.path})";
              KONG_KEY_PI = "$(cat ${config.sops.secrets.kong_key_pi.path})";
              KONG_KEY_OPENCODE = "$(cat ${config.sops.secrets.kong_key_opencode.path})";
              KONG_KEY_CLAUDE_CODE = "$(cat ${config.sops.secrets.kong_key_claude_code.path})";
              ANTHROPIC_AUTH_TOKEN = "$(cat ${config.sops.secrets.kong_key_claude_code.path})";
              KONG_KEY_CODEX = "$(cat ${config.sops.secrets.kong_key_codex.path})";
              KONG_KEY_HERMES = "$(cat ${config.sops.secrets.kong_key_hermes.path})";
              KONG_KEY_HERMES_VOICE = "$(cat ${config.sops.secrets.kong_key_hermes_voice.path})";
              KONG_KEY_VOICE = "$(cat ${config.sops.secrets.kong_key_voice.path})";
              EXTREMEROUTER_API_KEY = "$(cat ${config.sops.secrets.extremerouter_api_key.path})";
            };

            packages = [
              # spacedrive — refused to evaluate in this nixpkgs rev
            ];

            # Envoluntary configuration
            file.".config/envoluntary/config.toml".text = ''
              [[entries]]
              pattern = ".*/Clan/NFP(/.*)?"
              flake_reference = "path:${config.home.homeDirectory}/Clan/NFP"

              [[entries]]
              pattern = ".*/Projects/n8n-sorting-nix(/.*)?"
              flake_reference = "path:${config.home.homeDirectory}/Projects/n8n-sorting-nix"

              [[entries]]
              pattern = ".*/Projects/python(/.*)?"
              flake_reference = "nixpkgs#python313"

              [[entries]]
              pattern = ".*/Projects/typescript(/.*)?|.*/Projects/node(/.*)?"
              flake_reference = "nixpkgs#nodejs_22"

              [[entries]]
              pattern = ".*/Projects/rust(/.*)?"
              flake_reference = "nixpkgs#rustc"

              [[entries]]
              pattern = ".*/Projects/go(/.*)?"
              flake_reference = "nixpkgs#go"

              [[entries]]
              pattern = ".*/Projects/php(/.*)?"
              flake_reference = "nixpkgs#php"

              [[entries]]
              pattern = ".*/Projects/ruby(/.*)?"
              flake_reference = "nixpkgs#ruby"

              [[entries]]
              pattern = ".*/Projects/ocaml(/.*)?"
              flake_reference = "nixpkgs#ocaml"

              [[entries]]
              pattern = ".*/Projects/latex(/.*)?"
              flake_reference = "nixpkgs#texlive.combined.scheme-full"

              [[entries]]
              pattern = ".*/Projects/markdown(/.*)?|.*/Projects/docs(/.*)?"
              flake_reference = "nixpkgs#nix-shell"

              [[entries]]
              pattern = ".*/Projects(/.*)?"
              flake_reference = "nixpkgs#nix-shell"
            '';
          };

          # Himalaya email client config (see layers/50-cli-tui-programs/53-tools/himalaya.nix
          # for the package install). Lives here because it needs this home-manager
          # submodule's own `config.sops.secrets`, not the outer NixOS config.
          xdg.configFile."himalaya/config.toml".text = lib.mkIf cliEnabled (
            let
              wrighterik77Pass = config.sops.secrets.gmail_app_password_wrighterik77.path;
              lovelainautomationsPass = config.sops.secrets.gmail_app_password_lovelainautomations.path;
            in
            ''
              # Himalaya email client configuration
              # Multi-account Gmail setup for OpenCode + Hermes shared pipeline
              # Format: himalaya v2.2+
              # Passwords managed via SOPS secrets

              # ==============================================================================
              # Account: wrighterik77 (default)
              # ==============================================================================
              [accounts.wrighterik77]
              email = "wrighterik77@gmail.com"
              default = true

              imap.server = "imaps://imap.gmail.com:993"
              imap.sasl.plain.username = "wrighterik77@gmail.com"
              imap.sasl.plain.password.cmd = "cat ${wrighterik77Pass}"

              smtp.server = "smtps://smtp.gmail.com:465"
              smtp.sasl.plain.username = "wrighterik77@gmail.com"
              smtp.sasl.plain.password.cmd = "cat ${wrighterik77Pass}"

              # ==============================================================================
              # Account: lovelainautomations
              # ==============================================================================
              [accounts.lovelainautomations]
              email = "lovelainautomations@gmail.com"

              imap.server = "imaps://imap.gmail.com:993"
              imap.sasl.plain.username = "lovelainautomations@gmail.com"
              imap.sasl.plain.password.cmd = "cat ${lovelainautomationsPass}"

              smtp.server = "smtps://smtp.gmail.com:465"
              smtp.sasl.plain.username = "lovelainautomations@gmail.com"
              smtp.sasl.plain.password.cmd = "cat ${lovelainautomationsPass}"
            ''
          );
        };
      };
  };
}
