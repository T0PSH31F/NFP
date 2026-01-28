{
  pkgs,
  lib,
  ...
}:
with lib;
{
  # Firefox home-manager configuration

  programs.firefox = {
    enable = true;

    profiles.default = {
      id = 0;
      name = "default";
      isDefault = true;

      settings = {
        "browser.startup.homepage" = "https://search.nixos.org/";
        # Performance
        "gfx.webrender.all" = true;
        "media.ffmpeg.vaapi.enabled" = true;
        "media.hardware-video-decoding.force-enabled" = true;

        # Privacy
        "privacy.donottrackheader.enabled" = true;
        "privacy.trackingprotection.enabled" = true;
        "privacy.trackingprotection.socialtracking.enabled" = true;
        "browser.contentblocking.category" = "strict";

        # Disable telemetry
        "toolkit.telemetry.enabled" = false;
        "toolkit.telemetry.unified" = false;
        "toolkit.telemetry.archive.enabled" = false;
        "datareporting.healthreport.uploadEnabled" = false;
        "datareporting.policy.dataSubmissionEnabled" = false;

        # Disable Pocket
        "extensions.pocket.enabled" = false;

        # UI tweaks
        "browser.tabs.inTitlebar" = 0;
        "browser.uidensity" = 1; # Compact mode
        "browser.theme.toolbar-theme" = 0; # Dark theme

        # Smooth scrolling
        "general.smoothScroll" = true;
        "general.smoothScroll.mouseWheel.durationMaxMS" = 250;
        "general.smoothScroll.mouseWheel.durationMinMS" = 125;

        # New tab page
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
      };

      # Extensions (using nixpkgs firefox addons)
      extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
        ublock-origin
        privacy-badger
        decentraleyes
        clearurls
        sponsorblock
        return-youtube-dislikes
        darkreader
        vim-vixen
      ];

      # Search engines
      search = {
        force = true;
        default = "Perplexity";
        privateDefault = "Perplexity";

        engines = {
          "Nix Packages" = {
            urls = [
              {
                template = "https://search.nixos.org/packages";
                params = [
                  {
                    name = "type";
                    value = "packages";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = "''${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = [ "@np" ];
          };

          "NixOS Options" = {
            urls = [
              {
                template = "https://search.nixos.org/options";
                params = [
                  {
                    name = "type";
                    value = "packages";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = "''${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = [ "@no" ];
          };

          "Home Manager" = {
            urls = [
              {
                template = "https://home-manager-options.extranix.com/";
                params = [
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            definedAliases = [ "@hm" ];
          };

          "GitHub" = {
            urls = [
              {
                template = "https://github.com/search";
                params = [
                  {
                    name = "q";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            definedAliases = [ "@gh" ];
          };
        };
      };
    };
    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableFirefoxAccounts = true;
      DisableFormHistory = true;
      DisplayBookmarksToolbar = "newtab";
      DontCheckDefaultBrowser = true;

      # Enable tracking protection
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
      };

      # Performance settings
      Preferences = {
        "browser.cache.disk.enable" = false;
        "browser.cache.memory.enable" = true;
        "browser.cache.memory.capacity" = 512000;
        "media.ffmpeg.vaapi.enabled" = true;
        "media.hardware-video-decoding.force-enabled" = true;
      };
    };
    # User Chrome CSS (optional, can be enabled later)
    # userChrome = ''
    #   /* Custom CSS here */
    # '';
  };
}
