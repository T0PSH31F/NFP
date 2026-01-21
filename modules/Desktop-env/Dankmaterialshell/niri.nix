{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  # DankMaterialShell Niri-specific config
  # Source: https://github.com/AvengeMedia/DankMaterialShell

  config = lib.mkIf (config.desktop.dankmaterialshell.enable && (config.desktop.dankmaterialshell.backend == "niri" || config.desktop.dankmaterialshell.backend == "both")) {
    home-manager.users.t0psh31f = {
      imports = [
        inputs.niri.homeModules.niri
        inputs.dms.homeModules.niri
      ];

      systemd.user.services.niri-flake-polkit.Install.WantedBy = lib.mkForce [];

      # Niri-specific DankMaterialShell config
      programs.dank-material-shell = {
        niri = {
          includes = {
            enable = true;
            override = true;
            originalFileName = "hm";
            filesToInclude = [
              "alttab"
              "binds"
              "colors"
              "layout"
              "outputs"
              "wpblur"
            ];
          };
          enableSpawn = true;
        };
      };
    };
  };
}
