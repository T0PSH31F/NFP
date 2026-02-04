{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = lib.mkIf (config.clan.lib.hasTag "gaming") {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };

    programs.gamemode.enable = true;

    environment.systemPackages = with pkgs; [
      lutris
      wine
      winetricks
    ];

    # Optional: adjust kernel limits for some games
    boot.kernel.sysctl."vm.max_map_count" = 2147483642;
  };
}
