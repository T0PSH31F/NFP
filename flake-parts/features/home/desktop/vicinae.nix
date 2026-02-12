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
  osConfig,
  inputs,
  ...
}:
with lib;
let
  cfg = config.desktop.vicinae;
in
{
  options.desktop.vicinae = {
    enable = mkOption {
      type = types.bool;
      default = builtins.elem "desktop" (osConfig.clan.core.tags or [ ]);
      description = "Enable Vicinae launcher";
    };
  };

  config = mkIf cfg.enable {
    # Install Vicinae package
    home.packages = [
      inputs.vicinae.packages.${pkgs.system}.default
    ];

    # Configure Vicinae service
    services.vicinae = {
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
        close_on_focus_loss = true;
        consider_preedit = true;
        pop_to_root_on_close = true;
        search_files_in_root = true;

        # Favicon service (for web search icons)
        favicon_service = "twenty"; # Options: "twenty", "google", "duckduckgo"

        # Font configuration
        font = {
          normal = {
            size = 12;
            normal = "JetBrainsMono Nerd Font";
          };
        };

        # Theme configuration
        theme = {
          light = {
            name = "vicinae-light";
            icon_theme = "default";
          };
          dark = {
            name = "vicinae-dark";
            icon_theme = "default";
          };
        };

        # Launcher window settings
        launcher_window = {
          opacity = 0.95;
        };
      };

      # Extensions from vicinae-extensions repository
      extensions = with inputs.vicinae-extensions.packages.${pkgs.stdenv.hostPlatform.system}; [
        # System & Power Management
        bluetooth # Bluetooth device management
        power-profile # Power profile switching (performance/balanced/power-saver)

        # Development & Nix
        nix # Nix package search and management
        # github # GitHub repository search (requires token in providers config)

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
