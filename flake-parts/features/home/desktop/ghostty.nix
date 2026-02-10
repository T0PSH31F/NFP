{
  lib,
  osConfig,
  ...
}:
let
  clanTags = osConfig.clan.core.tags or [ ];
in
{
  config = lib.mkIf (builtins.elem "desktop" clanTags) {
    programs.ghostty = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      settings = {
        # theme = "catppuccin-mocha";
        font-family = "JetBrainsMono Nerd Font";
        font-size = 16;
        shell-integration-features = true;
        window-decoration = false;
        confirm-close-surface = false;
        window-padding-x = 4;
        window-padding-color = "extend";
        window-padding-balance = true;

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

    xdg.configFile."ghostty/config".text = lib.mkAfter ''
      custom-shader = ${../assets/shaders/neon.glsl}
      custom-shader = ${../assets/shaders/cursor_trail_neon.glsl}
    '';

    xdg.configFile."ghostty/config".force = true;
  };
}
