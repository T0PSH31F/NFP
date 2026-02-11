{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.ai-services;
in
{
  options.services.ai-services = {
    enable = mkEnableOption "AI-related services";

    postgresql = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable PostgreSQL with pgvector and lantern extensions";
      };

      port = mkOption {
        type = types.int;
        default = 5432;
        description = "PostgreSQL port";
      };
    };

    open-webui = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Open WebUI for LLM interfaces";
      };

      port = mkOption {
        type = types.int;
        default = 8080;
        description = "Open WebUI port";
      };
    };

    qdrant = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Qdrant vector database";
      };

      port = mkOption {
        type = types.int;
        default = 6333;
        description = "Qdrant port";
      };
    };

    localai = {
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

    chromadb = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable ChromaDB vector database";
      };

      port = mkOption {
        type = types.int;
        default = 8001;
        description = "ChromaDB port";
      };
    };

    # ============================================================================
    # SILLYTAVERN - AI Chat Frontend
    # ============================================================================
    sillytavern = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable SillyTavern AI chat frontend";
      };

      port = mkOption {
        type = types.int;
        default = 8000;
        description = "SillyTavern port";
      };

      dataDir = mkOption {
        type = types.str;
        default = "/var/lib/sillytavern";
        description = "Data directory for SillyTavern";
      };
    };

    # ============================================================================
    # OLLAMA - Local LLM Server
    # ============================================================================
    ollama = {
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

    # ============================================================================
    # LM STUDIO - Local LLM GUI (user-space, just package)
    # ============================================================================
    lmstudio = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Install LM Studio desktop application";
      };
    };

    # ============================================================================
    # JAN - Open-source ChatGPT Alternative
    # ============================================================================
    jan = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Install Jan AI desktop application";
      };
    };

    # ============================================================================
    # CHERRY STUDIO - Desktop LLM Client
    # ============================================================================
    cherry-studio = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Install Cherry Studio desktop LLM client";
      };
    };

    # ============================================================================
    # AIDER - AI Pair Programming CLI
    # ============================================================================
    aider = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Install Aider AI pair programming tool";
      };
    };
  };

  config = mkIf config.services.ai-services.enable {
    # PostgreSQL with pgvector and lantern
    services.postgresql = mkIf config.services.ai-services.postgresql.enable {
      enable = true;
      package = pkgs.postgresql_16;
      settings.port = config.services.ai-services.postgresql.port;

      # Enable extensions
      enableTCPIP = true;

      extensions = with pkgs.postgresql_16.pkgs; [
        pgvector
      ];

      settings = {
        shared_preload_libraries = "vector";
        max_connections = 100;
        shared_buffers = "256MB";
      };

      authentication = pkgs.lib.mkOverride 10 ''
        # TYPE  DATABASE        USER            ADDRESS                 METHOD
        local   all             all                                     trust
        host    all             all             127.0.0.1/32            md5
        host    all             all             ::1/128                 md5
      '';

      ensureDatabases = [
        "ai"
        "vectordb"
      ];
      ensureUsers = [
        {
          name = "ai";
          ensureDBOwnership = true;
        }
      ];
    };

    # Open WebUI - native NixOS service
    services.open-webui = mkIf config.services.ai-services.open-webui.enable {
      enable = true;
      port = config.services.ai-services.open-webui.port;
      openFirewall = true;
      environment = {
        OLLAMA_API_BASE_URL = "http://localhost:11434";
        WEBUI_AUTH = "false"; # Disable auth for local use
      };
    };

    # Qdrant vector database - native NixOS service
    services.qdrant = mkIf config.services.ai-services.qdrant.enable {
      enable = true;
      settings = {
        service = {
          http_port = config.services.ai-services.qdrant.port;
          grpc_port = 6334;
        };
        storage = {
          storage_path = "/var/lib/qdrant/storage";
        };
      };
    };

    # ChromaDB vector database - native NixOS service
    services.chromadb = mkIf config.services.ai-services.chromadb.enable {
      enable = true;
      port = config.services.ai-services.chromadb.port;
      openFirewall = true;
    };

    # LocalAI
    virtualisation.oci-containers.containers.local-ai =
      mkIf config.services.ai-services.localai.enable
        {
          image = "quay.io/go-skynet/local-ai:latest";
          ports = [ "${toString config.services.ai-services.localai.port}:8080" ];
          volumes = [
            "local-ai-models:/models"
          ];
          environment = {
            THREADS = "4";
            CONTEXT_SIZE = "512";
          };
        };

    # ============================================================================
    # OLLAMA - Native Local LLM Server
    # ============================================================================
    services.ollama = mkIf cfg.ollama.enable {
      enable = true;
      package = pkgs.ollama-vulkan;
      # acceleration = cfg.ollama.acceleration; # package handles acceleration
      loadModels = cfg.ollama.models;
    };

    # Ollama Service Customization (only when enabled)
    systemd.services.ollama = mkIf cfg.ollama.enable {
      serviceConfig.DynamicUser = lib.mkForce false;
    };

    # Create static user for Ollama (only when enabled)
    users.users.ollama = mkIf cfg.ollama.enable {
      group = "ollama";
      isSystemUser = true;
      description = "Ollama Service User";
      home = "/var/lib/ollama";
      createHome = true;
    };
    users.groups.ollama = mkIf cfg.ollama.enable { };

    systemd.tmpfiles.rules =
      (optional cfg.ollama.enable "d /var/lib/ollama 0750 ollama ollama -")
      ++ (optional cfg.ollama.enable "d /var/lib/ollama/models 0750 ollama ollama -")
      ++ (optional cfg.localai.enable "d /persist/var/lib/localai 0750 localai localai") # Moved here for consistency
      ++ (optional cfg.chromadb.enable "d /persist/var/lib/chromadb 0750 chromadb chromadb");

    # Enable docker/podman only for LocalAI (still needs container)
    virtualisation.docker.enable = mkIf cfg.localai.enable true;

    virtualisation.oci-containers.backend = mkIf cfg.localai.enable "docker";

    # NextJS Ollama LLM UI
    systemd.services.nextjs-ollama-llm-ui = {
      description = "NextJS Ollama LLM UI";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "ollama.service"
      ];
      serviceConfig = {
        ExecStart = "${pkgs.nextjs-ollama-llm-ui}/bin/nextjs-ollama-llm-ui";
        DynamicUser = true;
        Environment = [
          "PORT=3001"
          "OLLAMA_URL=http://localhost:11434"
        ];
      };
    };

    # Firewall rules (mostly handled by openFirewall options now)
    networking.firewall.allowedTCPPorts = mkIf cfg.enable (
      (optional cfg.postgresql.enable cfg.postgresql.port)
      ++ (optional cfg.localai.enable cfg.localai.port)
      ++ (optional cfg.ollama.enable 11434)
      ++ [ 3001 ] # NextJS UI
    );

    # Ensure data is persisted
    environment.persistence."/persist" = mkIf config.system-config.impermanence.enable {
      directories = [
        # "/var/lib/docker" # Persist all docker volumes
        "/var/lib/ollama"
        "/var/lib/qdrant"
      ];
    };

    environment.systemPackages = with pkgs; [
      # Frameworks
      crewai # Framework for orchestrating autonomous AI agents
      fabric-ai # AI-powered workflow framework
      go-hass-agent # Home Assistant agent in Go
      #task-master-ai # Task automation agent

      # Inference
      #gpt4all # Run LLMs locally on consumer hardware
      lmstudio # GUI for running local LLMs
      jan
      qdrant # Vector database for AI applications
      ramalama # Tool for managing AI models

      # Interfaces
      bluemail # Email client with AI integration
      cherry-studio # Desktop LLM client
      librechat # Open-source AI chat interface
      nextjs-ollama-llm-ui # Web UI for Ollama
      # sillytavern # Advanced LLM interface for roleplay
      # windsurf # Agentic IDE

      # CLI & TUI
      aider-chat-full # CLI for AI pair programming
      # crush (Provided by llm-agents.nix)
      krillinai # AI agent tool

      # TTS & STT
      # moshi # Real-time conversational AI
      piper-tts # Local neural text-to-speech engine
      whisper-ctranslate2 # High-performance speech-to-text
    ];

  };
}
