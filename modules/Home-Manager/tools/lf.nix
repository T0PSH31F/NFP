{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.lf = {
    enable = true;
    settings = {
      preview = true;
      hidden = true;
      drawbox = true;
      icons = true;
      ignorecase = true;
    };

    extraConfig = ''
      set previewer ${pkgs.ctpv}/bin/ctpv
      set cleaner ${pkgs.ctpv}/bin/ctpvclear
      &${pkgs.ctpv}/bin/ctpv -s $id
      &${pkgs.ctpv}/bin/ctpvquit $id
    '';
  };
}
