{
  config,
  lib,
  pkgs,
  osConfig ? config,
  ...
}:
let
  cfg = config.layers.layer-50.cli;
in
{
  home = lib.mkIf (cfg.enable && cfg.modernTools.enable) {
    programs = {
      bat = {
        enable = true;
        config.theme = lib.mkIf cfg.theming.enable "matugen";
      };
      ripgrep.enable = true;
      jq.enable = true;
      btop = {
        enable = true;
        settings.color_theme =
          if osConfig.layers.layer-40.desktop.noctalia.enable or false then
            "noctalia"
          else if cfg.theming.enable then
            "matugen"
          else
            "default";
      };
      eza = {
        enable = true;
        enableZshIntegration = true;
        enableBashIntegration = true;
        git = true;
        icons = "always";
        extraOptions = [
          "-a"
          "-1"
        ];
      };
      zoxide = {
        enable = true;
        enableZshIntegration = true;
        enableBashIntegration = true;
        options = [ "--cmd cd" ];
      };
      direnv = {
        enable = true;
        enableZshIntegration = true;
        enableBashIntegration = true;
        nix-direnv.enable = true;
      };
      fd = {
        enable = true;
        hidden = true;
        ignores = [
          ".git"
          ".DS_Store"
        ];
      };
      pay-respects = {
        enable = true;
        enableBashIntegration = true;
        enableZshIntegration = true;
        options = [
          "--alias"
          "f"
        ];
      };
      carapace = {
        enable = true;
        enableBashIntegration = true;
        enableZshIntegration = true;
      };
    };
    home.packages =
      with pkgs;
      [
        bar
        cloudflare-cli
        cpx
        detox
        duf
        dust
        fastcrw
        hyperfine
        pq-cli
        procs
        progress
        pv
        rsyncy
        sqlite
        stripe-cli
        supabase-cli
        tealdeer
        tokei
        trash-cli
        trippy
        wrangler
        xxh
      ]
      ++ [
        (writeShellScriptBin "cgc" ''
          if [ -x "$HOME/.local/bin/cgc" ]; then
            exec "$HOME/.local/bin/cgc" "$@"
          elif [ -x "$HOME/.local/share/uv/tools/codegraphcontext/bin/cgc" ]; then
            exec "$HOME/.local/share/uv/tools/codegraphcontext/bin/cgc" "$@"
          else
            echo "Error: cgc not found in ~/.local/bin or ~/.local/share/uv/tools" >&2
            exit 1
          fi
        '')
        (writeShellScriptBin "codegraphcontext" ''
          exec cgc "$@"
        '')
      ];

    home.activation.token-saver-symlinks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p "$HOME/.config/crw" "$HOME/.codegraphcontext/.venv/bin"
      if [ -e "$HOME/.local/bin/crw" ]; then
        $DRY_RUN_CMD ln -sfn "$HOME/.local/bin/crw" "$HOME/.config/crw/crw"
      fi
      if [ -e "$HOME/.local/bin/cgc" ]; then
        $DRY_RUN_CMD ln -sfn "$HOME/.local/bin/cgc" "$HOME/.codegraphcontext/.venv/bin/cgc"
      fi
    '';
  };
}
