{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.layers.layer-60.gui.communication;
in
{
  imports = [
    ./beeper.nix
    ./bitlbee.nix
    ./discord.nix
  ];

  options.layers.layer-60.gui.communication = {
    enable = lib.mkEnableOption "communication & messaging applications";
  };

  # Multi-class `home` key: mkDendriticModule routes this into
  # home-manager.users.<primaryUser>. Do NOT rename to `config` — bare
  # `home.packages` is not a NixOS option.
  home = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      ayugram-desktop # Telegram
      caprine # FB messenger
      cinny-desktop # Matrix
      element-desktop # Matrix
      equibop # discord
      fedistar # fediverse client
      fediwall # fediverse client
      ferdium # fediverse client (i think)
      flare-signal # Signal
      kotatogram-desktop # fediverse client
      signal-cli # Signal
      signal-desktop # signal
      tdl # telegram downloader
    ];
  };
}
