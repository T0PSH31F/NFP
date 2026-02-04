{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = lib.mkIf (config.clan.lib.hasTag "server") {
    environment.systemPackages = with pkgs; [
      # docker # Keep docker out if virtualization.docker.enable handles it
      aria2
      rsync
      screen
    ];

    virtualisation.docker.enable = true;
  };
}
