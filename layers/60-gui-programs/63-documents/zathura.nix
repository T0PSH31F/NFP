{
  config,
  lib,
  ...
}:
{
  options.layers.layer-60.gui.documents.zathura = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Zathura PDF viewer";
    };
  };

  home =
    lib.mkIf
      (config.layers.layer-60.gui.documents.enable && config.layers.layer-60.gui.documents.zathura.enable)
      {
        programs.zathura = {
          enable = true;
          options = {
            selection-clipboard = "clipboard";
          };
          extraConfig = "include noctaliarc";
        };

      };
}
