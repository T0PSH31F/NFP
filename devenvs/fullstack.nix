# devenvs/fullstack.nix
# Combined full-stack environment
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
      devenv.shells.fullstack = {
        name = "Full-Stack Development";

        languages = {
          python = {
            enable = true;
            version = "3.11";
            poetry.enable = true;
          };
          javascript = {
            enable = true;
            npm.enable = true;
          };
          rust.enable = true;
        };

        packages = with pkgs; [
          # Python
          ruff
          black

          # Node
          nodePackages.typescript

          # Rust
          rust-analyzer

          # AI tools
          ollama

          # Automation
          n8n

          # Database tools
          postgresql
          redis
        ];

        services = {
          postgres = {
            enable = true;
            initialDatabases = [ { name = "fullstack_dev"; } ];
          };
          redis.enable = true;
        };

        enterShell = ''
          echo "🚀 Full-Stack Development Environment"
          echo "====================================="
          echo ""
          echo "Languages available:"
          echo "  - Python $(python --version | cut -d' ' -f2)"
          echo "  - Node $(node --version)"
          echo "  - Rust $(rustc --version | cut -d' ' -f2)"
          echo ""
        '';
      };
    };
}
