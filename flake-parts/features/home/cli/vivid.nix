{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.programs.vivid;

  # Generate vivid theme from Matugen colors
  vividThemeTemplate = ''
    colors:
      # Material You colors from Matugen
      primary: '{{colors.primary.default.hex}}'
      primary_container: '{{colors.primary_container.default.hex}}'
      secondary: '{{colors.secondary.default.hex}}'
      secondary_container: '{{colors.secondary_container.default.hex}}'
      tertiary: '{{colors.tertiary.default.hex}}'
      tertiary_container: '{{colors.tertiary_container.default.hex}}'
      error: '{{colors.error.default.hex}}'
      error_container: '{{colors.error_container.default.hex}}'
      
      surface: '{{colors.surface.default.hex}}'
      surface_dim: '{{colors.surface_dim.default.hex}}'
      surface_bright: '{{colors.surface_bright.default.hex}}'
      surface_container: '{{colors.surface_container.default.hex}}'
      surface_container_low: '{{colors.surface_container_low.default.hex}}'
      surface_container_high: '{{colors.surface_container_high.default.hex}}'
      
      on_primary: '{{colors.on_primary.default.hex}}'
      on_secondary: '{{colors.on_secondary.default.hex}}'
      on_tertiary: '{{colors.on_tertiary.default.hex}}'
      on_surface: '{{colors.on_surface.default.hex}}'
      on_error: '{{colors.on_error.default.hex}}'
      
      outline: '{{colors.outline.default.hex}}'
      outline_variant: '{{colors.outline_variant.default.hex}}'
      
    core:
      normal_text:
        foreground: on_surface
      
      regular_file:
        foreground: on_surface
      
      reset_to_normal:
        foreground: on_surface
      
      directory:
        foreground: primary
        font-style: bold
      
      symlink:
        foreground: tertiary
        font-style: bold
      
      multi_hard_link: {}
      
      fifo:
        foreground: secondary
        background: surface_container
        font-style: bold
      
      socket:
        foreground: tertiary
        background: surface_container
        font-style: bold
      
      door:
        foreground: tertiary
        background: surface_container
        font-style: bold
      
      block_device:
        foreground: secondary
        background: surface_container
        font-style: bold
      
      character_device:
        foreground: secondary
        background: surface_container
        font-style: bold
      
      broken_symlink:
        foreground: error
        background: error_container
        font-style: bold
      
      missing_symlink_target:
        foreground: error
        background: error_container
        font-style: bold
      
      setuid:
        foreground: on_error
        background: error
        font-style: bold
      
      setgid:
        foreground: on_error
        background: error
        font-style: bold
      
      file_with_capability:
        foreground: on_error
        background: error
      
      sticky_other_writable:
        foreground: on_primary
        background: primary_container
      
      other_writable:
        foreground: primary
        font-style: bold
      
      sticky:
        foreground: on_primary
        background: primary
      
      executable_file:
        foreground: secondary
        font-style: bold

    text:
      special:
        foreground: tertiary
      
      todo:
        foreground: error
        font-style: bold
      
      licenses:
        foreground: outline
      
      configuration:
        foreground: secondary
      
      other:
        foreground: on_surface

    markup:
      foreground: tertiary

    programming:
      source:
        foreground: primary
      
      tooling:
        foreground: secondary
      
      protocol:
        foreground: tertiary
      
      data:
        foreground: on_surface

    media:
      image:
        foreground: tertiary
      
      audio:
        foreground: primary
      
      video:
        foreground: secondary
        font-style: bold
      
      fonts:
        foreground: tertiary_container
      
      3d:
        foreground: tertiary
        font-style: bold

    office:
      foreground: primary_container

    archives:
      foreground: error
      font-style: bold

    executable:
      foreground: secondary

    unimportant:
      foreground: outline_variant
  '';
in
{
  options.programs.vivid.matugen = {
    enable = mkEnableOption "Matugen integration for vivid";

    outputColorMode = mkOption {
      type = types.enum [
        "8-bit"
        "24-bit"
      ];
      default = "24-bit";
      description = "Color mode for terminal output";
    };

    customTheme = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Path to custom vivid theme YAML file";
    };
  };

  config = mkIf cfg.matugen.enable {
    # We don't enable the upstream vivid module here to avoid conflicts or double-setting
    # Instead we manually add the package and shell integration

    home.packages = [ pkgs.vivid ];

    # Create vivid config directory structure
    xdg.configFile = mkMerge [
      # Matugen theme template
      {
        "matugen/templates/vivid.yml" = {
          text = vividThemeTemplate;
        };
      }

      # Custom theme if provided
      (mkIf (cfg.matugen.customTheme != null) {
        "vivid/themes/custom.yml" = {
          source = cfg.matugen.customTheme;
        };
      })
    ];

    # Shell integration for bash
    programs.bash = mkIf config.programs.bash.enable {
      initExtra = mkAfter ''
        # Vivid LS_COLORS integration
        if command -v vivid &> /dev/null; then
          # Use Matugen-generated theme if available
          if [ -f "$HOME/.config/matugen/vivid.yml" ]; then
            export LS_COLORS="$(vivid -m ${cfg.matugen.outputColorMode} generate $HOME/.config/matugen/vivid.yml)"
          elif [ -f "$HOME/.config/vivid/themes/matugen.yml" ]; then
            export LS_COLORS="$(vivid -m ${cfg.matugen.outputColorMode} generate matugen)"
          else
            export LS_COLORS="$(vivid -m ${cfg.matugen.outputColorMode} generate snazzy)"
          fi
        fi
      '';
    };

    # Shell integration for zsh
    programs.zsh = mkIf config.programs.zsh.enable {
      initExtra = mkAfter ''
        # Vivid LS_COLORS integration
        if command -v vivid &> /dev/null; then
          # Use Matugen-generated theme if available
          if [[ -f "$HOME/.config/matugen/vivid.yml" ]]; then
            export LS_COLORS="$(vivid -m ${cfg.matugen.outputColorMode} generate $HOME/.config/matugen/vivid.yml)"
          elif [[ -f "$HOME/.config/vivid/themes/matugen.yml" ]]; then
            export LS_COLORS="$(vivid -m ${cfg.matugen.outputColorMode} generate matugen)"
          else
            export LS_COLORS="$(vivid -m ${cfg.matugen.outputColorMode} generate snazzy)"
          fi
        fi
      '';
    };

    # Shell integration for fish
    programs.fish = mkIf config.programs.fish.enable {
      shellInit = mkAfter ''
        # Vivid LS_COLORS integration
        if command -v vivid &> /dev/null
          # Use Matugen-generated theme if available
          if test -f "$HOME/.config/matugen/vivid.yml"
            set -gx LS_COLORS (vivid -m ${cfg.matugen.outputColorMode} generate $HOME/.config/matugen/vivid.yml)
          else if test -f "$HOME/.config/vivid/themes/matugen.yml"
            set -gx LS_COLORS (vivid -m ${cfg.matugen.outputColorMode} generate matugen)
          else
            set -gx LS_COLORS (vivid -m ${cfg.matugen.outputColorMode} generate snazzy)
          end
        end
      '';
    };

    # Shell integration for nushell
    programs.nushell = mkIf config.programs.nushell.enable {
      extraEnv = mkAfter ''
        # Vivid LS_COLORS integration
        let vivid_theme = if ("~/.config/matugen/vivid.yml" | path exists) {
          (vivid -m ${cfg.matugen.outputColorMode} generate ~/.config/matugen/vivid.yml)
        } else if ("~/.config/vivid/themes/matugen.yml" | path exists) {
          (vivid -m ${cfg.matugen.outputColorMode} generate matugen)
        } else {
          (vivid -m ${cfg.matugen.outputColorMode} generate snazzy)
        }
        $env.LS_COLORS = $vivid_theme
      '';
    };
  };
}
