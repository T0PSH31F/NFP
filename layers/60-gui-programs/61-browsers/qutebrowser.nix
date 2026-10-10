{
  config,
  lib,
  pkgs,
  osConfig ? config,
  ...
}:
let
  cfg = config.layers.layer-60.gui.qutebrowser;
in
{
  options.layers.layer-60.gui.qutebrowser = {
    enable = lib.mkEnableOption "qutebrowser keyboard-driven web browser";

    dashboardUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://100.64.0.3:3007/";
      description = "Default dashboard and start page URL";
    };
  };

  home = lib.mkIf cfg.enable {
    programs.qutebrowser = {
      enable = true;
      package = pkgs.qutebrowser;
      loadAutoconfig = false;
      enableDefaultBindings = true;

      settings = {
        "url.start_pages" = [ cfg.dashboardUrl ];
        "url.default_page" = cfg.dashboardUrl;
        "auto_save.session" = true;
        "tabs.position" = "left";
        "tabs.show" = "multiple";
        "downloads.location.prompt" = true;
        "downloads.position" = "bottom";
        "content.autoplay" = false;
        "content.blocking.enabled" = true;
        "scrolling.smooth" = true;
        "colors.webpage.preferred_color_scheme" = "dark";
      };

      searchEngines = {
        DEFAULT = "https://perplexity.com/";
        ddg = "https://duckduckgo.com/?q={}";
        g = "https://www.google.com/search?q={}";
        gh = "https://github.com/search?q={}";
        nw = "https://wiki.nixos.org/w/index.php?search={}";
      };

      quickmarks = {
        dashboard = cfg.dashboardUrl;
        nixos = "https://wiki.nixos.org/";
        github = "https://github.com/";
        tailscale = "https://login.tailscale.com/admin";
      };

      keyBindings = {
        normal = {
          "F1" = "bind";
          ",?" = "bind";
          ",h" = "help";
          ",r" = "config-source";
          ",d" = "open ${cfg.dashboardUrl}";
          ",D" = "open -t ${cfg.dashboardUrl}";
          "<Ctrl-t>" = "open --tab";
          ",p" = "open --private";
          ",b" = "adblock-update";
        };
      };

      keyMappings = {
        "<Ctrl-[>" = "<Escape>";
      };

      extraConfig = ''
        import os
        import re

        # Dynamic Noctalia color palette integration
        noctalia_conf = os.path.expanduser("~/.config/hypr/noctalia/noctalia-colors.conf")
        colors = {
            "primary": "#b1e862",
            "surface": "#11140c",
            "secondary": "#b7cf91",
            "error": "#ffb4ab",
            "tertiary": "#53f1a9",
            "surface_lowest": "#11140c",
        }

        if os.path.exists(noctalia_conf):
            try:
                with open(noctalia_conf, "r") as f:
                    for line in f:
                        m = re.match(r"^\$(\w+)\s*=\s*rgb\(([0-9a-fA-F]{6})\)", line.strip())
                        if m:
                            colors[m.group(1)] = f"#{m.group(2)}"
            except Exception:
                pass

        c.colors.completion.category.bg = colors["surface"]
        c.colors.completion.category.fg = colors["primary"]
        c.colors.completion.even.bg = colors["surface"]
        c.colors.completion.odd.bg = colors["surface"]
        c.colors.completion.fg = "#e2e3d8"
        c.colors.completion.item.selected.bg = colors["secondary"]
        c.colors.completion.item.selected.fg = colors["surface"]
        c.colors.completion.match.fg = colors["primary"]

        c.colors.statusbar.normal.bg = colors["surface"]
        c.colors.statusbar.normal.fg = "#e2e3d8"
        c.colors.statusbar.insert.bg = colors["primary"]
        c.colors.statusbar.insert.fg = colors["surface"]
        c.colors.statusbar.command.bg = colors["surface"]
        c.colors.statusbar.command.fg = colors["primary"]

        c.colors.tabs.bar.bg = colors["surface"]
        c.colors.tabs.even.bg = colors["surface"]
        c.colors.tabs.even.fg = "#a0a498"
        c.colors.tabs.odd.bg = colors["surface"]
        c.colors.tabs.odd.fg = "#a0a498"
        c.colors.tabs.selected.even.bg = colors["primary"]
        c.colors.tabs.selected.even.fg = colors["surface"]
        c.colors.tabs.selected.odd.bg = colors["primary"]
        c.colors.tabs.selected.odd.fg = colors["surface"]
      '';
    };

    # Script to import Brave Chromium bookmarks to qutebrowser on demand
    home.packages = [
      (pkgs.writeShellApplication {
        name = "qutebrowser-import-brave-bookmarks";
        runtimeInputs = [ pkgs.python3 ];
        text = ''
          python3 -c '
          import json, os

          brave_bm = os.path.expanduser("~/.config/BraveSoftware/Brave-Browser/Default/Bookmarks")
          qute_bm_dir = os.path.expanduser("~/.local/share/qutebrowser/bookmarks")
          qute_bm_file = os.path.join(qute_bm_dir, "urls")

          if not os.path.exists(brave_bm):
              print("No Brave bookmarks found at", brave_bm)
              exit(0)

          os.makedirs(qute_bm_dir, exist_ok=True)

          existing_urls = set()
          if os.path.exists(qute_bm_file):
              with open(qute_bm_file, "r") as f:
                  for line in f:
                      parts = line.strip().split(maxsplit=1)
                      if parts:
                          existing_urls.add(parts[0])

          with open(brave_bm, "r") as f:
              data = json.load(f)

          extracted = []
          def extract(node):
              if isinstance(node, dict):
                  if node.get("type") == "url" and "url" in node:
                      url = node["url"]
                      name = node.get("name", "").replace("\n", " ").strip()
                      if url and url not in existing_urls:
                          extracted.append((url, name))
                          existing_urls.add(url)
                  for v in node.values():
                      extract(v)
              elif isinstance(node, list):
                  for item in node:
                      extract(item)

          extract(data.get("roots", {}))

          if extracted:
              with open(qute_bm_file, "a") as f:
                  for url, name in extracted:
                      if name:
                          f.write(f"{url} {name}\n")
                      else:
                          f.write(f"{url}\n")
              print(f"Imported {len(extracted)} bookmarks from Brave into {qute_bm_file}")
          else:
              print("No new Brave bookmarks to import.")
          '
        '';
      })
    ];
  };
}
