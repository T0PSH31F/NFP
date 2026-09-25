{
  pkgs,
  lib,
  config,
  ...
}:
{
  options.layers.layer-40.desktop.dolphin = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Dolphin file manager";
    };
  };

  home = lib.mkIf config.layers.layer-40.desktop.dolphin.enable {
    home.packages = with pkgs; [
      kdePackages.dolphin
      kdePackages.dolphin-plugins
      kdePackages.kservice
    ];

    home.activation.kbuildsycoca = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD ${pkgs.kdePackages.kservice}/bin/kbuildsycoca6 --noincremental || true
    '';
  };
}
