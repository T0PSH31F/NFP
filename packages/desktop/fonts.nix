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
        font-awesome
        inter
        material-design-icons
        nerd-fonts.fira-code
        nerd-fonts.jetbrains-mono
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
