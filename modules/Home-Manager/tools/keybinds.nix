{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.programs.keybind-cheatsheet;
in
{
  options.programs.keybind-cheatsheet = {
    enable = mkEnableOption "Keybind cheatsheet overlay";

    keybindDir = mkOption {
      type = types.path;
      default = "${config.home.homeDirectory}/.config/noctalia/keybinds";
      description = "Directory containing keybind JSON files";
    };

    tools = mkOption {
      type = types.listOf types.str;
      default = [ "helix" "tmux" "ghostty" "hyprland" ];
      description = "List of tools to include in cheatsheet";
    };
  };

  config = mkIf cfg.enable {
    # Create keybind data directory
    home.file = {
      ".config/noctalia/keybinds/helix.json".text = builtins.toJSON {
        name = "Helix";
        categories = {
          "Normal Mode" = {
            "i" = "Insert mode";
            "a" = "Append";
            "o" = "Open line below";
            "O" = "Open line above";
            "v" = "Visual mode";
            "V" = "Visual line mode";
            "Ctrl+v" = "Visual block mode";
            ":" = "Command mode";
            "/" = "Search";
            "n" = "Next search result";
            "N" = "Previous search result";
            "u" = "Undo";
            "U" = "Redo";
            "y" = "Yank (copy)";
            "p" = "Paste after";
            "P" = "Paste before";
            "d" = "Delete";
            "c" = "Change";
            "x" = "Delete character";
            "Space+f" = "File picker (Yazi)";
            "Space+F" = "File picker (vsplit)";
          };
          "Movement" = {
            "h/j/k/l" = "Left/Down/Up/Right";
            "w" = "Next word";
            "b" = "Previous word";
            "e" = "End of word";
            "0" = "Start of line";
            "$" = "End of line";
            "gg" = "Start of file";
            "G" = "End of file";
            "Ctrl+d" = "Page down";
            "Ctrl+u" = "Page up";
          };
          "LSP" = {
            "gd" = "Go to definition";
            "gr" = "Go to references";
            "K" = "Hover documentation";
            "Space+r" = "Rename";
            "Space+a" = "Code action";
          };
        };
      };

      ".config/noctalia/keybinds/tmux.json".text = builtins.toJSON {
        name = "Tmux";
        categories = {
          "Sessions" = {
            "Ctrl+b d" = "Detach session";
            "Ctrl+b $" = "Rename session";
            "Ctrl+b s" = "List sessions";
          };
          "Windows" = {
            "Ctrl+b c" = "Create window";
            "Ctrl+b ," = "Rename window";
            "Ctrl+b n" = "Next window";
            "Ctrl+b p" = "Previous window";
            "Ctrl+b 0-9" = "Switch to window";
            "Ctrl+b &" = "Kill window";
          };
          "Panes" = {
            "Ctrl+b %" = "Split vertically";
            "Ctrl+b \"" = "Split horizontally";
            "Ctrl+b o" = "Next pane";
            "Ctrl+b ;" = "Last pane";
            "Ctrl+b x" = "Kill pane";
            "Ctrl+b z" = "Toggle zoom";
            "Ctrl+b {" = "Move pane left";
            "Ctrl+b }" = "Move pane right";
          };
        };
      };

      ".config/noctalia/keybinds/ghostty.json".text = builtins.toJSON {
        name = "Ghostty";
        categories = {
          "Terminal" = {
            "Ctrl+Shift+c" = "Copy";
            "Ctrl+Shift+v" = "Paste";
            "Ctrl+Shift+t" = "New tab";
            "Ctrl+Shift+w" = "Close tab";
            "Ctrl+Tab" = "Next tab";
            "Ctrl+Shift+Tab" = "Previous tab";
            "Ctrl+Shift+n" = "New window";
            "Ctrl+Shift+q" = "Quit";
          };
          "Zoom" = {
            "Ctrl+=" = "Zoom in";
            "Ctrl+-" = "Zoom out";
            "Ctrl+0" = "Reset zoom";
          };
          "Search" = {
            "Ctrl+Shift+f" = "Find";
            "Ctrl+Shift+g" = "Find next";
            "Ctrl+Shift+h" = "Find previous";
          };
        };
      };

      ".config/noctalia/keybinds/hyprland.json".text = builtins.toJSON {
        name = "Hyprland (Noctalia)";
        categories = {
          "Applications" = {
            "Super+Return" = "Terminal (Ghostty)";
            "Super+Shift+Return" = "Terminal (Warp)";
            "Super+W" = "Browser (Brave)";
            "Super+Ctrl+W" = "Browser (Librewolf)";
            "Super+Shift+W" = "Browser (Mullvad)";
            "Super+Alt+W" = "Browser (Dillo+)";
            "Super+E" = "File Manager";
            "Super+C" = "VSCode";
            "Super+M" = "Music (Spotify)";
          };
          "Window Management" = {
            "Super+Q" = "Close window";
            "Super+B" = "Fullscreen";
            "Super+Shift+B" = "Maximize";
            "Super+Arrow" = "Move focus";
            "Super+Shift+Arrow" = "Move window";
          };
          "Workspaces" = {
            "Super+1-9" = "Switch workspace";
            "Super+Shift+1-9" = "Move to workspace";
            "Super+Ctrl+Left/Right" = "Previous/Next workspace";
            "Super+Mouse Wheel" = "Scroll workspaces";
          };
          "Noctalia" = {
            "Super+Space" = "Overview";
            "Super+Alt+Space" = "Spotlight";
            "Super+V" = "Clipboard";
            "Super+N" = "Notifications";
            "Super+Y" = "Wallpaper";
            "Super+Alt+L" = "Lock screen";
          };
          "Media" = {
            "XF86AudioRaiseVolume" = "Volume up";
            "XF86AudioLowerVolume" = "Volume down";
            "XF86AudioMute" = "Mute";
            "XF86MonBrightnessUp" = "Brightness up";
            "XF86MonBrightnessDown" = "Brightness down";
          };
        };
      };
    };

    # Keybind cheatsheet viewer script
    home.packages = with pkgs; [
      (writeShellScriptBin "keybind-cheatsheet" ''
        #!/usr/bin/env bash
        # Keybind cheatsheet overlay using rofi
        
        KEYBIND_DIR="${cfg.keybindDir}"
        TOOLS=(${concatStringsSep " " cfg.tools})
        CURRENT_INDEX=0
        
        show_keybinds() {
          local tool="$1"
          local json_file="$KEYBIND_DIR/$tool.json"
          
          if [ ! -f "$json_file" ]; then
            echo "Keybind file not found: $json_file"
            return 1
          fi
          
          # Parse JSON and format for rofi
          ${pkgs.jq}/bin/jq -r '
            .name as $name |
            .categories | to_entries[] |
            "=== " + .key + " ===" as $header |
            ($header, (.value | to_entries[] | .key + " → " + .value))
          ' "$json_file" | ${pkgs.rofi}/bin/rofi -dmenu \
            -p "Keybinds: $tool (←/→ to switch)" \
            -mesg "Use arrow keys to switch between tools" \
            -theme-str 'window {width: 800px; height: 600px;}' \
            -theme-str 'listview {lines: 20;}'
        }
        
        # Show keybinds for the first tool
        show_keybinds "''${TOOLS[0]}"
      '')

      # Alternative gum-based viewer
      (writeShellScriptBin "keybind-cheatsheet-gum" ''
        #!/usr/bin/env bash
        # Keybind cheatsheet using gum
        
        KEYBIND_DIR="${cfg.keybindDir}"
        
        # Select tool
        TOOL=$(${pkgs.gum}/bin/gum choose ${concatStringsSep " " cfg.tools})
        
        if [ -z "$TOOL" ]; then
          exit 0
        fi
        
        JSON_FILE="$KEYBIND_DIR/$TOOL.json"
        
        if [ ! -f "$JSON_FILE" ]; then
          ${pkgs.gum}/bin/gum style --foreground 196 "Keybind file not found: $JSON_FILE"
          exit 1
        fi
        
        # Display keybinds
        ${pkgs.gum}/bin/gum style --border double --padding "1 2" --border-foreground 212 "Keybinds: $TOOL"
        echo ""
        
        ${pkgs.jq}/bin/jq -r '
          .categories | to_entries[] |
          "### " + .key + "\n" +
          (.value | to_entries[] | "  " + .key + " → " + .value) + "\n"
        ' "$JSON_FILE" | ${pkgs.gum}/bin/gum format
      '')
    ];

    # Hyprland keybind to toggle cheatsheet
    wayland.windowManager.hyprland.settings.bind = mkAfter [
      "SUPER, B, exec, keybind-cheatsheet"
    ];
  };
}
