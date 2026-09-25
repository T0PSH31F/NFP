# Tier: 55-prompt
# Module: atuin.nix
# Purpose: Atuin shell history sync across bash/zsh/nushell on all machines.
# Option Path: layers.layer-50.cli.prompt.atuin
# Enabling Host Tags: workstation, desktop, homelab
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.layers.layer-50.cli.prompt.atuin;
in
{
  options.layers.layer-50.cli.prompt.atuin = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Atuin shell prompt history sync across all machines";
    };

    autoSync = mkOption {
      type = types.bool;
      default = true;
      description = "Enable automatic history synchronization";
    };

    syncFrequency = mkOption {
      type = types.str;
      default = "1h";
      description = "Atuin auto-sync frequency";
    };
  };

  home = mkIf cfg.enable {
    programs.atuin = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      enableNushellIntegration = true;
      flags = [
        "--disable-up-arrow"
      ];
      settings = {
        auto_sync = cfg.autoSync;
        sync_frequency = cfg.syncFrequency;
        search_mode = "fuzzy";
        filter_mode = "global";
        style = "compact";
        inline_height = 20;
        enter_accept = false;
      };
    };
  };
}
