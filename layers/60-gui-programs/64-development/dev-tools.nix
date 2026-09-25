{
  pkgs,
  lib,
  config,
  osConfig ? config,
  ...
}:
let
  cfg = config.layers.layer-60.gui.dev-tools;
in
{
  options.layers.layer-60.gui.dev-tools = {
    enable = lib.mkEnableOption "GUI development tools";
  };

  nixos = { };

  home = lib.mkIf cfg.enable {
    # `crush` not listed here — provided by layers.layer-71.harness.crush.
    home.packages = with pkgs; [
      abtop
      angryoxide
      angryipscanner
      beadwork
      cc-switch
      curlie
      cyberstrike
      devin-desktop
      hcom
      httpie
      ketch
      kiro
      obscura
      postman
      vhs
      yq

      # Database GUI Managers
      beekeeper-studio
      pgadmin4-desktopmode
    ];

    home.activation.setupSshConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            mkdir -p $HOME/.ssh
            chmod 700 $HOME/.ssh
            if [ ! -f $HOME/.ssh/config ] || [ -L $HOME/.ssh/config ]; then
              rm -f $HOME/.ssh/config
              cat > $HOME/.ssh/config << 'EOF'
              AddKeysToAgent yes

              Host z0r0.local
                  StrictHostKeyChecking no
                  UserKnownHostsFile /dev/null
                  LogLevel ERROR

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
