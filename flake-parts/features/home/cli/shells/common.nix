# flake-parts/features/home/cli/shells/common.nix
{ config, lib, ... }:

let
  cfg = config.programs.cli-environment;
in
{
  config = lib.mkIf cfg.enable {
    home.sessionVariables = {
      EDITOR = "hx";
      VISUAL = "hx";
      PAGER = "bat";
      MANPAGER = "sh -c 'col -bx | bat -l man -p'";
    };

    home.shellAliases = {
      # Editor shortcuts
      e = "hx";
      edit = "hx";
      vi = "hx";
      vim = "hx";
      v = "hx";

      # File Manager
      f = "yazi";
      fm = "yazi";

      # Modern replacements
      cat = "bat";
      ps = "procs";
      diff = "delta";
      gg = "lazygit";
      l = "eza -lh";
      ll = "eza -lah";
      ls = "eza";
      tree = "eza --tree";
      serve = "miniserve";
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      "....." = "cd ../../../..";

      # Nix shortcuts
      nrs = "sudo nixos-rebuild switch --flake ~/Clan/Grandlix-Gang";
      nrt = "sudo nixos-rebuild test --flake ~/Clan/Grandlix-Gang";
      nfc = "nix flake check";
      nfu = "nix flake update";

      # Clan machine management
      cbuild = "clan machines build";
      cupdate = "clan machines update";

      # System Monitoring
      htop = "btop";
      top = "btop";

      # Misc
      weather = "curl wttr.in";
      myip = "curl ifconfig.me";
      ports = "ss -tulanp";
      sysinfo = "fastfetch";
    };

    # Custom shell functions
    programs.zsh.initContent = lib.mkIf cfg.shells.zsh.enable ''
      # Project navigation
      proj() {
        local project_dir="$HOME/projects"
        if [[ -d "$project_dir" ]]; then
          cd "$project_dir/$1" 2>/dev/null || cd "$project_dir"
        fi
      }

      clan() {
        local clan_dir="$HOME/Clan"
        if [[ -d "$clan_dir" ]]; then
          cd "$clan_dir/$1" 2>/dev/null || cd "$clan_dir"
        fi
      }

      # Nix search helper
      ns() {
        nix-search-tv print | fzf --preview 'nix-search-tv preview {}' --scheme history
      }

      # SSH keyscan helper
      sshks() {
        ssh-keyscan -t ed25519 192.168.1.0/24 >> ~/.ssh/known_hosts
      }
    '';
  };
}
