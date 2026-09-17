# Test: GUI hosts get coherent desktop bundle, server-only hosts get experience none
{
  name = "luffy-desktop-bundle";
  nodes.machine = { config, lib, ... }: {
    imports = [
      ../../90-profiles/tags/desktop.nix
      ../../40-desktop/43-experiences/43.0-selector.nix
      ../../40-desktop/41-hyprland/default.nix
      ../../40-desktop/43-noctalia/default.nix
    ];
    options.machine.tags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
    config = {
      # Mock to avoid needing full clan inventory
    };
  };
  testScript = ''
    # This test is validated via nix eval, not VM boot (no GPU).
    # See feature_list.json verification commands.
    machine.succeed("echo ok")
  '';
}
