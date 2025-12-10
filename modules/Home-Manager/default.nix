{
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.spicetify-nix.homeManagerModules.default
    # Core Packages
    ./home-packages.nix

    # Browsers
    ./browsers

    # Media
    ./mpv.nix
    ./swayimg.nix

    # Desktop
    ./xdg.nix

    # Shells & Terminals (using directory default.nix)
    ./shell

    # Tools (using directory default.nix)
    ./tools

    # Editors (using directory default.nix)
    ./editors

    # File Managers
    ./yazi

    # Penetration Testing (commented out)
    # ./pentest
  ];

  programs.home-manager.enable = true;

  # Git configuration
  programs.git = {
    enable = true;
    userName = "Grandlix User";
    userEmail = "user@grandlix.gang";

    delta = {
      enable = true;
      options = {
        features = "decorations";
        side-by-side = true;
        navigate = true;
      };
    };

    aliases = {
      st = "status";
      co = "checkout";
      br = "branch";
      cm = "commit -m";
      lg = "log --graph --oneline --decorate";
      unstage = "reset HEAD --";
      last = "log -1 HEAD";
    };

    settings = {
      init.defaultBranch = "main";
      pull.rebase = false;
      push.autoSetupRemote = true;
      merge.conflictStyle = "diff3";
      diff.colorMoved = "default";
    };
  };
}
