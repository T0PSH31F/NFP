{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.layers.layer-50.cli;
in
{
  home = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      bottom
      btop
      countryfetch
      cyberpunk-neon
      fastfetch
      ffmpeg
      gping
      gum
      htop
      hue-plus
      hueadm
      iftop
      iotop
      neohtop
      neowall
      openhue-cli
      razer-cli
      tailscale
      tmuxai
    ];
    programs = {
      rbw.enable = true;
      aria2.enable = true;
      aria2p.enable = true;
      pistol.enable = true;
    };
  };
}
