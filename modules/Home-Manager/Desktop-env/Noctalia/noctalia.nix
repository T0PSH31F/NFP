# modules/nixos/themes/noctalia.nix
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.themes.noctalia;
in
{
  options.themes.noctalia = {
    enable = mkEnableOption "Noctalia theming system";

    package = mkOption {
      type = types.package;
      default = pkgs.noctalia;
      description = "The Noctalia package to use";
    };

    templates = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              description = "Template name";
            };
            inputPath = mkOption {
              type = types.path;
              description = "Path to template file";
            };
            outputPath = mkOption {
              type = types.str;
              description = "Where to write generated theme";
            };
            postHook = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Command to run after generation";
            };
          };
        }
      );
      default = [ ];
      description = "List of user templates to process";
    };

    autoReload = mkOption {
      type = types.bool;
      default = true;
      description = "Automatically reload services when themes change";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    # Generate user-templates.toml from NixOS config
    environment.etc."noctalia/user-templates.toml".text = ''
      ${concatMapStringsSep "\n\n" (template: ''
        [[templates]]
        name = "${template.name}"
        input_path = "${template.inputPath}"
        output_path = "${template.outputPath}"
        ${optionalString (template.postHook != null) ''post_hook = "${template.postHook}"''}
      '') cfg.templates}
    '';

    # Systemd service to watch for theme changes
    systemd.user.services.noctalia-watcher = mkIf cfg.autoReload {
      description = "Noctalia Theme Watcher";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/noctalia watch";
        Restart = "on-failure";
        RestartSec = 3;
      };
    };

    # Home-manager integration
    home-manager.sharedModules = [
      {
        home.packages = [ cfg.package ];

        xdg.configFile."noctalia/user-templates.toml".source =
          config.environment.etc."noctalia/user-templates.toml".source;
      }
    ];
  };
}
