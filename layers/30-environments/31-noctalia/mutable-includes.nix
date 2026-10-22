# Mutable Includes — Base app configs that source Noctalia-generated colors
#
# Pattern: Each app's "base" config is deployed by Home Manager as an
# immutable symlink to /nix/store, BUT it includes/sources a *mutable*
# file from a runtime-writable path (~/.config/noctalia/templates/).
# This avoids read-only conflicts while keeping configs declarative.
#
# For apps where Noctalia's built-in templates already handle the color
# file generation, we only need to wire up the source/include directive.
{
  osConfig ? config,
  config,
  lib,
  ...
}:
let
  cfg = osConfig.layers.layer-40.desktop.noctalia;
in
{
  config = lib.mkIf cfg.enable {

    # ── Hyprland Experience Includes ─────────────────────────────
    xdg.configFile."hypr/experiences/noctalia-hyprland.conf".text = ''
      # Noctalia Hyprland Experience Includes
      source = ${config.home.homeDirectory}/.config/hypr/noctalia.conf
      source = ${config.home.homeDirectory}/.config/hypr/hyprtoolkit.conf
      source = ${config.home.homeDirectory}/.cache/noctalia/HVE/overlay.conf
    '';
    xdg.configFile."hypr/experiences/active-experience.conf".text = ''
      # Active Desktop Experience (Noctalia Hyprland)
      source = ${config.home.homeDirectory}/.config/hypr/experiences/noctalia-hyprland.conf
    '';
    xdg.configFile."hypr/vibrancy.frag".source = ../../../layers/00-cyberia/02-assets/vibrancy.frag;

    # ── Kitty ──────────────────────────────────────────────────────────
    # Noctalia's built-in kitty template generates to:
    #   ~/.config/kitty/themes/noctalia.conf (and symlinks to current-theme.conf)
    # We set Kitty to include the current theme file
    xdg.configFile."kitty/kitty.conf" = {
      text = ''
        # Kitty base config — managed by Home Manager
        # Dynamic colors are loaded from Noctalia's generated theme
        include current-theme.conf


        # Font
        font_family      JetBrainsMono Nerd Font
        bold_font         auto
        italic_font       auto
        bold_italic_font  auto
        font_size 14.0

        # Window
        window_padding_width 8
        background_opacity 0.92
        dynamic_background_opacity yes
        confirm_os_window_close 0

        # Cursor
        cursor_shape beam
        cursor_blink_interval 0.5

        # Performance
        repaint_delay 10
        input_delay 3
        sync_to_monitor yes

        # Bell
        enable_audio_bell yes
        visual_bell_duration 0.0

        # URLs
        url_style curly
        open_url_with default
        detect_urls yes
      '';
      force = true;
    };

    # ── GTK 3 ──────────────────────────────────────────────────────────
    # Noctalia's built-in gtk template generates gtk colors to:
    #   ~/.config/gtk-3.0/noctalia.css
    xdg.configFile."gtk-3.0/gtk.css" = {
      text = ''
        /* GTK3 base — import Noctalia-generated Material You colors */
        @import url("noctalia.css");
      '';
      force = true;
    };

    # ── GTK 4 ──────────────────────────────────────────────────────────
    xdg.configFile."gtk-4.0/gtk.css" = {
      text = ''
        /* GTK4 base — import Noctalia-generated Material You colors */
        @import url("noctalia.css");
      '';
      force = true;
    };

    # ── Ghostty ────────────────────────────────────────────────────────
    # Noctalia's built-in ghostty template generates to:
    #   ~/.config/ghostty/themes/noctalia
    # We set the config to use the noctalia theme name
    xdg.configFile."ghostty/config" = {
      text = ''
        # Ghostty base config — managed by Home Manager
        # Dynamic theme loaded from Noctalia
        theme = noctalia


        font-family = JetBrainsMono Nerd Font
        font-size = 16
        background-opacity = 0.92
        window-padding-x = 8
        window-padding-y = 8
        confirm-close-surface = false
        cursor-style = bar
        cursor-style-blink = true
        mouse-hide-while-typing = true
        copy-on-select = clipboard
        window-decoration = false
        gtk-titlebar = false
      '';
      force = true;
    };

    # ── Rofi ───────────────────────────────────────────────────────────
    # Our custom user-template generates rofi-colors.rasi
    xdg.configFile."rofi/config.rasi" = {
      text = ''
        /* Rofi base config — import Noctalia-generated Material You colors */

        * {
            // Fallback dark neon palette (used if rofi-colors.rasi missing)
            bg:    #0f0f1a;
            bg-alt:#1a1a2e;
            fg:    #e0e0ff;
            fg-alt:#a0a0c0;
            accent:#00d4ff;
            selected: #ff6ec7;
            on-selected: #0f0f1a;
            glow: #aa00ff;
        }

        @import "noctalia.rasi"

        configuration {
          modi: "drun,run,window,ssh";
          show-icons: true;
          icon-theme: "Papirus-Dark";
          display-drun: "Launch";
          drun-display-format: "{name}";
          font: "JetBrainsMono Nerd Font 14";
        }

        window {
          width: 45%;
          border: 2px;
          border-color: @accent;
          border-radius: 16px;
          background-color: @bg;
          /* Subtle neon glow via box-shadow (client-side decoration) */
          // drop-shadow: 0 0 24px rgba(0, 212, 255, 0.15);
        }

        mainbox {
          background-color: transparent;
          padding: 8px;
        }

        inputbar {
          background-color: @bg-alt;
          text-color: @fg;
          border-radius: 10px;
          padding: 14px;
          margin: 10px;
          border: 1px;
          border-color: @accent;
        }

        listview {
          background-color: transparent;
          columns: 1;
          lines: 8;
          spacing: 6px;
          padding: 10px;
        }

        element {
          background-color: transparent;
          text-color: @fg-alt;
          padding: 12px;
          border-radius: 8px;
        }

        element selected {
          background-color: @selected;
          text-color: @on-selected;
          /* Neon glow on selected item */
          border: 1px;
          border-color: @glow;
        }

        element-icon {
          size: 0.8em;
        }

        element-text {
          font: "JetBrainsMono Nerd Font 14";
          vertical-align: 0.5;
        }
      '';
      force = true;
    };

    # ── Zellij ─────────────────────────────────────────────────────────
    # Zellij config is managed by layers/50-cli-tui-programs/54-multiplexers/zellij.nix
    # Noctalia's built-in zellij template generates zellij-colors.kdl for theme colors.
    # The main config.kdl is NOT overridden here — zellij.nix owns it.

    # Zellij Layout -> Master (Left terminal, Right 2x SSH windows)
    xdg.configFile."zellij/layouts/default.kdl" = {
      text = ''
        layout {
            default_tab_template {
                pane size=1 borderless=true {
                    plugin location="zellij:tab-bar"
                }
                children
                pane size=2 borderless=true {
                    plugin location="zellij:status-bar"
                }
            }
            tab name="Master" {
                pane split_direction="vertical" {
                    pane size="65%"
                    pane split_direction="horizontal" {
                        pane command="ssh" {
                            args "nami"
                        }
                        // pane command="ssh" {
                        //     args "luffy"
                        // }
                    }
                }
            }
        }
      '';
      force = true;
    };

    # ── Zathura ────────────────────────────────────────────────────────
    # Noctalia's built-in zathura template overwrites zathurarc directly
    # No include mechanism needed — Noctalia manages it

    # ── Helix ──────────────────────────────────────────────────────────
    # Noctalia's built-in helix template generates to helix themes dir (~/.config/helix/themes/noctalia.toml)
    # We just need to set the theme name in config.toml
    xdg.configFile."helix/config.toml" = {
      text = ''
        theme = "noctalia"

        [editor]
        line-number = "relative"
        cursorline = true
        auto-save = true
        true-color = true
        color-modes = true
        bufferline = "multiple"
        cursor-shape.insert = "bar"
        cursor-shape.normal = "block"

        [editor.statusline]
        left = ["mode", "spinner", "file-name", "read-only-indicator", "file-modification-indicator"]
        right = ["diagnostics", "selections", "register", "position", "file-encoding", "file-line-ending"]

        [editor.indent-guides]
        render = true
        character = "▏"

        [editor.soft-wrap]
        enable = true
      '';
      force = true;
    };

    # ── Vesktop / Vencord ──────────────────────────────────────────────
    # Our custom user-template generates vesktop-vencord.css
    # Vesktop reads themes from its themes directory
    xdg.configFile."vesktop/themes/.gitkeep".text = "";

    # ── Neovim ─────────────────────────────────────────────────────────
    # Our custom user-template generates nvim-colors.vim
    xdg.configFile."nvim/colors/.gitkeep".text = "";

    # ── SwayNC ─────────────────────────────────────────────────────────
    # Our custom user-template generates swaync-colors.css
    xdg.configFile."swaync/style.css" = {
      text = ''
        /* SwayNC base style — import Noctalia-generated colors */
        @import "~/.config/noctalia/templates/swaync-colors.css";
      '';
      force = true;
    };

    # ── Gedit ──────────────────────────────────────────────────────────
    # Our custom user-template generates gedit-matugen.xml sourceview style
    # Gedit reads styles from ~/.local/share/gedit/styles/

    # ── Zsh color sourcing ─────────────────────────────────────────────
    # Our custom user-template generates zsh-colors.sh
    # Users can source this in their .zshrc:
    # [ -f ~/.config/noctalia/templates/zsh-colors.sh ] && source ~/.config/noctalia/templates/zsh-colors.sh
  };
}
