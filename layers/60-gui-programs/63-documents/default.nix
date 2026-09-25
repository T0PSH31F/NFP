{
  config,
  lib,
  pkgs,
  mkDendriticModule,
  ...
}:
let
  cfg = config.layers.layer-60.gui.documents;
in
{
  imports = [
    (mkDendriticModule "zathura" ./zathura.nix)
  ];

  options.layers.layer-60.gui.documents = {
    enable = lib.mkEnableOption "Documents, Publishing & Desktop utilities";
  };

  home = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      libreoffice-fresh
      pandoc
      pdfmm
      texliveFull
      scribus
      sigil
      obsidian
      z-library-desktop
      tutanota-desktop
      webull-desktop
      hicolor-icon-theme
    ];
  };
}
