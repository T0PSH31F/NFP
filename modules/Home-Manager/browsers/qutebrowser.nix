{pkgs, ...}: {
  # Qutebrowser configuration
  programs.qutebrowser = {
    enable = true;

    settings = {
      # UI
      colors.webpage.preferred_color_scheme = "dark";
      tabs.position = "top";
      tabs.show = "multiple";
      statusbar.show = "always";

      # Content
      content.autoplay = false;
      content.headers.do_not_track = true;
      content.javascript.can_access_clipboard = true;
      content.notifications.enabled = false;

      # Downloads
      downloads.location.directory = "~/Downloads";
      downloads.location.prompt = false;

      # Search
      url.searchengines = {
        "DEFAULT" = "https://duckduckgo.com/?q={}";
        "g" = "https://www.google.com/search?q={}";
        "gh" = "https://github.com/search?q={}";
        "np" = "https://search.nixos.org/packages?query={}";
        "no" = "https://search.nixos.org/options?query={}";
        "yt" = "https://www.youtube.com/results?search_query={}";
      };

      url.start_pages = ["about:blank"];
      url.default_page = "about:blank";

      # Fonts
      fonts.default_family = "JetBrainsMono Nerd Font";
      fonts.default_size = "11pt";

      # Zoom
      zoom.default = "100%";

      # Hints
      hints.border = "1px solid #5294e2";
    };

    keyBindings = {
      normal = {
        # Vim-style navigation
        "J" = "tab-prev";
        "K" = "tab-next";
        "H" = "back";
        "L" = "forward";

        # Extra bindings
        ",m" = "hint links spawn mpv {hint-url}";
        ",p" = "spawn --userscript qute-pass";
      };
    };

    extraConfig = ''
      # Additional Python config
      c.content.canvas_reading = False
      c.content.webgl = True
      c.content.headers.user_agent = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    '';
  };
}
