{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.cli-environment;
in
{
  config = lib.mkIf cfg.enable {
    programs.gpg = {
      enable = true;
    };
    services.gpg-agent = {
      enable = true;
      pinentryPackage = pkgs.pinentry-gnome3;
      enableSshSupport = true;
    };
  };
}
