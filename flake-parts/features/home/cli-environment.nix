# flake-parts/features/home/cli-environment.nix
# Comprehensive CLI/TUI environment - portable terminal workspace
# Replaces yazelix with self-contained Helix + Yazi + Zellij integration
{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:

let
  cfg = config.programs.cli-environment;
  clanTags = osConfig.clan.core.tags or [ ];
in
{
  options.programs.cli-environment = {
    enable = lib.mkEnableOption "Complete CLI/TUI development environment";

    enableYazelix = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Helix + Yazi + Zellij integration (yazelix-style)";
    };

    enableExtraTools = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable extended CLI toolset (monitoring, network tools, etc.)";
    };
  };

  config = lib.mkIf cfg.enable {

    # =========================================================================
    # CORE EDITOR - HELIX
    # =========================================================================
    programs.helix = {
      enable = true;
      defaultEditor = true;

      settings = {
        theme = "catppuccin_mocha";

        editor = {
          line-number = "relative";
          mouse = false;
          cursorline = true;
          cursorcolumn = false;
          auto-save = true;
          completion-trigger-len = 1;
          true-color = true;
          rulers = [
            80
            120
          ];
          color-modes = true;

          cursor-shape = {
            insert = "bar";
            normal = "block";
            select = "underline";
          };

          file-picker = {
            hidden = false;
            git-ignore = true;
          };

          lsp = {
            display-messages = true;
            display-inlay-hints = true;
          };

          statusline = {
            left = [
              "mode"
              "spinner"
              "file-name"
              "file-modification-indicator"
            ];
            center = [ "diagnostics" ];
            right = [
              "selections"
              "position"
              "file-encoding"
              "file-line-ending"
              "file-type"
            ];
          };

          indent-guides = {
            render = true;
            character = "┊";
          };
        };

        keys.normal = {
          # Yazi integration - open file manager
          space.e = ":sh yazi";

          # Quick save
          C-s = ":w";

          # Quick quit
          C-q = ":q";

          # Buffer navigation
          H = ":bp";
          L = ":bn";

          # Zellij pane navigation (if in zellij)
          A-h = ":sh zellij action move-focus left";
          A-j = ":sh zellij action move-focus down";
          A-k = ":sh zellij action move-focus up";
          A-l = ":sh zellij action move-focus right";
        };

        keys.insert = {
          # Quick escape alternatives
          j.k = "normal_mode";
          k.j = "normal_mode";
        };
      };

      # Language servers
      languages = {
        language = [
          {
            name = "nix";
            auto-format = true;
            formatter.command = "${pkgs.nixfmt-rfc-style}/bin/nixfmt";
          }
          {
            name = "python";
            auto-format = true;
            language-servers = [ "pylsp" ];
          }
          {
            name = "rust";
            auto-format = true;
          }
          {
            name = "go";
            auto-format = true;
          }
          {
            name = "javascript";
            auto-format = true;
          }
          {
            name = "typescript";
            auto-format = true;
          }
          {
            name = "json";
            auto-format = true;
          }
          {
            name = "yaml";
            auto-format = true;
          }
          {
            name = "toml";
            auto-format = true;
          }
          {
            name = "markdown";
            auto-format = true;
          }
        ];
      };
    };

    # =========================================================================
    # FILE MANAGER - YAZI
    # =========================================================================
    programs.yazi = {
      enable = true;

      settings = {
        manager = {
          show_hidden = true;
          show_symlink = true;
          sort_by = "natural";
          sort_dir_first = true;
          linemode = "size";
        };

        preview = {
          image_filter = "lanczos3";
          image_quality = 90;
          tab_size = 2;
          max_width = 600;
          max_height = 900;
        };

        opener = {
          edit = [
            {
              run = ''${pkgs.helix}/bin/hx "$@"'';
              block = true;
            }
          ];
          open = [ { run = ''xdg-open "$@"''; } ];
        };
      };

      keymap = {
        manager.prepend_keymap = [
          {
            on = [ "e" ];
            run = "open";
            desc = "Open with Helix";
          }
          {
            on = [ "E" ];
            run = "open --interactive";
            desc = "Open with...";
          }
          {
            on = [ "<C-s>" ];
            run = "escape";
            desc = "Exit yazi";
          }
        ];
      };
    };

    # =========================================================================
    # TERMINAL MULTIPLEXER - ZELLIJ
    # =========================================================================
    programs.zellij = {
      enable = lib.mkIf cfg.enableYazelix true;

      settings = {
        theme = "catppuccin-mocha";
        default_shell = "${pkgs.zsh}/bin/zsh";
        pane_frames = true;
        simplified_ui = false;
        default_layout = "compact";

        keybinds = {
          normal = {
            # Unbind Ctrl+q (conflicts with Helix)
            "bind \"Ctrl q\"" = {
              Quit = { };
            };
          };

          pane = {
            # Vim-style pane navigation
            "bind \"h\"" = {
              MoveFocus = "Left";
            };
            "bind \"j\"" = {
              MoveFocus = "Down";
            };
            "bind \"k\"" = {
              MoveFocus = "Up";
            };
            "bind \"l\"" = {
              MoveFocus = "Right";
            };
          };
        };
      };
    };

    # =========================================================================
    # ENHANCED ZSH CONFIGURATION
    # =========================================================================
    programs.zsh = {
      initExtra = ''
        # Quick project navigation
        proj() {
          local project_dir="${config.home.homeDirectory}/projects"
          if [[ -d "$project_dir" ]]; then
            cd "$project_dir/$1" 2>/dev/null || cd "$project_dir"
          fi
        }

        clan() {
          local clan_dir="${config.home.homeDirectory}/Clan"
          if [[ -d "$clan_dir" ]]; then
            cd "$clan_dir/$1" 2>/dev/null || cd "$clan_dir"
          fi
        }

        # Git worktree shortcut
        gwt() {
          if [[ -z "$1" ]]; then
            git worktree list
          else
            git worktree add "../$1" "$1"
          fi
        }

        # Nix development shortcuts
        nd() { nix develop "$@"; }
        nb() { nix build "$@"; }
        nf() { nix flake "$@"; }

        # Quick system rebuild
        rebuild() {
          local hostname=$(hostname)
          sudo nixos-rebuild switch --flake ~/Clan/Grandlix-Gang#$hostname "$@"
        }

        # Start yazelix-style environment
        yazelix() {
          if command -v zellij &> /dev/null; then
            zellij --layout compact
          else
            echo "Zellij not available, starting helix directly"
            hx "$@"
          fi
        }

        # fzf-powered directory navigation
        fzf-cd() {
          local dir
          dir=$(fd --type d --hidden --exclude .git | fzf --preview 'eza --tree --level=1 --icons {}')
          if [[ -n "$dir" ]]; then
            cd "$dir"
            zle reset-prompt
          fi
        }
        zle -N fzf-cd
        bindkey '^F' fzf-cd

        # fzf-powered file opening in helix
        fzf-edit() {
          local file
          file=$(fd --type f --hidden --exclude .git | fzf --preview 'bat --color=always {}')
          if [[ -n "$file" ]]; then
            hx "$file"
          fi
        }
        zle -N fzf-edit
        bindkey '^E' fzf-edit
      '';

      # Enhanced shell aliases
      shellAliases = {
        # ======= Editor & File Management =======
        e = "hx";
        edit = "hx";
        v = "hx"; # vim muscle memory
        vim = "hx";
        f = "yazi";
        fm = "yazi";

        # ======= Directory Navigation =======
        ".." = "cd ..";
        "..." = "cd ../..";
        "...." = "cd ../../..";
        dl = "cd ~/Downloads";
        docs = "cd ~/Documents";
        proj = "cd ~/projects";
        clan = "cd ~/Clan/Grandlix-Gang";

        # ======= Git Shortcuts =======
        g = "git";
        gs = "git status";
        ga = "git add";
        gaa = "git add --all";
        gc = "git commit";
        gcm = "git commit -m";
        gp = "git push";
        gpl = "git pull";
        gd = "git diff";
        gco = "git checkout";
        gb = "git branch";
        gl = "git log --oneline --graph --decorate";
        glog = "git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";

        # ======= Nix Shortcuts =======
        nrs = "sudo nixos-rebuild switch --flake ~/Clan/Grandlix-Gang";
        nrt = "sudo nixos-rebuild test --flake ~/Clan/Grandlix-Gang";
        nrb = "sudo nixos-rebuild boot --flake ~/Clan/Grandlix-Gang";
        nfc = "nix flake check";
        nfu = "nix flake update";
        nfl = "nix flake lock";
        nfs = "nix flake show";

        # Clan machine management
        cbuild = "clan machines build";
        cupdate = "clan machines update";
        cflash = "clan machines install";

        # Garbage collection
        ngc = "sudo nix-collect-garbage -d";
        "ngc-old" = "sudo nix-collect-garbage --delete-older-than 7d";

        # ======= System Monitoring =======
        htop = "btop";
        top = "btop";

        # ======= Misc Utilities =======
        weather = "curl wttr.in";
        myip = "curl ifconfig.me";
        ports = "ss -tulanp";
        ezsh = "hx ~/.zshrc";
        eflake = "hx ~/Clan/Grandlix-Gang/flake.nix";
        sysinfo = "fastfetch";
      };
    };

    # =========================================================================
    # CLI TOOLS - Essential utilities
    # =========================================================================
    home.packages =
      with pkgs;
      [
        # === Core Yazelix Trio ===
        helix
        yazi
      ]
      ++ lib.optionals cfg.enableYazelix [ zellij ]
      ++ [
        # === Modern CLI Replacements ===
        ripgrep # grep replacement
        fd # find replacement
        zoxide # cd replacement (smart)
        fzf # fuzzy finder
        dust # du replacement
        duf # df replacement
        procs # ps replacement
        gping # ping with graph
        bottom # btop/htop alternative
        btop # resource monitor

        # === File Management ===
        tree # directory tree
        ranger # TUI file manager (backup)
        lf # Terminal file manager
        nnn # Minimalist file manager

        # === Git Tools ===
        gitui # TUI for git
        lazygit # Another TUI for git
        gh # GitHub CLI
        git-crypt # Transparent file encryption
        delta # Better git diffs

        # === File Operations ===
        rsync # File sync
        rclone # Cloud sync

        # === Archive Tools ===
        unzip
        zip
        p7zip
        unrar
        gnutar

        # === Network Tools ===
        curl
        wget
        httpie # HTTP client
        aria2 # Download manager

        # === System Info ===
        fastfetch # System info
        neofetch # System info (classic)

        # === Text Processing ===
        jq # JSON processor
        yq-go # YAML processor
        sd # sed alternative

        # === Development ===
        direnv # Auto environment
        just # Command runner
        tokei # Code statistics
        hyperfine # Benchmarking

        # === Misc Utilities ===
        tealdeer # tldr client
        trash-cli # Safe rm
      ]
      ++ lib.optionals cfg.enableExtraTools [
        # === Extended Tools (optional) ===
        tmux # Terminal multiplexer (backup)

        # Network diagnostics
        nmap
        netcat
        socat

        # Monitoring
        iotop
        iftop
        nethogs

        # PDF tools
        poppler_utils # pdftotext, etc.

        # Image tools
        imagemagick

        # Video tools
        ffmpeg-full

        # Encryption
        age
        gnupg

        # Compression
        zstd
        lz4

        # System
        lsof
        pciutils
        usbutils
      ];

    # =========================================================================
    # ADDITIONAL PROGRAMS
    # =========================================================================

    # FZF configuration
    programs.fzf = {
      enable = true;
      enableZshIntegration = true;

      defaultCommand = "fd --type f --hidden --follow --exclude .git";
      defaultOptions = [
        "--height 40%"
        "--layout=reverse"
        "--border"
        "--inline-info"
      ];

      fileWidgetCommand = "fd --type f --hidden --follow --exclude .git";
      changeDirWidgetCommand = "fd --type d --hidden --follow --exclude .git";
    };

    # Zoxide (smart cd)
    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    # Git delta for better diffs
    programs.git = {
      enable = true;
      delta = {
        enable = true;
        options = {
          navigate = true;
          light = false;
          line-numbers = true;
          syntax-theme = "Catppuccin-mocha";
        };
      };
    };

    # =========================================================================
    # SESSION VARIABLES
    # =========================================================================
    home.sessionVariables = {
      EDITOR = "hx";
      VISUAL = "hx";
      PAGER = "bat";
      MANPAGER = "sh -c 'col -bx | bat -l man -p'";
    };
  };
}
