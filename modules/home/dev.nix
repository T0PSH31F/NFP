{
  config,
  pkgs,
  lib,
  clanTags,
  ...
}:
{
  config = lib.mkIf (builtins.elem "dev" clanTags) {
    home.packages = with pkgs; [
      # Editor tooling
      neovim
      vscode

      # CLIs
      httpie
      curlie
      jq
      yq
    ];

    programs.ssh = {
      enable = true;
      matchBlocks = {
        "github.com" = {
          hostname = "github.com";
          user = "git";
          identityFile = "~/.ssh/id_ed25519";
        };
      };
    };
  };
}
