# Tier: 73-memory
# Module: brain-service.nix
# Purpose: PKB RAG service — ingestion, indexing, and vector query API for notes/documents.
# Option Path: services.ai-services.brain-service
# Enabling Host Tags: pkb-node, ai-server, homelab
# RAM Footprint: medium (300MB-1GB)
{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.services.ai-services.brain-service = {
    enable = lib.mkEnableOption "Brain Service (FastAPI + LlamaIndex + PGVector PKB)";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8010;
      description = "HTTP API port";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Host IP to bind the API server to (set to 127.0.0.1 for local access, 0.0.0.0 for LAN/public access)";
    };

    llmApiBase = lib.mkOption {
      type = lib.types.str;
      default = "https://openrouter.ai/api/v1";
      description = "OpenAI compatible base URL (used only when llmProvider = \"openai\")";
    };

    llmModel = lib.mkOption {
      type = lib.types.str;
      default = "gpt-4o-mini";
      description = "LLM model for query answering";
    };

    # Privacy-first: default to a local Ollama LLM for answer generation so
    # the corpus never leaves the box. Set to "openai" to fall back to a
    # hosted OpenAI-compatible endpoint.
    llmProvider = lib.mkOption {
      type = lib.types.enum [
        "ollama"
        "openai"
      ];
      default = "ollama";
      description = "Answer-generation LLM provider: local ollama (private) or hosted openai-compatible";
    };

    embedModel = lib.mkOption {
      type = lib.types.str;
      default = "nomic-embed-text";
      description = "Ollama embedding model";
    };

    embedDim = lib.mkOption {
      type = lib.types.int;
      default = 768;
      description = "Embedding dimension (must match model)";
    };

    # ── Database & user (hardening) ─────────────────────────────────
    dbUser = lib.mkOption {
      type = lib.types.str;
      default = "brain_user";
      description = "PostgreSQL role for brain-service (NOT the postgres superuser)";
    };

    dbName = lib.mkOption {
      type = lib.types.str;
      default = "brain_db";
      description = "PostgreSQL database for brain-service";
    };

    dbHost = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "PostgreSQL host";
    };

    dbPort = lib.mkOption {
      type = lib.types.port;
      default = 5432;
      description = "PostgreSQL port";
    };

    booksDir = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Directory to watch for new PDF/EPUB files";
    };

    mcpEnable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable MCP server for Hermes";
    };

    apiSecretFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to the environment file with API keys.";
    };

    # ── MCP/API authentication & RBAC ───────────────────────────────
    # Agent -> role map. API keys are injected via BRAIN_SERVICE_API_KEYS env
    # (rendered by the generator below); roles gate tool access.
    agents = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.enum [
          "reader"
          "writer"
          "admin"
        ]
      );
      default = {
        hermes = "writer";
        polyfloor = "writer";
        everos = "reader";
      };
      description = "Agent names mapped to RBAC roles (reader/writer/admin).";
    };
  };

  config =
    let
      cfg = config.services.ai-services.brain-service;
      secretFile =
        if cfg.apiSecretFile != null then
          cfg.apiSecretFile
        else
          config.clan.core.vars.generators.brain-service.files."env".path;

      # Python environment with all dependencies
      pythonEnv = pkgs.python3.withPackages (
        ps: with ps; [
          # Core API
          fastapi
          uvicorn
          pydantic
          sqlalchemy
          psycopg2
          pgvector

          # LlamaIndex
          llama-index-core
          llama-index-vector-stores-postgres
          llama-index-embeddings-ollama
          llama-index-llms-openai
          llama-index-llms-ollama

          # Document parsing
          pymupdf # PDF
          ebooklib # EPUB
          beautifulsoup4 # HTML
          markdown # Markdown → HTML conversion
          lxml # Fast HTML parser
          python-multipart # File uploads

          # File watching
          watchdog

          # MCP server
          mcp
        ]
      );

      # Brain Service Python Script — loaded from external file to avoid Nix heredoc indentation issues
      brainScript = ./brain_server.py;
    in
    lib.mkIf cfg.enable {
      clan.core.vars.generators.brain-service = {
        files."env" = {
          secret = true;
          owner = "postgres";
          group = "postgres";
        };
        prompts."api-key" = {
          type = "hidden";
          description = "OpenRouter/OpenAI API key for Brain Service";
        };
        prompts."mcp-api-keys" = {
          type = "hidden";
          description = "JSON map of agent -> {key, role} for brain-service MCP/API auth (e.g. {\"hermes\":{\"key\":\"...\",\"role\":\"writer\"}})";
        };
        prompts."db-password" = {
          type = "hidden";
          description = "Password for the dedicated brain_db / brain_user PostgreSQL role";
        };
        script = ''
                  if [ -f "$prompts/api-key" ]; then
                    API_KEY=$(cat "$prompts/api-key")
                  else
                    API_KEY="dummy"
                  fi
                  echo "LLM_API_KEY=$API_KEY" > "$out/env"

                  # DB password for the dedicated brain_user role
                  if [ -f "$prompts/db-password" ] && [ -s "$prompts/db-password" ]; then
                    DB_PASS=$(cat "$prompts/db-password")
                  else
                    DB_PASS="brain-dev-password"
                  fi
                  echo "DB_PASS=$DB_PASS" >> "$out/env"

                  # RBAC agent keys (JSON). Fall back to a deterministic local default
                  # if the prompt is unset so the service still boots in dev/CI.
                  if [ -f "$prompts/mcp-api-keys" ] && [ -s "$prompts/mcp-api-keys" ]; then
                    AGENT_KEYS=$(cat "$prompts/mcp-api-keys")
                  else
                    AGENT_KEYS=$(cat <<JSON
                    {
                      "hermes": {"key": "local-dev-hermes", "role": "writer"},
                      "polyfloor": {"key": "local-dev-polyfloor", "role": "writer"},
                      "everos": {"key": "local-dev-everos", "role": "reader"}
                    }
          JSON
                    )
                  fi
                  echo "BRAIN_SERVICE_API_KEYS=$AGENT_KEYS" >> "$out/env"
        '';
      };

      # ── Dedicated PostgreSQL role/db + pgvector (hardening) ──────────
      # brain-service uses its own brain_user/brain_db role instead of the
      # postgres superuser. Mirrors honcho.nix provisioning.
      services.postgresql = {
        enable = true;
        ensureDatabases = [ cfg.dbName ];
        ensureUsers = [
          {
            name = cfg.dbUser;
            ensureDBOwnership = false; # owned via initialScript below (different name)
            ensureClauses = {
              login = true;
              superuser = false;
              createrole = false;
              createdb = false;
            };
          }
        ];
        extensions = ps: with ps; [ pgvector ];
      };

      # Grant postgres access to traverse /home/t0psh31f/ for PKB books
      users.users.postgres.extraGroups = [ "users" ];

      # Create data directory
      systemd.tmpfiles.rules = [
        "d /var/lib/brain-service 0750 postgres postgres -"
        "d /var/lib/brain-service/tiktoken-cache 0755 postgres postgres -"
      ];

      # Main API service
      systemd.services.brain-service = {
        description = "Brain Service PKB API";
        wantedBy = [ "multi-user.target" ];
        after = [
          "postgresql.service"
          "postgresql-extensions.service"
        ];
        requires = [ "postgresql.service" ];

        environment = {
          DB_NAME = cfg.dbName;
          DB_USER = cfg.dbUser;
          DB_HOST = cfg.dbHost;
          DB_PORT = toString cfg.dbPort;
          LLM_PROVIDER = cfg.llmProvider;
          LLM_API_BASE = cfg.llmApiBase;
          LLM_MODEL = cfg.llmModel;
          OLLAMA_URL = "http://127.0.0.1:11434";
          EMBED_MODEL = cfg.embedModel;
          EMBED_DIM = toString cfg.embedDim;
          PORT = toString cfg.port;
          HOST = cfg.host;
          BRAIN_MODE = "api";
          MANIFEST_PATH = "/var/lib/brain-service/manifest.json";
          TIKTOKEN_CACHE_DIR = "/var/lib/brain-service/tiktoken-cache";
        }
        // lib.optionalAttrs (cfg.booksDir != null) {
          BOOKS_DIR = cfg.booksDir;
        };

        serviceConfig = {
          ExecStart = "${pythonEnv}/bin/python ${brainScript}";
          ExecStartPre = [
            "+${pkgs.writeShellScript "brain-service-db-init" ''
              set -euo pipefail
              # Coexists with honcho's postgresql.initialScript (which owns the
              # global initialScript); provision brain_db's vector extension +
              # ownership idempotently here. The "+" prefix runs this as root,
              # so psql must drop to the postgres superuser role explicitly.
              PSQL() { ${pkgs.util-linux}/bin/runuser -u postgres -- ${pkgs.postgresql}/bin/psql -v ON_ERROR_STOP=1 "$@"; }
              PSQL -d postgres -c "ALTER DATABASE ${cfg.dbName} OWNER TO ${cfg.dbUser};"
              PSQL -d ${cfg.dbName} -c "CREATE EXTENSION IF NOT EXISTS vector;"
              PSQL -d ${cfg.dbName} -c "GRANT ALL ON SCHEMA public TO ${cfg.dbUser};"
            ''}"
          ];
          Restart = "on-failure";
          User = "postgres";
          EnvironmentFile = secretFile;
          MemoryMax = "1G";
          MemoryHigh = "800M";
        };
      };

      # MCP server for Hermes (runs on-demand via stdin/stdout)
      systemd.services.brain-mcp = lib.mkIf cfg.mcpEnable {
        description = "Brain Service MCP Server";
        # Triggered on-demand by Hermes, not at boot
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pythonEnv}/bin/python ${brainScript}";
          User = "postgres";
          EnvironmentFile = secretFile;
          Environment = [
            "BRAIN_MODE=mcp"
            "DB_NAME=${cfg.dbName}"
            "DB_USER=${cfg.dbUser}"
            "DB_HOST=${cfg.dbHost}"
            "DB_PORT=${toString cfg.dbPort}"
            "LLM_PROVIDER=${cfg.llmProvider}"
            "LLM_API_BASE=${cfg.llmApiBase}"
            "LLM_MODEL=${cfg.llmModel}"
            "OLLAMA_URL=http://127.0.0.1:11434"
            "EMBED_MODEL=${cfg.embedModel}"
            "EMBED_DIM=${toString cfg.embedDim}"
            "MANIFEST_PATH=/var/lib/brain-service/manifest.json"
            "TIKTOKEN_CACHE_DIR=/var/lib/brain-service/tiktoken-cache"
          ];
        };
      };

      # File watcher service (optional)
      systemd.services.brain-watcher = lib.mkIf (cfg.booksDir != null) {
        description = "Brain Service File Watcher";
        wantedBy = [ "multi-user.target" ];
        after = [ "brain-service.service" ];
        requires = [ "brain-service.service" ];

        environment = {
          BRAIN_MODE = "watcher";
          DB_NAME = cfg.dbName;
          DB_USER = cfg.dbUser;
          DB_HOST = cfg.dbHost;
          DB_PORT = toString cfg.dbPort;
          LLM_PROVIDER = cfg.llmProvider;
          OLLAMA_URL = "http://127.0.0.1:11434";
          EMBED_MODEL = cfg.embedModel;
          EMBED_DIM = toString cfg.embedDim;
          BOOKS_DIR = cfg.booksDir;
          MANIFEST_PATH = "/var/lib/brain-service/manifest.json";
          TIKTOKEN_CACHE_DIR = "/var/lib/brain-service/tiktoken-cache";
        };

        serviceConfig = {
          ExecStart = "${pythonEnv}/bin/python ${brainScript}";
          Restart = "on-failure";
          User = "postgres";
          EnvironmentFile = secretFile;
        };
      };

      # MCP wrapper package for Hermes integration
      environment.systemPackages = lib.mkIf cfg.mcpEnable [
        (import ../75-mcp/_brain-mcp-wrapper.nix {
          inherit
            pkgs
            brainScript
            pythonEnv
            cfg
            ;
        })
        # CLI tool for quick ingestion
        (pkgs.writeShellScriptBin "brain-ingest" ''
          if [ -z "$1" ]; then
            echo "Usage: brain-ingest <file-or-directory>"
            echo "  Supports: PDF, EPUB, HTML, MD, TXT"
            exit 1
          fi

          if [ -d "$1" ]; then
            curl -s -X POST "http://127.0.0.1:8010/ingest/directory?directory=$1" | jq .
          else
            curl -s -X POST "http://127.0.0.1:8010/ingest/path?path=$1" | jq .
          fi
        '')
        # CLI tool for ingesting websites
        (pkgs.writeShellScriptBin "insite" ''
          if [ -z "$1" ]; then
            echo "Usage: insite <url>"
            echo "  Downloads a website and ingests it into your PKB"
            echo ""
            echo "Examples:"
            echo "  insite docs.clan.lol"
            echo "  insite https://nixos.wiki/wiki/NixOS_Wiki"
            echo "  insite https://blog.example.com/article"
            exit 1
          fi

          # Normalize URL
          URL="$1"
          if [[ ! "$URL" =~ ^https?:// ]]; then
            URL="https://$URL"
          fi

          # Extract domain for folder name
          DOMAIN=$(echo "$URL" | sed -E 's|https?://([^/]+).*|\1|' | sed 's|www\.||')
          DEST="$HOME/Notes/PKB/websites/$DOMAIN"

          echo "Downloading $URL → $DEST/"
          mkdir -p "$DEST"

          ${pkgs.wget}/bin/wget --mirror --convert-links --adjust-extension --page-requisites \
            --no-parent --no-host-directories --directory-prefix="$DEST" \
            --reject="*.css,*.js,*.png,*.jpg,*.jpeg,*.gif,*.svg,*.ico,*.woff,*.woff2,*.ttf,*.eot" \
            --timeout=10 --tries=2 "$URL" 2>&1 | tail -5

          echo ""
          echo "Ingesting into Brain Service..."
          RESULT=$(curl -s -X POST "http://127.0.0.1:8010/ingest/directory?directory=$DEST" 2>&1)
          FILES=$(echo "$RESULT" | ${pkgs.jq}/bin/jq -r '.files // 0')
          echo "Done! Ingested $FILES files from $DOMAIN"
          echo "  Source: $DEST/"
        '')

        # CLI tool for querying
        (pkgs.writeShellScriptBin "brain-query" ''
          if [ -z "$1" ]; then
            echo "Usage: brain-query <question>"
            exit 1
          fi

          curl -s -X POST http://127.0.0.1:8010/query \
            -H "Content-Type: application/json" \
            -d "{\"question\": \"$1\"}" | jq .
        '')
      ];

      # Impermanence
      environment.persistence."/persist" =
        lib.mkIf (config.layers.layer-10.system.config.impermanence.enable or false)
          {
            directories = [
              {
                directory = "/var/lib/brain-service";
                user = "postgres";
                group = "postgres";
                mode = "0750";
              }
            ];
          };
    };
}
