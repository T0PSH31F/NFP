{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.programs.yazelix;
in
{
  options.programs.yazelix = {
    enable = mkEnableOption "Yazelix - Yazi + Helix integration";

    package = mkOption {
      type = types.package;
      default = pkgs.helix;
      description = "Helix package to use";
    };

    yaziPackage = mkOption {
      type = types.package;
      default = pkgs.yazi;
      description = "Yazi package to use";
    };

    defaultEditor = mkOption {
      type = types.bool;
      default = true;
      description = "Set Helix as the default editor";
    };

    theme = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Helix theme to use";
    };

    settings = mkOption {
      type = types.attrs;
      default = { };
      description = "Additional Helix settings";
    };

    languages = mkOption {
      type = types.attrs;
      default = { };
      description = "Language server configurations";
    };

    extraPackages = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "Extra packages for language servers and tools";
    };
  };

  config = mkIf cfg.enable {
    programs.helix = {
      enable = true;
      package = cfg.package;
      defaultEditor = cfg.defaultEditor;

      settings = mkMerge [
        {
          editor = {
            text-width = 80;
            lsp = {
              display-messages = true;
              display-inlay-hints = true;
            };
            soft-wrap.enable = false;
            inline-diagnostics.cursor-line = "warning";
            end-of-line-diagnostics = "hint";
            popup-border = "all";
            color-modes = true;
            file-picker.hidden = false;
            bufferline = "multiple";

            cursor-shape = {
              insert = "bar";
              normal = "block";
              select = "block";
            };

            statusline = {
              left = [
                "mode"
                "file-name"
                "diagnostics"
                "version-control"
                "read-only-indicator"
                "file-modification-indicator"
              ];
              center = [ ];
              right = [
                "register"
                "file-type"
                "file-encoding"
                "selections"
                "position"
                "position-percentage"
                "spinner"
              ];
              separator = "│";
              mode = {
                normal = "NORMAL";
                insert = "INSERT";
                select = "SELECT";
              };
            };

            indent-guides = {
              render = true;
              character = "▏";
            };
          };

          # Yazelix-specific keybindings
          keys.normal = {
            space.f = ":sh yazi-picker open<ret>";
            space.F = ":sh yazi-picker vsplit<ret>";
          };
        }
        cfg.settings
      ];

      languages = cfg.languages;
    };

    programs.yazi = {
      enable = true;
      package = cfg.yaziPackage;
      enableZshIntegration = true;
      enableBashIntegration = true;

      settings = {
        manager = {
          show_hidden = true;
          sort_by = "natural";
          sort_dir_first = true;
        };
      };
    };

    # Yazi-picker script for Helix integration
    home.packages =
      with pkgs;
      [
        # Core dependencies
        nodejs_24
        yarn
        uv
        docker-compose
        powershell
        typst

        # Yazi-picker script for Helix integration
        (writeShellScriptBin "yazi-picker" ''
          paths=$(yazi "$2" --chooser-file=/dev/stdout | while read -r; do printf "%q " "$REPLY"; done)

          if [[ -n "$paths" ]]; then
          	zellij action toggle-floating-panes
          	zellij action write 27 # send <Escape> key
          	zellij action write-chars ":$1 $paths"
          	zellij action write 13 # send <Enter> key
          else
          	zellij action toggle-floating-panes
          fi
        '')

        # LLM helper scripts
        (writeShellScriptBin "llm-gen-commit-msg" ''
          gemini --yolo --prompt-interactive "
          Write a Git commit message for staged changes.

          - Match the existing commit style if possible.
          - If unclear, use Conventional Commit format: feat|fix|chore|refactor(scope): summary.
          - Keep under 72 chars; add a short body if useful.
          - Do not edit files — only output the commit message.
          "
        '')

        (writeShellScriptBin "llm-do-anal" ''
          gemini --yolo --prompt-interactive "
          Review the current codebase and suggest improvements.

          Identify design, performance, or readability issues.
          Be specific: reference files or functions.
          Output recommendations only; do not edit files.
          "
        '')

        (writeShellScriptBin "llm-explain" ''
          gemini --yolo --prompt-interactive "
          Explain the codebase for a new developer.

          Summarize structure, key modules, and interactions.
          Focus on clarity and accuracy.
          Output only your explanation; do not edit files.
          "
        '')
      ]
      ++ cfg.extraPackages;
  };
}
