{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Version control
    git
    gh

    # Build tools
    gnumake
    cmake

    # Compilers/interpreters
    gcc
    python311
    nodejs_22
    go
    rustc
    cargo

    # LSPs and formatters
    nil
    nixfmt-rfc-style

    # Container tools
    docker
    docker-compose

    # Database clients
    postgresql_16
    sqlite

    # API testing
    postman
    insomnia
  ];
}
