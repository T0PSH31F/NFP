{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = lib.mkIf (config.clan.lib.hasTag "desktop") {
    fonts = {
      enableDefaultPackages = lib.mkForce false;

      packages = with pkgs; [
        nerd-fonts.jetbrains-mono
        nerd-fonts.fira-code
        inter
        font-awesome
        material-design-icons
        noto-fonts-color-emoji
      ];

      fontconfig = {
        enable = true;
        defaultFonts = {
          monospace = [
            "JetBrainsMono Nerd Font"
            "FiraCode Nerd Font"
          ];
          sansSerif = [ "Inter" ];
          emoji = [ "Noto Color Emoji" ];
        };
      };
    };
  };
}
