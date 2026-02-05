# devenvs/python-ai-agent.nix
# Python development environment for AI agents and automation
{ inputs, ... }:
{
  perSystem =
    {
      config,
      pkgs,
      system,
      ...
    }:
    {
      devenv.shells.python-ai-agent = {
        name = "Python AI Agent Development";

        # Python setup
        languages.python = {
          enable = true;
          version = "3.11";
          poetry = {
            enable = true;
            activate.enable = true;
            install.enable = true;
          };
          venv = {
            enable = true;
            requirements = ''
              openai>=1.0.0
              anthropic>=0.8.0
              langchain>=0.1.0
              chromadb>=0.4.0
              fastapi>=0.109.0
              uvicorn>=0.27.0
              pydantic>=2.5.0
              python-dotenv>=1.0.0
              httpx>=0.26.0
              tenacity>=8.2.0
            '';
          };
        };

        # AI/ML packages
        packages = with pkgs; [
          # Python tools
          ruff
          black
          mypy
          python3Packages.ipython

          # AI/ML tools
          ollama

          # Database tools
          postgresql
          sqlite

          # Network tools
          curl
          jq
          httpie

          # LLM agents integration
          # inputs.llm-agents.packages.${system}.default
        ];

        # Services
        services = {
          postgres = {
            enable = true;
            initialDatabases = [ { name = "ai_agent_dev"; } ];
            listen_addresses = "127.0.0.1";
          };

          redis = {
            enable = true;
            port = 6379;
          };
        };

        # Environment variables
        env = {
          PYTHONPATH = "./src:$PYTHONPATH";
          DATABASE_URL = "postgresql://postgres@localhost/ai_agent_dev";
          REDIS_URL = "redis://localhost:6379";
          OLLAMA_HOST = "http://localhost:11434";
        };

        # Shell hooks
        enterShell = ''
          echo "🤖 Python AI Agent Development Environment"
          echo "=========================================="
          echo ""
          echo "Python version: $(python --version)"
          echo "Poetry version: $(poetry --version)"
          echo ""
          echo "Services running:"
          echo "  - PostgreSQL on localhost:5432"
          echo "  - Redis on localhost:6379"
          echo ""
          echo "To start Ollama: ollama serve"
          echo "To run FastAPI: uvicorn main:app --reload"
          echo ""
        '';

        # Process management (replaces docker-compose)
        processes = {
          # ollama.exec = "ollama serve";
          # Uncomment to auto-start services
        };

        # Pre-commit hooks
        pre-commit.hooks = {
          ruff.enable = true;
          black.enable = true;
          mypy.enable = true;
        };
      };
    };
}
