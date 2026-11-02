{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.layers.layer-50.cli;
  nixvimEnabled = config.layers.layer-50.cli.nixvim.enable or false;
  editorBin = if nixvimEnabled then "nvim" else "${lib.getExe pkgs.neovim}";
in
{
  home = lib.mkIf cfg.enable {
    programs.yazi = {
      enable = true;
      shellWrapperName = "y";
      enableZshIntegration = true;
      extraPackages = with pkgs; [
        glow
        mediainfo
        ouch
        ripdrag
        rsync
        sshfs
        starship
        trash-cli
        udisks
        wl-clipboard
      ];
      initLua = ''
        require("full-border"):setup()
        require("git"):setup()
        require("starship"):setup()
        require("bookmarks"):setup({
          last_directory = { enable = true, persist = true },
          persist = "all",
          desc_format = "full",
          file_pick_mode = "hover",
          notify = {
            enable = true,
            timeout = 1,
            message = {
              new = "New bookmark '<key>' -> '<folder>'",
              delete = "Deleted bookmark in '<key>'",
              delete_all = "Deleted all bookmarks",
            },
          },
        })
        require("sshfs"):setup()
        require("gvfs"):setup({
          save_password_autoconfirm = true,
        })
      '';
      plugins = with pkgs.yaziPlugins; {
        inherit
          bookmarks
          bypass
          chmod
          compress
          diff
          drag
          dupes
          full-border
          git
          gitui
          glow
          gvfs
          jump-to-char
          lazygit
          mediainfo
          mime-ext
          mount
          ouch
          piper
          projects
          recycle-bin
          relative-motions
          restore
          rich-preview
          rsync
          smart-enter
          smart-filter
          smart-paste
          sshfs
          starship
          sudo
          time-travel
          toggle-pane
          vcs-files
          wl-clipboard
          yafg
          yatline
          yatline-githead
          zoom
          ;
      };
      settings = {
        mgr = {
          show_hidden = true;
          sort_by = "natural";
          sort_dir_first = true;
          show_symlink = true;
          linemode = "size";
        };
        manager = {
          show_hidden = true;
          sort_by = "natural";
          sort_dir_first = true;
          show_symlink = true;
          linemode = "size";
        };
        plugin = {
          prepend_fetchers = [
            {
              id = "git";
              url = "*";
              run = "git";
            }
            {
              id = "git";
              url = "*/";
              run = "git";
            }
          ];
          prepend_previewers = [
            {
              name = "*.md";
              run = "glow";
            }
            {
              mime = "application/*zip";
              run = "ouch";
            }
            {
              mime = "application/x-tar";
              run = "ouch";
            }
            {
              mime = "application/x-bzip2";
              run = "ouch";
            }
            {
              mime = "application/x-7z-compressed";
              run = "ouch";
            }
            {
              mime = "application/x-rar";
              run = "ouch";
            }
            {
              mime = "application/x-xz";
              run = "ouch";
            }
            {
              mime = "{audio,video,image}/*";
              run = "mediainfo";
            }
          ];
        };
        opener = {
          edit = [
            {
              run = ''${editorBin} "$@"'';
              block = true;
              desc = "Neovim";
            }
          ];
          helix = [
            {
              run = ''hx "$@"'';
              block = true;
              desc = "Helix";
            }
          ];
        };
        open = {
          rules = [
            {
              name = "*/";
              use = [
                "edit"
                "helix"
                "open"
                "reveal"
              ];
            }
            {
              mime = "text/*";
              use = [
                "edit"
                "helix"
                "reveal"
              ];
            }
            {
              mime = "application/json";
              use = [
                "edit"
                "helix"
                "reveal"
              ];
            }
            {
              mime = "application/javascript";
              use = [
                "edit"
                "helix"
                "reveal"
              ];
            }
            {
              mime = "application/x-sh";
              use = [
                "edit"
                "helix"
                "reveal"
              ];
            }
            {
              mime = "*";
              use = [
                "edit"
                "helix"
                "open"
                "reveal"
              ];
            }
          ];
        };
      };
      keymap.mgr.prepend_keymap = [
        # Smart navigation & paste
        {
          on = [ "l" ];
          run = "plugin smart-enter";
          desc = "Enter directory or open file";
        }
        {
          on = [ "p" ];
          run = "plugin smart-paste";
          desc = "Paste into hovered directory or CWD";
        }
        {
          on = [ "F" ];
          run = "plugin smart-filter";
          desc = "Smart live filter";
        }
        {
          on = [ "f" ];
          run = "plugin jump-to-char";
          desc = "Jump to char (vim f<char>)";
        }
        {
          on = [ "T" ];
          run = "plugin toggle-pane max-preview";
          desc = "Maximize or restore preview pane";
        }
        {
          on = [ "<C-d>" ];
          run = "plugin drag";
          desc = "Drag & drop selected files (ripdrag)";
        }

        # Mounted Drives, Network Shares & Fleet Nodes (g + key)
        {
          on = [
            "g"
            "n"
          ];
          run = "cd /mnt/nas";
          desc = "Go to Buffalo NAS (/mnt/nas)";
        }
        {
          on = [
            "g"
            "g"
          ];
          run = "cd ~/GoogleDrive";
          desc = "Go to Google Drive (~/GoogleDrive)";
        }
        {
          on = [
            "g"
            "m"
          ];
          run = "cd /run/media/t0psh31f";
          desc = "Go to removable USB/Media drives";
        }
        {
          on = [
            "g"
            "p"
          ];
          run = "cd /persist";
          desc = "Go to /persist Btrfs volume";
        }
        {
          on = [
            "g"
            "f"
          ];
          run = "cd ~/Clan/NFP";
          desc = "Go to NFP Flake (~/Clan/NFP)";
        }
        {
          on = [
            "g"
            "j"
          ];
          run = "cd ~/Clan/Jarvis";
          desc = "Go to Jarvis Flake (~/Clan/Jarvis)";
        }
        {
          on = [
            "g"
            "v"
          ];
          run = "plugin gvfs -- jump-to-device --automount";
          desc = "Jump to GVFS network/MTP device";
        }

        # Mount Manager, SSHFS & GVFS (M + key)
        {
          on = [
            "M"
            "m"
          ];
          run = "plugin mount";
          desc = "Open disk/partition Mount Manager (udisksctl)";
        }
        {
          on = [
            "M"
            "s"
          ];
          run = "plugin sshfs -- menu";
          desc = "Open SSHFS remote fleet mount menu (z0r0/luffy)";
        }
        {
          on = [
            "M"
            "g"
          ];
          run = "plugin gvfs -- select-then-mount --jump";
          desc = "Mount & jump to GVFS device (SMB/MTP/SFTP)";
        }
        {
          on = [
            "M"
            "u"
          ];
          run = "plugin gvfs -- select-then-unmount";
          desc = "Unmount GVFS device";
        }
        {
          on = [
            "M"
            "a"
          ];
          run = "plugin gvfs -- add-mount";
          desc = "Add GVFS network URI (smb://, sftp://)";
        }

        # Editor & Archive / File Operations
        {
          on = [ "e" ];
          run = "open --interactive";
          desc = "Open with editor";
        }
        {
          on = [ "E" ];
          run = "open --hovered --interactive";
          desc = "Choose opener interactively";
        }
        {
          on = [ "<C-s>" ];
          run = "escape";
          desc = "Exit yazi";
        }
        {
          on = [
            "b"
            "a"
          ];
          run = "plugin bookmarks save";
          desc = "Add bookmark";
        }
        {
          on = [
            "b"
            "g"
          ];
          run = "plugin bookmarks jump";
          desc = "Jump to bookmark";
        }
        {
          on = [
            "b"
            "d"
          ];
          run = "plugin bookmarks delete";
          desc = "Delete bookmark";
        }
        {
          on = [ "C" ];
          run = "plugin ouch";
          desc = "Compress selected files (ouch)";
        }
        {
          on = [ "D" ];
          run = "plugin diff";
          desc = "Diff selected files";
        }
        {
          on = [
            "c"
            "m"
          ];
          run = "plugin chmod";
          desc = "Change file permissions";
        }
        {
          on = [
            "g"
            "u"
          ];
          run = "plugin gitui";
          desc = "Open GitUI";
        }
        {
          on = [
            "g"
            "l"
          ];
          run = "plugin lazygit";
          desc = "Open Lazygit";
        }
        {
          on = [
            "g"
            "s"
          ];
          run = "plugin vcs-files";
          desc = "Show changed Git files";
        }
        {
          on = [
            "d"
            "t"
          ];
          run = "plugin recycle-bin delete";
          desc = "Move to recycle bin";
        }
        {
          on = [
            "d"
            "r"
          ];
          run = "plugin recycle-bin restore";
          desc = "Restore from recycle bin";
        }
        {
          on = [
            "y"
            "c"
          ];
          run = "plugin wl-clipboard";
          desc = "Copy to Wayland clipboard";
        }
      ];
    };
  };
}
