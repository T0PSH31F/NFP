{
  config,
  pkgs,
  lib,
  clanTags,
  ...
}:
{
  config = lib.mkIf (builtins.elem "desktop" clanTags) {
    xdg.configFile."ghostty/config".text = ''
      theme = catppuccin-mocha
      font-family = "JetBrainsMono Nerd Font"
      window-decoration = false
      confirm-close-surface = false

      # Shader configuration (example: crt)
      # You can change this to bloom, glitch, etc.
      custom-shader = ${pkgs.ghostty}/share/ghostty/shaders/bloom.glsl
    '';
  };
}
