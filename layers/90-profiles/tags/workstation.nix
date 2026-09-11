# workstation — base limits, themes, network tools, ssh
# Tags-as-data: all config gated by tag membership.
{ config, lib, ... }:
{
  config = lib.mkIf (builtins.elem "workstation" config.machine.tags) {
    layers = {
      layer-10.system.config.resource-limits.enable = lib.mkDefault true;
      layer-50.cli.nixTools.enable = lib.mkDefault true;
      layer-50.home.cli.services.rclone.enable = lib.mkDefault true;
      layer-30.theming.themes = {
        grub-lain.enable = lib.mkDefault false;
        plymouth-hellonavi.enable = lib.mkDefault false;
      };
      layer-20.services.config = {
        avahi.enable = lib.mkDefault true;
        tailscale.enable = lib.mkDefault true;
        monitoring.enable = lib.mkDefault true;
        syncthing.enable = lib.mkDefault true;
      };
      layer-20.services.backups.restic.enable = lib.mkDefault true;
    };

    services.ssh-agent.enable = lib.mkDefault true;
  };
}
