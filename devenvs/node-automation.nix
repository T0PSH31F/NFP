# devenvs/node-automation.nix
# Node.js environment for n8n automation and web scraping
{ inputs, ... }:
{
  perSystem =
    { config, pkgs, ... }:
    {
      devenv.shells.node-automation = {
        name = "Node.js Automation & n8n";

        # Node.js setup
        languages.javascript = {
          enable = true;
          package = pkgs.nodejs_20;
          npm = {
            enable = true;
            install.enable = true;
          };
          pnpm = {
            enable = true;
            install.enable = true;
          };
        };

        packages = with pkgs; [
          # Node tools
          nodePackages.typescript
          nodePackages.ts-node
          nodePackages.eslint
          nodePackages.prettier

          # Automation tools
          n8n
          playwright-driver.browsers

          # Database
          postgresql
          sqlite

          # Utils
          jq
          curl
        ];

        services = {
          postgres = {
            enable = true;
            initialDatabases = [ { name = "n8n"; } ];
          };
        };

        env = {
          N8N_PORT = "5678";
          N8N_PROTOCOL = "http";
          N8N_HOST = "localhost";
          DB_TYPE = "postgresdb";
          DB_POSTGRESDB_DATABASE = "n8n";
          DB_POSTGRESDB_HOST = "localhost";
          DB_POSTGRESDB_PORT = "5432";
          DB_POSTGRESDB_USER = "postgres";
          PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
        };

        enterShell = ''
          echo "🔄 Node.js Automation Environment"
          echo "================================="
          echo ""
          echo "Node version: $(node --version)"
          echo "npm version: $(npm --version)"
          echo ""
          echo "To start n8n: n8n start"
          echo "n8n will be available at http://localhost:5678"
          echo ""
        '';

        processes = {
          # n8n.exec = "n8n start";
        };
      };
    };
}
