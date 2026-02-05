# devenvs/rust-saas.nix
# Rust development for SaaS applications
{ inputs, ... }:
{
  perSystem =
    { config, pkgs, ... }:
    {
      devenv.shells.rust-saas = {
        name = "Rust SaaS Development";

        languages.rust = {
          enable = true;
          channel = "stable";
          components = [
            "rustc"
            "cargo"
            "clippy"
            "rustfmt"
            "rust-analyzer"
          ];
        };

        packages = with pkgs; [
          # Rust tools
          cargo-watch
          cargo-edit
          cargo-audit
          cargo-outdated

          # Database
          postgresql
          diesel-cli

          # Utils
          openssl
          pkg-config
        ];

        services.postgres = {
          enable = true;
          initialDatabases = [ { name = "rust_saas_dev"; } ];
        };

        env = {
          DATABASE_URL = "postgresql://postgres@localhost/rust_saas_dev";
          RUST_BACKTRACE = "1";
        };

        enterShell = ''
          echo "🦀 Rust SaaS Development Environment"
          echo "===================================="
          echo ""
          echo "Rust version: $(rustc --version)"
          echo "Cargo version: $(cargo --version)"
          echo ""
          echo "Database: postgresql://localhost/rust_saas_dev"
          echo ""
          echo "Quick commands:"
          echo "  cargo watch -x run    - Auto-reload on changes"
          echo "  cargo test            - Run tests"
          echo "  cargo clippy          - Run linter"
          echo ""
        '';

        processes = {
          # api.exec = "cargo watch -x run";
        };
      };
    };
}
