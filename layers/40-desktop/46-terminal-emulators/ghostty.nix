# Ghostty Terminal Emulator Module
{
  config,
  lib,
  osConfig ? config,
  ...
}:
let
  clanTags = osConfig.machine.tags or [ ];
  shaderPath = ../../00-cyberia/02-assets/shaders/manga_slash.glsl;
  shaderExists = builtins.pathExists shaderPath;
in
{
  config = lib.mkIf (builtins.elem "desktop" clanTags) {
    assertions = [
      {
        assertion = shaderExists;
        message = "Ghostty cursor shader missing at ${toString shaderPath}";
      }
    ];

    programs.ghostty = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      settings = {
        font-family = "JetBrains Mono Nerd Font";
        font-size = 16;
        shell-integration-features = true;
        window-decoration = false;
        confirm-close-surface = false;
        window-padding-x = 4;
        window-padding-color = "extend";
        window-padding-balance = true;

        cursor-style = "block";
        cursor-style-blink = true;

        # Custom GLSL cursor shader (manga_slash.glsl in assets)
        # Note: GLSL cursor shaders render on top-level Ghostty surfaces,
        # but do not render inside text-cell multiplexers (Zellij/Tmux panes).
        custom-shader = "${shaderPath}";

        keybind = [
          "ctrl+alt+v=new_split:right"
          "ctrl+alt+s=new_split:down"
          "ctrl+alt+n=new_split:auto"
          "ctrl+shift+h=goto_split:left"
          "ctrl+shift+j=goto_split:bottom"
          "ctrl+shift+k=goto_split:top"
          "ctrl+shift+l=goto_split:right"
          "ctrl+shift+w=close_surface"
          "page_up=scroll_page_fractional:-0.5"
          "page_down=scroll_page_fractional:+0.5"
        ];
      };
    };
  };
}
