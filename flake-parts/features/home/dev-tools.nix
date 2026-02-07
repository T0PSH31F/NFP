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
      # vscode is configured in vscode.nix with vscode-fhs

      # CLIs
      httpie
      curlie
      jq
      yq
    ];

    # Note: programs.ssh creates a symlink with wrong permissions
    # Instead, we'll manage SSH config manually or use a systemd activation script
    # programs.ssh is disabled to avoid the "Bad owner or permissions" error
    home.activation.setupSshConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            mkdir -p $HOME/.ssh
            chmod 700 $HOME/.ssh
            if [ ! -f $HOME/.ssh/config ] || [ -L $HOME/.ssh/config ]; then
              rm -f $HOME/.ssh/config
              cat > $HOME/.ssh/config << 'EOF'
      Host github.com
          HostName github.com
          User git
          IdentityFile ~/.ssh/id_ed25519
      EOF
              chmod 600 $HOME/.ssh/config
            fi
    '';
  };
}
