# 🗺️ Central Declarative Keymap & Action Registry (NFP)
# Unified action definitions for Hyprland, Niri, wlr-which-key, and Rofi cheat sheets.
{ lib }:
let
  mkAction =
    {
      chord,
      action,
      desc,
      category,
      cmd ? null,
      source ? "action-registry.nix",
      scope ? "local",
      noctaliaOnly ? false,
    }:
    {
      inherit
        chord
        action
        desc
        category
        cmd
        source
        scope
        noctaliaOnly
        ;
    };
in
{
  # ── Direct Root Chords ─────────────────────────────────────────────
  rootChords = [
    (mkAction {
      chord = "Super+Space";
      action = "vicinae-launcher";
      desc = "Vicinae application launcher";
      category = "launchers";
      cmd = "vicinae toggle";
    })
    (mkAction {
      chord = "Super+/";
      action = "rofi-cheatsheet";
      desc = "Rofi alphabetical cheat sheet index";
      category = "launchers";
      cmd = "cheatsheet";
    })
    (mkAction {
      chord = "Super+Enter";
      action = "which-key-root";
      desc = "wlr-which-key all-map index";
      category = "launchers";
      cmd = "wlr-which-key";
    })
    (mkAction {
      chord = "Super+T";
      action = "launch-ghostty";
      desc = "Launch Ghostty terminal";
      category = "terminal";
      cmd = "uwsm app -- ghostty";
    })
    (mkAction {
      chord = "Super+Shift+T";
      action = "launch-kitty";
      desc = "Launch Kitty terminal";
      category = "terminal";
      cmd = "uwsm app -- kitty";
    })
    (mkAction {
      chord = "Super+Shift+A";
      action = "agents-root";
      desc = "Open Agents map root";
      category = "agents";
      cmd = "wlr-which-key agents";
    })
    (mkAction {
      chord = "Alt+T";
      action = "toggle-scratchpad-term";
      desc = "Toggle top Ghostty dropdown terminal";
      category = "scratchpad";
      cmd = "pypr toggle term";
    })
    (mkAction {
      chord = "Alt+N";
      action = "toggle-scratchpad-gedit";
      desc = "Toggle right Gedit notepad panel";
      category = "scratchpad";
      cmd = "pypr toggle gedit";
    })
    (mkAction {
      chord = "Alt+G";
      action = "toggle-scratchpad-gemini";
      desc = "Toggle right Gemini chat panel";
      category = "scratchpad";
      cmd = "pypr toggle gemini";
    })
  ];

  # ── Mnemonic Which-Key & Rofi Groups ────────────────────────────────
  groups = {
    desktop = {
      root = "Super+D";
      name = "📁 Desktop Applications";
      actions = [
        (mkAction {
          chord = "B";
          action = "browser-brave";
          desc = "Brave Browser";
          category = "desktop";
          cmd = "uwsm app -- brave";
        })
        (mkAction {
          chord = "F";
          action = "file-manager";
          desc = "Dolphin File Manager";
          category = "desktop";
          cmd = "uwsm app -- dolphin";
        })
        (mkAction {
          chord = "C";
          action = "comms-discord";
          desc = "Vesktop / Discord";
          category = "desktop";
          cmd = "uwsm app -- vesktop";
        })
        (mkAction {
          chord = "M";
          action = "music-spotify";
          desc = "Spotify";
          category = "desktop";
          cmd = "uwsm app -- spotify";
        })
        (mkAction {
          chord = "N";
          action = "notes-obsidian";
          desc = "Obsidian PKM Notes";
          category = "desktop";
          cmd = "uwsm app -- obsidian";
        })
        (mkAction {
          chord = "E";
          action = "editor-helix";
          desc = "Helix / Neovim Editor";
          category = "desktop";
          cmd = "uwsm app -- ghostty -e hx";
        })
        (mkAction {
          chord = "S";
          action = "system-settings";
          desc = "Nwg-look / Settings";
          category = "desktop";
          cmd = "uwsm app -- nwg-look";
        })
        (mkAction {
          chord = "O";
          action = "screenshot-menu";
          desc = "Hypr-screenshot OCR/region tool";
          category = "desktop";
          cmd = "hypr-screenshot region";
        })
      ];
    };

    window = {
      root = "Super+W";
      name = "🪟 Window & Workspace Operations";
      actions = [
        (mkAction {
          chord = "Q";
          action = "close-window";
          desc = "Close focused window";
          category = "window";
          cmd = "hyprctl dispatch killactive";
        })
        (mkAction {
          chord = "F";
          action = "fullscreen";
          desc = "Toggle fullscreen";
          category = "window";
          cmd = "hyprctl dispatch fullscreen 0";
        })
        (mkAction {
          chord = "V";
          action = "toggle-floating";
          desc = "Toggle floating layout";
          category = "window";
          cmd = "hyprctl dispatch togglefloating";
        })
        (mkAction {
          chord = "P";
          action = "pin-window";
          desc = "Pin window / always on top";
          category = "window";
          cmd = "hyprctl dispatch pin";
        })
        (mkAction {
          chord = "S";
          action = "toggle-split";
          desc = "Toggle split orientation";
          category = "window";
          cmd = "hyprctl dispatch togglesplit";
        })
        (mkAction {
          chord = "H";
          action = "focus-left";
          desc = "Focus window left";
          category = "window";
          cmd = "hyprctl dispatch movefocus l";
        })
        (mkAction {
          chord = "J";
          action = "focus-down";
          desc = "Focus window down";
          category = "window";
          cmd = "hyprctl dispatch movefocus d";
        })
        (mkAction {
          chord = "K";
          action = "focus-up";
          desc = "Focus window up";
          category = "window";
          cmd = "hyprctl dispatch movefocus u";
        })
        (mkAction {
          chord = "L";
          action = "focus-right";
          desc = "Focus window right";
          category = "window";
          cmd = "hyprctl dispatch movefocus r";
        })
      ];
    };

    fleet = {
      root = "Super+F";
      name = "⚓ Fleet & Services";
      actions = [
        (mkAction {
          chord = "H";
          action = "fleet-homepage";
          desc = "Open NFP Homepage Dashboard";
          category = "fleet";
          cmd = "xdg-open http://nami.nfp.nix:3007";
          scope = "fleet-remote";
        })
        (mkAction {
          chord = "G";
          action = "fleet-grafana";
          desc = "Open Grafana Observability";
          category = "fleet";
          cmd = "xdg-open http://nami.nfp.nix:3000";
          scope = "fleet-remote";
        })
        (mkAction {
          chord = "A";
          action = "fleet-adguard";
          desc = "Open AdGuard Home DNS";
          category = "fleet";
          cmd = "xdg-open http://luffy.nfp.nix:3002";
          scope = "fleet-remote";
        })
        (mkAction {
          chord = "S";
          action = "fleet-ssh-selector";
          desc = "SSH Fleet Host Selector";
          category = "fleet";
          cmd = "uwsm app -- ghostty -e ssh nami";
          scope = "fleet-remote";
        })
        (mkAction {
          chord = "L";
          action = "fleet-logs";
          desc = "View Fleet Journal Logs";
          category = "fleet";
          cmd = "uwsm app -- ghostty -e journalctl -f";
        })
        (mkAction {
          chord = "T";
          action = "tailscale-status";
          desc = "Tailscale / Headscale Status";
          category = "fleet";
          cmd = "uwsm app -- ghostty -e tailscale status";
        })
        (mkAction {
          chord = "C";
          action = "clan-menu";
          desc = "Safe Clan / NFP Command Menu";
          category = "fleet";
          cmd = "uwsm app -- ghostty -e clan machines list";
        })
      ];
    };

    agents = {
      root = "Super+Shift+A";
      name = "🤖 Autonomous AI Agents";
      actions = [
        (mkAction {
          chord = "O";
          action = "agent-opencode";
          desc = "OpenCode AI Agent";
          category = "agents";
          cmd = "uwsm app -- opencode-desktop";
        })
        (mkAction {
          chord = "H";
          action = "agent-hermes";
          desc = "Hermes Agent CLI";
          category = "agents";
          cmd = "uwsm app -- ghostty -e hermes";
        })
        (mkAction {
          chord = "R";
          action = "agent-router";
          desc = "Polyfloor / Router API Control";
          category = "agents";
          cmd = "xdg-open http://nami.nfp.nix:7777/healthz";
          scope = "fleet-remote";
        })
        (mkAction {
          chord = "P";
          action = "agent-prompt";
          desc = "Prompt Workspace / Gemini Chat Panel";
          category = "agents";
          cmd = "pypr toggle gemini";
        })
        (mkAction {
          chord = "L";
          action = "agent-logs";
          desc = "Agent Activity Logs";
          category = "agents";
          cmd = "uwsm app -- ghostty -e journalctl --user -u hermes-agent -f";
        })
        (mkAction {
          chord = "M";
          action = "agent-monitoring";
          desc = "Agent Resource Monitor";
          category = "agents";
          cmd = "uwsm app -- ghostty -e btop";
        })
      ];
    };

    media = {
      root = "Super+M";
      name = "🎵 Media & Entertainment";
      actions = [
        (mkAction {
          chord = "S";
          action = "media-spotify";
          desc = "Spotify Desktop";
          category = "media";
          cmd = "uwsm app -- spotify";
        })
        (mkAction {
          chord = "M";
          action = "media-music-player";
          desc = "Strawberry Music Player";
          category = "media";
          cmd = "uwsm app -- strawberry";
        })
        (mkAction {
          chord = "J";
          action = "media-jellyfin";
          desc = "Jellyfin Media Server";
          category = "media";
          cmd = "xdg-open http://luffy.nfp.nix:8096";
          scope = "fleet-remote";
        })
        (mkAction {
          chord = "K";
          action = "media-kodi";
          desc = "Kodi Media Center";
          category = "media";
          cmd = "uwsm app -- kodi";
        })
        (mkAction {
          chord = "R";
          action = "media-requests";
          desc = "Jellyseerr Media Requests";
          category = "media";
          cmd = "xdg-open http://luffy.nfp.nix:5055";
          scope = "fleet-remote";
        })
        (mkAction {
          chord = "D";
          action = "media-downloads";
          desc = "Usenet & Torrent Download Queue";
          category = "media";
          cmd = "xdg-open http://luffy.nfp.nix:8081";
          scope = "fleet-remote";
        })
      ];
    };

    system = {
      root = "Super+S";
      name = "⚙️ System & Session";
      actions = [
        (mkAction {
          chord = "P";
          action = "power-menu";
          desc = "Power / Shutdown Menu";
          category = "system";
          cmd = "wlogout";
        })
        (mkAction {
          chord = "B";
          action = "bluetooth-control";
          desc = "Bluetooth Manager (Blueman)";
          category = "system";
          cmd = "uwsm app -- blueman-manager";
        })
        (mkAction {
          chord = "W";
          action = "wifi-network";
          desc = "NetworkManager TUI / GUI";
          category = "system";
          cmd = "uwsm app -- ghostty -e nmtui";
        })
        (mkAction {
          chord = "A";
          action = "audio-pavucontrol";
          desc = "Volume & Audio Control (Pavucontrol)";
          category = "system";
          cmd = "uwsm app -- pavucontrol";
        })
        (mkAction {
          chord = "C";
          action = "color-theme-control";
          desc = "Matugen / Theme Selector";
          category = "system";
          cmd = "uwsm app -- nwg-look";
        })
        (mkAction {
          chord = "R";
          action = "reload-compositor";
          desc = "Reload Hyprland Compositor Config";
          category = "system";
          cmd = "hyprctl reload && notify-send 'Hyprland' 'Configuration reloaded successfully'";
        })
        (mkAction {
          chord = "L";
          action = "lock-screen";
          desc = "Lock Screen";
          category = "system";
          cmd = "hyprlock";
        })
      ];
    };

    git = {
      root = "Super+G";
      name = "🛠️ Development & Git Workflow";
      actions = [
        (mkAction {
          chord = "G";
          action = "git-lazygit";
          desc = "Lazygit TUI";
          category = "git";
          cmd = "uwsm app -- ghostty -e lazygit";
        })
        (mkAction {
          chord = "S";
          action = "git-status";
          desc = "Git Status check in Ghostty";
          category = "git";
          cmd = "uwsm app -- ghostty -e git status";
        })
        (mkAction {
          chord = "H";
          action = "herdr-session";
          desc = "Herdr Persistent Terminal Sessions";
          category = "git";
          cmd = "uwsm app -- ghostty -e herdr";
        })
      ];
    };
  };
}
