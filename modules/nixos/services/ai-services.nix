{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  options.services.ai-services = {
    enable = mkEnableOption "AI-related services";

    postgresql = {
      enable = mkOption {
        type = types.bool;
        default = true;
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
        default = 8000;
        description = "ChromaDB port";
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

    # Open WebUI - container-based deployment
    virtualisation.oci-containers.containers.open-webui =
      mkIf config.services.ai-services.open-webui.enable
        {
          image = "ghcr.io/open-webui/open-webui:main";
          ports = [ "${toString config.services.ai-services.open-webui.port}:8080" ];
          volumes = [
            "open-webui:/app/backend/data"
          ];
          extraOptions = [
            "--add-host=host.docker.internal:host-gateway"
          ];
        };

    # Qdrant vector database
    virtualisation.oci-containers.containers.qdrant = mkIf config.services.ai-services.qdrant.enable {
      image = "qdrant/qdrant:latest";
      ports = [
        "${toString config.services.ai-services.qdrant.port}:6333"
        "6334:6334"
      ];
      volumes = [
        "qdrant_storage:/qdrant/storage"
      ];
    };

    # ChromaDB vector database
    virtualisation.oci-containers.containers.chromadb =
      mkIf config.services.ai-services.chromadb.enable
        {
          image = "chromadb/chroma:latest";
          ports = [ "${toString config.services.ai-services.chromadb.port}:8000" ];
          volumes = [
            "chromadb_data:/chroma/chroma"
          ];
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

    # Enable docker/podman for container services
    virtualisation.docker.enable = mkIf (
      config.services.ai-services.open-webui.enable
      || config.services.ai-services.qdrant.enable
      || config.services.ai-services.chromadb.enable
      || config.services.ai-services.localai.enable
    ) true;

    virtualisation.oci-containers.backend = "docker";

    # Firewall rules
    networking.firewall.allowedTCPPorts = mkIf config.services.ai-services.enable (
      (optional config.services.ai-services.postgresql.enable config.services.ai-services.postgresql.port)
      ++ (optional config.services.ai-services.open-webui.enable config.services.ai-services.open-webui.port)
      ++ (optional config.services.ai-services.qdrant.enable config.services.ai-services.qdrant.port)
      ++ (optional config.services.ai-services.chromadb.enable config.services.ai-services.chromadb.port)
      ++ (optional config.services.ai-services.localai.enable config.services.ai-services.localai.port)
    );
  };
}
