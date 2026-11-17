# Vicinae Launcher Configuration
# ===============================
# Vicinae is a modern application launcher for Wayland/X11 with extension support.
#
# Features:
# - Systemd service with auto-start
# - Plugin/extension system (bluetooth, nix search, power profiles, etc.)
# - Sops-nix integration for API keys and tokens
# - Customizable theming and fonts
#
# Sops Secrets Setup:
# 1. The vicinae.json secret is declared in flake-parts/users/t0psh31f.nix
# 2. Edit secrets with: sops secrets/vicinae.yaml
# 3. The secret contains JSON with provider preferences (API keys, tokens)
# 4. Example structure in secrets/vicinae.yaml:
#    vicinae.json: |
#      {
#        "providers": {
#          "@knoopx/github-0": {
#            "preferences": { "githubToken": "ghp_..." }
#          }
#        }
#      }
#
# Available Extensions:
# - See https://github.com/vicinaehq/extensions/tree/main/extensions
# - Uncomment extensions below to enable them
# - Some require API keys configured via sops secrets

{
  config,
  lib,
  pkgs,
  osConfig ? config,
  inputs,
  ...
}:
with lib;
let
  cfg = osConfig.layers.layer-40.desktop.frameworks.vicinae;
in
{
  config = mkIf cfg.enable {
    # Configure Vicinae service (programs.vicinae also installs the configured package)
    programs.vicinae = {
      enable = true;

      # Systemd service configuration
      systemd = {
        enable = true;
        autoStart = true; # Start automatically on login
        environment = {
          USE_LAYER_SHELL = 1; # Use layer shell for Wayland
        };
      };

      # Vicinae settings
      settings = {
        # Import sops secrets (API keys, tokens for extensions)
        # Only import if sops secret exists (prevents crash when sops not configured)
        imports =
          let
            secretPath = config.sops.secrets."vicinae.json".path or null;
          in
          lib.optionals (secretPath != null && builtins.pathExists secretPath) [ secretPath ];

        # UI Behavior
        close_on_focus_loss = false;
        consider_preedit = true;
        pop_to_root_on_close = true;
        search_files_in_root = true;

        # Favicon service (for web search icons)
        favicon_service = "twenty"; # Options: "twenty", "google", "duckduckgo"

        # Font configuration
        font = {
          normal = {
            size = 16;
            normal = "JetBrainsMono Nerd Font";
          };
        };

        # Theme configuration
        # Note: The "noctalia" theme dynamically handles both light and dark modes.
        theme = {
          light = {
            name = lib.mkForce "noctalia";
            icon_theme = "candy-icons";
          };
          dark = {
            name = lib.mkForce "noctalia";
            icon_theme = "candy-icons";
          };
        };

        # Launcher window settings
        launcher_window = {
          opacity = lib.mkForce 0.95;
        };
      };

      # Extensions from vicinae-extensions repository
      extensions = with inputs.vicinae-extensions.packages.${pkgs.stdenv.hostPlatform.system}; [
        agenda
        aria2-manager
        # bluetooth
        brotab
        chromium-bookmarks
        dashboard-icons
        # exegol
        firefox
        # floww
        fuzzy-files
        hypr-keybinds
        it-tools
        kde-system-settings
        # mise
        # niri
        nix
        # otp
        # pass
        player-pilot
        podman
        port-killer
        # power-profile
        process-manager
        pulseaudio
        searxng
        # silverbullet
        # simple-bookmarks
        # skate
        # spongebob-text-transformer
        ssh
        # stocks
        # supergenpass
        vscode-recents
        # wifi-commander

        # Utilities
        # clipboard # Clipboard history manager
        # emoji # Emoji picker
        # calculator # Quick calculator
        # timer # Timer and stopwatch
        # weather # Weather information (requires API key)
        # Media & Entertainment
        # spotify # Spotify control (requires Spotify premium)
        # Window Management
        # window-switcher # Window switcher for Wayland/X11
      ];
    };
  };
}
