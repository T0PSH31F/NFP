{ pkgs, ... }:
{
  services.flameshot = {
    enable = true;
    package = pkgs.flameshot;
    settings = {
      General = {
        disabledTrayIcon = true;
        showStartupLaunchMessage = false;
      };
    };
  };
}
