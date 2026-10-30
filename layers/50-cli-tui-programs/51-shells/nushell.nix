# Nushell Shell Integration Module
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.layers.layer-50.cli.nushell;
in
{
  options.layers.layer-50.cli.nushell = {
    enable = lib.mkEnableOption "Nushell modern structured shell";
  };

  home = lib.mkIf cfg.enable {
    programs = {
      nushell = {
        enable = true;
        package = pkgs.nushell;
        configFile.text = ''
          $env.config = {
            show_banner: false
            edit_mode: "vi"
            ls: {
              use_ls_colors: true
              clickable_links: true
            }
            rm: {
              always_trash: false
            }
            table: {
              mode: rounded
              index_mode: always
            }
          }
        '';
      };

      zoxide = {
        enable = true;
        enableNushellIntegration = true;
      };

      direnv = {
        enable = true;
        enableNushellIntegration = true;
      };
    };

    home.persistence."/persist/home/${config.home.username}" = {
      directories = [
        ".local/share/nushell"
      ];
    };
  };
}
