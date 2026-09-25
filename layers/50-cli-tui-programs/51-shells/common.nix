{ config, lib, ... }:
let
  cfg = config.layers.layer-50.cli;
in
{
  home = lib.mkIf cfg.enable {
    home.sessionVariables = {
      EDITOR = "hx";
      VISUAL = "hx";
      PAGER = "bat";
      MANPAGER = "sh -c 'col -bx | bat -l man -p'";
      STARSHIP_CONFIG = lib.mkForce "$HOME/.cache/starship/starship.toml";
    };

    home.shellAliases = {
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      "....." = "cd ../../../..";
      cat = "bat";
      cbuild = "clan machines build";
      clan-watch = "~/Clan/NFP/layers/00-cyberia/06-scripts/clan-update-watch.sh";
      cupdate = "clan machines update";
      cuw = "~/Clan/NFP/layers/00-cyberia/06-scripts/clan-update-watch.sh";
      diff = "delta";
      e = "hx";
      edit = "hx";
      f = "yazi";
      fm = "yazi";
      gg = "lazygit";
      GLaDOS = "nix-shell -p portaudio --run \"export LD_LIBRARY_PATH=\\\$(echo \\\$NIX_LDFLAGS | grep -oP '/nix/store/[^ ]+portaudio[^ ]+/lib' | head -n 1); cd ~/Projects/GlaDos/GLaDOS && uv run glados start --input-mode audio\"";
      htop = "btop";
      l = "eza -lh";
      ll = "eza -lah";
      ls = "eza";
      myip = "curl ifconfig.me";
      nfc = "nix flake check";
      nfp = "clan";
      nfpg = "clan vars generate";
      nfps = "clan secrets";
      nfu = "nix flake update";
      nrepl = "nix repl --option experimental-features \"flakes pipe-operators\" --expr \"rec { pkgs = import <nixpkgs>{}; lib = pkgs.lib; }\"";
      nrs = "sudo nixos-rebuild switch --flake ~/Clan/NFP";
      nrt = "sudo nixos-rebuild test --flake ~/Clan/NFP";
      nfpun = "clan machines update nami";
      nfpuz = "clan machines update z0r0";
      nfpul = "clan machines update luffy";
      nfpu = "clan machines update";
      # NH shortcuts
      nos = "nh os switch";
      nob = "nh os boot";
      not = "nh os test";
      noc = "nh clean all";
      # Nom shortcuts
      nb = "nom build";
      ndev = "nom develop";
      # Nix helpers
      ndiff = "nvd diff /run/current-system result";
      ntree = "nix-tree";
      mvi = "mpv --config-dir=$HOME/.config/mvi";
      ports = "ss -tulanp";
      ps = "procs";
      serve = "miniserve";
      set-ai = "uv run python ~/.local/bin/set-ai";
      sysaudit = "sysaudit";
      sysinfo = "fastfetch";
      top = "btop";
      tree = "eza --tree";
      v = "hx";
      vi = "hx";
      vim = "nvim";
      weather = "curl wttr.in";
      # sex = "xxh root@93.188.162.110";
      zshh = "xxh root@";
      # vpsu = "ssh t0psh31f@93.188.162.110 '. /etc/profile.d/nix.sh && cd ~/Clan/NFP && git pull && nix run home-manager -- switch --flake .#t0psh31f@vps'";
    };

    programs.zsh.initContent = lib.mkIf cfg.shells.zsh.enable ''
      proj() { local project_dir="$HOME/projects"; if [[ -d "$project_dir" ]]; then cd "$project_dir/$1" 2>/dev/null || cd "$project_dir"; fi; }
      clandir() { local clan_dir="$HOME/Clan"; if [[ -d "$clan_dir" ]]; then cd "$clan_dir/$1" 2>/dev/null || cd "$clan_dir"; fi; }
      ns() { nix-search-tv print | fzf --preview 'nix-search-tv preview {}' --scheme history; }
      sshks() { ssh-keyscan -t ed25519 192.168.1.0/24 >> ~/.ssh/known_hosts; }
    '';
  };
}
