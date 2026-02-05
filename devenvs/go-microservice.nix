# devenvs/go-microservice.nix
# Go development for microservices
{ inputs, ... }:
{
  perSystem =
    { config, pkgs, ... }:
    {
      devenv.shells.go-microservice = {
        name = "Go Microservice Development";

        languages.go = {
          enable = true;
          package = pkgs.go_1_21;
        };

        packages = with pkgs; [
          # Go tools
          gopls
          delve
          golangci-lint
          gotools

          # gRPC/Protobuf
          protobuf
          protoc-gen-go
          protoc-gen-go-grpc

          # Database
          postgresql
          redis
        ];

        services = {
          postgres.enable = true;
          redis.enable = true;
        };

        env = {
          GOPATH = "./.go";
          DATABASE_URL = "postgresql://postgres@localhost/go_dev";
        };

        enterShell = ''
          echo "🐹 Go Microservice Environment"
          echo "=============================="
          echo ""
          echo "Go version: $(go version)"
          echo ""
          echo "Services running:"
          echo "  - PostgreSQL on localhost:5432"
          echo "  - Redis on localhost:6379"
          echo ""
        '';
      };
    };
}
