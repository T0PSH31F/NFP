# Tier: 60-gui-programs
# Module: 68-communication/discord.nix
# Purpose: Discord clients — Vesktop (Vencord) & Equibop (Equicord) — with
#          declarative plugin and theme configuration.
{
  config,
  lib,
  pkgs,
  osConfig ? config,
  ...
}:
let
  cfg = config.layers.layer-60.gui.communication.discord;
  commEnabled = config.layers.layer-60.gui.communication.enable;
  user = config.layers.meta.primaryUser or "t0psh31f";
in
{
  options.layers.layer-60.gui.communication.discord = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Discord clients (Vesktop & Equibop).";
    };

    # ── Vesktop ─────────────────────────────────────────────────────────────
    vesktop = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Vesktop — the Vencord-bundled Discord desktop client.";
      };

      package = lib.mkOption {
        type = lib.types.nullOr lib.types.package;
        default = pkgs.vesktop;
        description = "The Vesktop package to use.";
      };

      mutableSettings = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Allow Vesktop settings to be mutated at runtime (merged on activation).";
      };

      themes = lib.mkOption {
        type = lib.types.attrsOf lib.types.lines;
        default = { };
        description = ''
          Vencord themes to install. Each key becomes <name>.css and can be
          enabled via the enabledThemes option below.
        '';
        example = lib.literalExpression ''
          { "midnight" = builtins.readFile ./themes/midnight.css; }
        '';
      };

      enabledThemes = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "List of theme filenames (with .css) to activate in Vencord.";
        example = [ "midnight.css" ];
      };
    };

    # ── Equibop ─────────────────────────────────────────────────────────────
    equibop = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Equibop — the Equicord-bundled Discord desktop client.";
      };

      package = lib.mkOption {
        type = lib.types.nullOr lib.types.package;
        default = pkgs.equibop;
        description = "The Equibop package to use.";
      };

      themes = lib.mkOption {
        type = lib.types.attrsOf lib.types.lines;
        default = { };
        description = ''
          Equicord themes to install. Each key becomes <name>.css and can be
          enabled via the enabledThemes option below.
        '';
        example = lib.literalExpression ''
          { "midnight" = builtins.readFile ./themes/midnight.css; }
        '';
      };

      enabledThemes = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "List of theme filenames (with .css) to activate in Equicord.";
        example = [ "midnight.css" ];
      };
    };
  };

  # programs.vesktop / programs.equibop are Home Manager options. This file is
  # imported raw via default.nix imports (not multi-class-wrapped), so route
  # through home-manager.users like beeper.nix.
  config = lib.mkIf (commEnabled && cfg.enable) {
    home-manager.users.${user} = {
      # ── Vesktop ─────────────────────────────────────────────────────────────
      programs.vesktop = lib.mkIf cfg.vesktop.enable {
        enable = true;
        package = cfg.vesktop.package;

        vencord = {
          useSystem = true;
          themes = cfg.vesktop.themes;

          settings = {
            autoUpdate = true;
            autoUpdateNotification = false;
            disableMinSize = true;
            notifyAboutUpdates = false;
            useQuickCss = true;
            enabledThemes = cfg.vesktop.enabledThemes;

            plugins = {
              AlwaysTrust.enabled = true;
              BetterFolders.enabled = true;
              ClearURLs.enabled = true;
              FakeNitro.enabled = true;
              PinDMs.enabled = true;
              WebKeybinds.enabled = true;
              WebScreenShareFixes.enabled = true;
            };
          };
        };

        settings = {
          arRPC = true;
          checkUpdates = false;
          enableSplashScreen = false;
        };
      };

      # ── Equibop ─────────────────────────────────────────────────────────────
      programs.equibop = lib.mkIf cfg.equibop.enable {
        enable = true;
        package = cfg.equibop.package;

        equicord = {
          themes = cfg.equibop.themes;

          settings = {
            autoUpdate = true;
            autoUpdateNotification = false;
            disableMinSize = true;
            notifyAboutUpdates = false;
            useQuickCss = true;
            enabledThemes = cfg.equibop.enabledThemes;

            plugins = {
              # ── Privacy / Safety ───────────────────────────────────────
              alwaysTrust.enabled = true;
              clearURLs.enabled = true;
              silentTyping.enabled = true;

              # ── UX ─────────────────────────────────────────────────────
              betterFolders.enabled = true;
              betterSettings.enabled = true;
              memberCount.enabled = true;
              mentionAvatars.enabled = true;
              messageLatency.enabled = true;
              noReplyMention.enabled = true;
              noTypingAnimation.enabled = true;
              pinDms.enabled = true;
              platformIndicators.enabled = true;
              roleColorEverywhere.enabled = true;
              showHiddenChannels.enabled = true;
              showMeYourName.enabled = true;
              typingIndicator.enabled = true;
              viewIcons.enabled = true;
              messageLogger.enabled = true;

              # ── Media ──────────────────────────────────────────────────
              fakeNitro.enabled = true;
              imageZoom.enabled = true;
              pictureInPicture.enabled = true;
              voiceMessages.enabled = true;
              volumeBooster.enabled = true;

              # ── Web / Desktop-specific (must be quoted — contain dots) ─
              "webKeybinds.web".enabled = true;
              "webScreenShareFixes.web".enabled = true;
              "webScreenShare.browser".enabled = true;
            };
          };
        };

        settings = {
          arRPC = true;
          checkUpdates = false;
          enableSplashScreen = false;
        };
      };
    };
  };
}
