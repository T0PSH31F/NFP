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
      plugins = with pkgs.yaziPlugins; {
        inherit bookmarks;
        inherit chmod;
        inherit compress;
        inherit ouch;
        inherit rsync;
        inherit sudo;
        inherit diff;
        inherit drag;
        inherit dupes;
        inherit full-border;
        inherit gitui;
        inherit lazygit;
        inherit glow;
        inherit mediainfo;
        inherit mime-ext;
        inherit rich-preview;
        inherit piper;
        inherit gvfs;
        inherit recycle-bin;
        inherit vcs-files;
        inherit wl-clipboard;
        inherit yatline;
        inherit yatline-githead;
      };
      settings = {
        manager = {
          show_hidden = true;
          sort_by = "natural";
          sort_dir_first = true;
        };
        opener.edit = [
          {
            run = ''${editorBin} "$@"'';
            block = true;
          }
        ];
        keymap.manager.prepend_keymap = [
          {
            on = [ "e" ];
            run = "open";
            desc = "Open with Neovim";
          }
        ];
      };
      keymap.manager.prepend_keymap = [
        {
          on = [ "e" ];
          run = "open";
          desc = "Open with Neovim";
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
          run = "plugin compress";
          desc = "Compress selected files";
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
