{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  options.nix-tools = {
    enable = mkEnableOption "Nix development and helper tools";
  };

  config = mkIf config.nix-tools.enable {
    # NH - NixOS Helper
    # Provides cleaner commands: nh os switch, nh os boot, nh os test, etc.
    programs.nh = {
      enable = true;
      clean.enable = false;
      clean.extraArgs = "--keep-since 7d --keep 5";
      flake = "/home/t0psh31f/Clan/Grandlix-Gang";
    };

    # Install nom (Nix Output Monitor)
    # Usage: nom build, nom shell, etc. - prettier build output
    environment.systemPackages = with pkgs; [
      nix-output-monitor # nom command
      nix-top
      nvd # Nix/NixOS package version diff tool
      nix-tree # Interactive nix dependency tree viewer
      nix-index # Locate packages providing a file
      nix-ld
      nixfmt-tree
      arion
      nix-top
      nix-tree
      nix-init
      nix-inspect
      nixos-option
      nix-search-tv
      nix-your-shell
      nix-fast-build
      nix-zsh-completions
      optinix
      statix
      deadnix
      omnix
      manix
      optnix
      zsh-nix-shell
      # mcp-nixos # Disabled: dependency conflict with fastmcp (needs mcp<1.17.0 but has 1.25.0)
      nil
      #nixd
      dix
      compose2nix
      comma

    ];
    # Enable nix-index database generation
    programs.command-not-found.enable = false;
    programs.nix-index = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
    };

    # Helpful shell aliases for home-manager users
    home-manager.users.t0psh31f = {
      home.shellAliases = {
        cunt = "clan machines update nami";
        cumz = "clan machines update z0r0";
        cum = "clan machines update";
        # NH shortcuts
        nos = "nh os switch";
        nob = "nh os boot";
        not = "nh os test";
        noc = "nh clean all";

        # Nom shortcuts
        nb = "nom build";
        ndev = "nom develop";

        # Nix helpers
        ndiff = "nvd diff /run/current-system result";
        ntree = "nix-tree";
      };
    };
  };
}
