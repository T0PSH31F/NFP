{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
let
  cfg = config.modules.yazelix;
  user = "t0psh31f";
in
{
  options.modules.yazelix = {
    enable = mkEnableOption "Yazelix Integrated Workspace Environment";

    packs = mkOption {
      type = types.listOf types.str;
      default = [
        "python"
        "js_ts"
        "rust"
        "config"
        "file-management"
      ];
      description = "Enabled Yazelix packs";
    };
  };

  config = mkIf cfg.enable {
    # System-level dependencies
    environment.systemPackages = with pkgs; [
      git
      curl
      wl-clipboard
      nushell # Required by Yazelix for internal scripting
    ];

    # Home Manager Configuration (as a NixOS module)
    home-manager.users.${user} =
      {
        pkgs,
        config,
        lib,
        ...
      }:
      {
        imports = [
          inputs.yazelix.homeManagerModules.default
        ];

        home.packages = with pkgs; [
          nushell
        ];

        programs.yazelix = {
          enable = true;

          # Shell configuration - use Zsh as default, Nushell is used internally
          default_shell = "zsh";
          extra_shells = [
            "nushell"
            "bash"
            "fish"
          ];

          terminals = [
            "ghostty"
            "wezterm"
          ];
          manage_terminals = true;

          # Recommended dependencies (lazygit, atuin, zoxide, starship, fzf, mise, etc)
          recommended_deps = true;

          # Enable Atuin for shell history
          enable_atuin = true;

          # Yazi configuration
          yazi_extensions = true; # File preview support
          yazi_media = lib.mkDefault false; # ~1GB media processing (optional)
          yazi_plugins = [
            "git"
            "starship"
          ];

          # Editor: Use system Helix or Yazelix's Helix
          # editor_command = "hx";  # Use system Helix (requires helix_runtime_path)
          # For now, let Yazelix manage its own Helix

          # Development-friendly settings
          skip_welcome_screen = false;
          enable_sidebar = true;
          disable_zellij_tips = true;

          # Packs (using Yazelix's built-in pack system)
          pack_names = cfg.packs;
          pack_declarations = {
            python = [
              "pyright"
              "ruff"
              "uv"
              "python3Packages.ipython"
              "black"
              "isort"
            ];
            js_ts = [
              "nodePackages.typescript-language-server"
              "nodePackages.prettier"
              "biome"
            ];
            rust = [
              "rust-analyzer"
              "cargo"
              "rustc"
              "cargo-update"
            ];
            config = [
              "nil"
              "nixfmt-tree"
              "taplo"
              "yaml-language-server"
              "statix"
              "deadnix"
            ];
            file-management = [
              "fd"
              "ripgrep"
              "erdtree"
            ];
          };

          # Additional packages for your workflow
          user_packages = with pkgs; [
            # Nix development tools
            nix-top
            any-nix-shell
            nix-btm
            cached-nix-shell
            nix-zsh-completions
            nix-your-shell
            nix-fast-build
            optinix
          ];
        };
      };
  };
}
