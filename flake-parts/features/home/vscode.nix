{
  pkgs,
  lib,
  osConfig,
  ...
}:
let
  clanTags = osConfig.clan.core.tags or [ ];
in
{
  config = lib.mkIf (builtins.elem "dev" clanTags) {
    # VS Code with FHS compatibility
    programs.vscode = {
      enable = true;
      package = pkgs.vscode-fhs;
    };
    programs.npm.enable = true;
  };
}
