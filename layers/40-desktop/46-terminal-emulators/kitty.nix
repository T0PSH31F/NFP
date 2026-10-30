{
  config,
  lib,
  ...
}:
{
  options.layers.layer-40.desktop.terminals.kitty = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Kitty terminal emulator";
    };
  };

  config = lib.mkIf config.layers.layer-40.desktop.terminals.kitty.enable {
    programs.kitty = {
      enable = true;
      font = {
        name = lib.mkForce "JetBrains Mono Nerd Font";
        size = 14;
      };
      settings = {
        background_opacity = lib.mkForce "0.9";
        enable_audio_bell = lib.mkForce false;
        confirm_os_window_close = lib.mkForce 0;
      };
    };
  };
}
