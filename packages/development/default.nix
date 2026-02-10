{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = lib.mkIf (config.clan.lib.hasTag "dev") {
    environment.systemPackages = with pkgs; [
      # Compilers & build tools
      gcc
      binutils
      cmake
      gnumake
      pkg-config
      libgcc
      antigravity-fhs
      gnumake
      pkg-config

      # VCS / dev tooling
      gitFull
      git-lfs
      gh

      # Dev environments
      devenv
      direnv

      # Languages
      poetry
      uv
      nodejs
      nodePackages.npm
      nodePackages.yarn
      typescript

      # Debugging
      gdb
      valgrind
    ];

    programs.direnv.enable = true;
  };
}
