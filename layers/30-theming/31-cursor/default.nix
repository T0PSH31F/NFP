# Unified Cursor Theming Module
{
  config,
  lib,
  pkgs,
  osConfig ? config,
  ...
}:
let
  sonic-hyprcursor = pkgs.stdenv.mkDerivation {
    pname = "sonic-hyprcursor";
    version = "1.0.0";
    src = ../../00-cyberia/02-assets/cursors/Sonic-cursor-hyprcursor;
    installPhase = ''
      mkdir -p $out/share/icons/Sonic-Hyprcursor
      cp -r Sonic-Hyprcursor/* $out/share/icons/Sonic-Hyprcursor/
    '';
  };
in
{
  options.layers.layer-30.theming.cursor = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable custom cursor themes";
    };

    size = lib.mkOption {
      type = lib.types.int;
      default = 64;
      description = "Size of the cursor (e.g. 24, 32, 48, 64)";
    };
  };

  # System level packages for cursor
  nixos =
    let
      cfg = osConfig.layers.layer-30.theming.cursor;
    in
    lib.mkIf cfg.enable {
      environment.systemPackages = [ sonic-hyprcursor ];
    };

  # Home Manager pointerCursor settings
  home =
    let
      cfg = osConfig.layers.layer-30.theming.cursor;
    in
    lib.mkIf cfg.enable {
      home.packages = with pkgs; [
        hyprcursor
        sonic-hyprcursor
        rose-pine-hyprcursor
      ];

      home.activation.cleanSonicCursor = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
        for target in "Sonic-Hyprcursor" "rose-pine"; do
          for path in "$HOME/.local/share/icons/$target" "$HOME/.icons/$target"; do
            if [ -d "$path" ] && [ ! -L "$path" ]; then
              echo "Removing physical directory $path to avoid Home Manager symlink conflict"
              rm -rf "$path"
            fi
          done
        done
      '';

      home.pointerCursor = {
        enable = lib.mkForce true; # explicit — relying on non-null to auto-enable is deprecated
        package = lib.mkForce sonic-hyprcursor;
        name = lib.mkForce "Sonic-Hyprcursor";
        size = lib.mkForce cfg.size;
        gtk.enable = lib.mkForce true;
        x11.enable = lib.mkForce true;
        hyprcursor = {
          enable = lib.mkForce true;
          size = lib.mkForce cfg.size;
        };
      };
    };
}
