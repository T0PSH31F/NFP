# Tier: 77-dash-desk-ui
# Module: chat-guis.nix
# Purpose: Native AI chat GUIs & desktop assistants (Newelle, Cheating-Daddy)
# Option Path: layers.layer-77.dash-desk-ui.chat-guis
# Enabling Host Tags: desktop, ai-agent, workstation
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.layers.layer-77.dash-desk-ui.chat-guis;
in
{
  options.layers.layer-77.dash-desk-ui.chat-guis = {
    enable = lib.mkEnableOption "Native AI chat GUIs & desktop assistants (Newelle, Cheating-Daddy)";
  };

  home = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      newelle
      cheating-daddy
    ];
  };
}
