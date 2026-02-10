# flake-parts/features/nixos/packages/dev.nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  hasTag = tag: builtins.elem tag (config.clan.core.tags or [ ]);
in
{
  config = lib.mkIf (hasTag "dev") {
    environment.systemPackages = with pkgs; [
      # Compilers & build tools
      antigravity-fhs
      binutils
      cmake
      gcc
      gnumake
      libgcc
      pkg-config

      # Debugging
      gdb
      valgrind

      # Dev environments
      devenv
      direnv

      # Languages
      nodePackages.npm
      nodePackages.yarn
      nodejs
      poetry
      typescript
      uv

      # VCS / dev tooling
      gh
      git-lfs
      gitFull
    ];

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
