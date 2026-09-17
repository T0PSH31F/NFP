# layers/20-services/26-monitoring/homepage-dashboard.nix
# Grandlix × One Piece Cyberpunk Dashboard — Vegapunk Records Edition (NFP Custom Build)
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.layers.layer-20.services.config.homepage-dashboard;
  # Tailnet addresses
  z0r0 = "z0r0.nfp.nix";
  luffy = "luffy.nfp.nix";
  nami = "nami.nfp.nix";

  # Candidate widgets definition table
  widgetCatalog = [
    {
      id = "synapse";
      name = "Matrix Synapse";
      category = "luffy";
      onePieceSub = "Crew Transponder Network";
      icon = "/assets/images/Lufy.png";
      url = "http://${luffy}:8008";
      proxy_url = "http://${luffy}:8008/_matrix/client/versions";
      secret_env = null;
      requiresSecret = false;
    }
    {
      id = "mautrix";
      name = "Mautrix Bridges";
      category = "luffy";
      onePieceSub = "Bridge Network";
      icon = "/assets/images/Lufy.png";
      url = "http://${luffy}:29317";
      proxy_url = "http://${luffy}:29317";
      secret_env = null;
      requiresSecret = false;
    }
    {
      id = "nextcloud";
      name = "Nextcloud";
      category = "luffy";
      onePieceSub = "Shared Treasure Vault";
      icon = "/assets/images/Lufy.png";
      url = "http://${luffy}:8080";
      proxy_url = "http://${luffy}:8080/status.php";
      secret_env = null;
      requiresSecret = false;
    }
    {
      id = "filebrowser";
      name = "FileBrowser";
      category = "luffy";
      onePieceSub = "Ship's Log Navigator";
      icon = "/assets/images/Lufy.png";
      url = "http://${luffy}:8089";
      proxy_url = "http://${luffy}:8089/api/version";
      secret_env = null;
      requiresSecret = false;
    }
    {
      id = "immich";
      name = "Immich";
      category = "luffy";
      onePieceSub = "Crew Photo Album";
      icon = "/assets/images/Lufy.png";
      url = "http://${luffy}:2283";
      proxy_url = "http://${luffy}:2283/api/server/version";
      secret_env = "IMMICH_API_KEY";
      requiresSecret = true;
    }
    {
      id = "glances";
      name = "Glances";
      category = "luffy";
      onePieceSub = "Ship Status Monitor";
      icon = "/assets/images/Lufy.png";
      url = "http://${luffy}:61208";
      proxy_url = "http://${luffy}:61208/api/3/quicklook";
      secret_env = null;
      requiresSecret = false;
    }

    {
      id = "caddy";
      name = "Caddy";
      category = "zoro";
      onePieceSub = "Santoryu Navigation Routes";
      icon = "/assets/images/Zoro.png";
      url = "http://${luffy}:2019";
      proxy_url = "http://${luffy}:2019/config/";
      secret_env = null;
      requiresSecret = false;
    }
    {
      id = "headscale";
      name = "Headscale";
      category = "zoro";
      onePieceSub = "VPN Armory Network";
      icon = "/assets/images/Zoro.png";
      url = "http://${nami}:8086";
      proxy_url = "http://${nami}:8086/health";
      secret_env = "HEADSCALE_API_KEY";
      requiresSecret = true;
    }
    {
      id = "adguard";
      name = "AdGuard Home";
      category = "zoro";
      onePieceSub = "First Mate's Shield";
      icon = "/assets/images/Zoro.png";
      url = "http://${luffy}:3002";
      proxy_url = "http://${luffy}:3002/control/stats";
      secret_env = "ADGUARD_AUTH";
      requiresSecret = true;
    }
    {
      id = "portainer";
      name = "Portainer";
      category = "zoro";
      onePieceSub = "Container Armory";
      icon = "/assets/images/Zoro.png";
      url = "http://${luffy}:9000";
      proxy_url = "http://${luffy}:9000/api/system/status";
      secret_env = "PORTAINER_API_KEY";
      requiresSecret = true;
    }

    {
      id = "searxng";
      name = "SearXNG";
      category = "nami";
      onePieceSub = "Grand Line Map";
      icon = "/assets/images/Nami.png";
      url = "http://${luffy}:8888";
      proxy_url = "http://${luffy}:8888/healthz";
      secret_env = null;
      requiresSecret = false;
    }
    {
      id = "weather";
      name = "Open-Meteo Weather";
      category = "nami";
      onePieceSub = "Weather Surveillance";
      icon = "/assets/images/Nami.png";
      url = "https://open-meteo.com";
      proxy_url = "https://api.open-meteo.com/v1/forecast?latitude=1.3521&longitude=103.8198&current_weather=true";
      secret_env = null;
      requiresSecret = false;
    }

    {
      id = "grocy";
      name = "Grocy";
      category = "sanji";
      onePieceSub = "Galley Inventory";
      icon = "/assets/images/Sanji.png";
      url = "http://${luffy}:9192";
      proxy_url = "http://${luffy}:9192/api/system/info";
      secret_env = null;
      requiresSecret = false;
    }
    {
      id = "mealie";
      name = "Mealie";
      category = "sanji";
      onePieceSub = "Recipe Collection";
      icon = "/assets/images/Sanji.png";
      url = "http://${luffy}:9080";
      proxy_url = "http://${luffy}:9080/api/app/about";
      secret_env = null;
      requiresSecret = false;
    }

    {
      id = "jellyfin";
      name = "Jellyfin";
      category = "vegapunk";
      onePieceSub = "The Original (Genius Center)";
      icon = "/assets/images/Stella.png";
      url = "http://${luffy}:8096";
      proxy_url = "http://${luffy}:8096/Items/Counts";
      secret_env = "JELLYFIN_API_KEY";
      requiresSecret = true;
    }
    {
      id = "sonarr";
      name = "Sonarr";
      category = "vegapunk";
      onePieceSub = "Shaka — Good";
      icon = "📡";
      url = "http://${luffy}:8989";
      proxy_url = "http://${luffy}:8989/api/v3/series";
      secret_env = "SONARR_API_KEY";
      requiresSecret = true;
    }
    {
      id = "radarr";
      name = "Radarr";
      category = "vegapunk";
      onePieceSub = "Lilith — Evil";
      icon = "😈";
      url = "http://${luffy}:7878";
      proxy_url = "http://${luffy}:7878/api/v3/movie";
      secret_env = "RADARR_API_KEY";
      requiresSecret = true;
    }
    {
      id = "lidarr";
      name = "Lidarr";
      category = "vegapunk";
      onePieceSub = "Brook — Soul King 💀🎵";
      icon = "💀🎵";
      url = "http://${luffy}:8686";
      proxy_url = "http://${luffy}:8686/api/v1/album";
      secret_env = "LIDARR_API_KEY";
      requiresSecret = true;
    }
    {
      id = "prowlarr";
      name = "Prowlarr";
      category = "vegapunk";
      onePieceSub = "Edison — Thinking";
      icon = "💡";
      url = "http://${luffy}:9696";
      proxy_url = "http://${luffy}:9696/api/v1/indexer";
      secret_env = "PROWLARR_API_KEY";
      requiresSecret = true;
    }
    {
      id = "bazarr";
      name = "Bazarr";
      category = "vegapunk";
      onePieceSub = "Pythagoras — Wisdom";
      icon = "📜";
      url = "http://${luffy}:6767";
      proxy_url = "http://${luffy}:6767/api/system/status";
      secret_env = "BAZARR_API_KEY";
      requiresSecret = true;
    }
    {
      id = "overseerr";
      name = "Overseerr";
      category = "vegapunk";
      onePieceSub = "York — Greed";
      icon = "💰";
      url = "http://${luffy}:5055";
      proxy_url = "http://${luffy}:5055/api/v1/request/count";
      secret_env = "OVERSEERR_API_KEY";
      requiresSecret = true;
    }
    {
      id = "deluge";
      name = "Deluge";
      category = "vegapunk";
      onePieceSub = "Atlas — Violence";
      icon = "💪";
      url = "http://${luffy}:8112";
      proxy_url = "http://${luffy}:8112";
      secret_env = null;
      requiresSecret = false;
    }

    {
      id = "calibre-web";
      name = "Calibre-Web";
      category = "robin";
      onePieceSub = "Ancient Poneglyphs";
      icon = "/assets/images/Nicorobin.png";
      url = "http://${luffy}:8093";
      proxy_url = "http://${luffy}:8093";
      secret_env = null;
      requiresSecret = false;
    }
    {
      id = "readarr";
      name = "Readarr";
      category = "robin";
      onePieceSub = "Archaeological Discoveries";
      icon = "/assets/images/Nicorobin.png";
      url = "http://${luffy}:8787";
      proxy_url = "http://${luffy}:8787/api/v1/book";
      secret_env = "READARR_API_KEY";
      requiresSecret = true;
    }
    {
      id = "komga";
      name = "Komga";
      category = "robin";
      onePieceSub = "Manga Scrolls";
      icon = "/assets/images/Nicorobin.png";
      url = "http://${luffy}:25600";
      proxy_url = "http://${luffy}:25600/api/v1/books";
      secret_env = null;
      requiresSecret = false;
    }
    {
      id = "pastebin";
      name = "Pastebin";
      category = "robin";
      onePieceSub = "Research Fragments";
      icon = "/assets/images/Nicorobin.png";
      url = "http://${luffy}:8000";
      proxy_url = "http://${luffy}:8000";
      secret_env = null;
      requiresSecret = false;
    }

    {
      id = "prometheus";
      name = "Prometheus";
      category = "chopper";
      onePieceSub = "Medical Scanner";
      icon = "/assets/images/Chopper.png";
      url = "http://${z0r0}:9090";
      proxy_url = "http://${z0r0}:9090/api/v1/query?query=up";
      secret_env = null;
      requiresSecret = false;
    }
    {
      id = "grafana";
      name = "Grafana + Loki";
      category = "chopper";
      onePieceSub = "Medical Records";
      icon = "/assets/images/Chopper.png";
      url = "http://${z0r0}:3008";
      proxy_url = "http://${z0r0}:3008/api/health";
      secret_env = "GRAFANA_API_KEY";
      requiresSecret = true;
    }
    {
      id = "harmonia";
      name = "Harmonia";
      category = "chopper";
      onePieceSub = "Medicine Cache";
      icon = "/assets/images/Chopper.png";
      url = "http://${z0r0}:8443";
      proxy_url = "http://${z0r0}:8443";
      secret_env = null;
      requiresSecret = false;
    }
  ];

  # Enabled services in fleet
  enabledWidgets = widgetCatalog;

  secretRequiringWidgets = filter (w: w.requiresSecret) enabledWidgets;
  secretCheck = (secretRequiringWidgets != [ ]) -> (cfg.environmentFile != null);

  # Build JSON Config file
  configObject = {
    stats = {
      crewUp = 28;
      crewTotal = 30;
      satellites = 7;
      uptime = "99.9";
    };
    categories = [
      {
        id = "luffy";
        title = "👑 Luffy's Command — Captain's Deck";
        subtitle = "Core Command & Communication Vault";
        crewMember = "Luffy";
        avatar = "/assets/images/Lufy.png";
        color = "#ff0055";
        services = filter (w: w.category == "luffy") enabledWidgets;
      }
      {
        id = "zoro";
        title = "⚔️ Zoro's Armory — First Mate's Watch";
        subtitle = "Network Defense & Container Armory";
        crewMember = "Zoro";
        avatar = "/assets/images/Zoro.png";
        color = "#39ff14";
        services = filter (w: w.category == "zoro") enabledWidgets;
      }
      {
        id = "nami";
        title = "🧭 Nami's Chart Room — Navigator's Station";
        subtitle = "Search Engines & Weather Surveillance";
        crewMember = "Nami";
        avatar = "/assets/images/Nami.png";
        color = "#ff9500";
        services = filter (w: w.category == "nami") enabledWidgets;
      }
      {
        id = "sanji";
        title = "🍳 Sanji's Galley — Chef's Kitchen";
        subtitle = "All Blue Pantry & Recipe Collection";
        crewMember = "Sanji";
        avatar = "/assets/images/Sanji.png";
        color = "#ffd700";
        services = filter (w: w.category == "sanji") enabledWidgets;
      }
      {
        id = "robin";
        title = "📚 Robin's Library — Archaeologist's Archive";
        subtitle = "Poneglyphs, Manga & Document Vault";
        crewMember = "Robin";
        avatar = "/assets/images/Nicorobin.png";
        color = "#00d9ff";
        services = filter (w: w.category == "robin") enabledWidgets;
      }
      {
        id = "chopper";
        title = "🩺 Chopper's Infirmary — Doctor's Office";
        subtitle = "Fleet Observability, Metrics & Telemetry";
        crewMember = "Chopper";
        avatar = "/assets/images/Chopper.png";
        color = "#ff00ff";
        services = filter (w: w.category == "chopper") enabledWidgets;
      }
    ];
    constellation = {
      center = head (filter (w: w.id == "jellyfin") enabledWidgets);
      satellites = map (
        w:
        w
        // {
          avatarIcon = w.icon;
          satelliteName = w.onePieceSub;
        }
      ) (filter (w: w.category == "vegapunk" && w.id != "jellyfin") enabledWidgets);
    };
    inherit (cfg) bookmarks;
    widget_map = listToAttrs (map (w: nameValuePair w.id w) enabledWidgets);
  };

  configJsonFile = pkgs.writeText "homepage-config.json" (builtins.toJSON configObject);

  # Build Static Web Package
  staticPackage = pkgs.runCommand "homepage-dashboard-static" { } ''
    mkdir -p $out/public/assets/css $out/public/assets/js $out/public/assets/fonts $out/public/assets/images

    # Copy HTML
    cat << 'EOF' > $out/public/index.html
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>NFP Cyberia Command — Grandlix Homepage</title>
      <link rel="stylesheet" href="/assets/css/theme.css">
      <link rel="stylesheet" href="/assets/css/custom.css">
    </head>
    <body>
      <div class="atmosphere-container" aria-hidden="true">
        <div class="holographic-grid"></div>
        <div class="fog-layer fog-1"></div>
        <div class="fog-layer fog-2"></div>
      </div>

      <header class="command-bar">
        <div class="brand-section">
          <svg class="jolly-roger-icon" viewBox="0 0 64 64" aria-label="Straw Hat Jolly Roger">
            <circle cx="32" cy="32" r="28" fill="none" stroke="#ff0055" stroke-width="3"/>
            <ellipse cx="32" cy="22" rx="20" ry="6" fill="#ffd700"/>
            <circle cx="32" cy="20" r="12" fill="#ff0055"/>
            <circle cx="24" cy="34" r="4" fill="#fff"/>
            <circle cx="40" cy="34" r="4" fill="#fff"/>
            <path d="M22 46 Q 32 54, 42 46" stroke="#fff" stroke-width="3" fill="none"/>
          </svg>
          <h1 class="brand-title">GRANDLIX</h1>
          <div class="log-pose-container" aria-label="Log Pose Navigation Compass">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#00d9ff" stroke-width="2">
              <circle cx="12" cy="12" r="9"/>
              <path class="log-pose-needle" d="M12 5 L14 12 L12 19 L10 12 Z" fill="#ff0055"/>
            </svg>
            <span style="font-family: var(--font-header); font-size: 0.75rem; color: #00d9ff;">LOG POSE</span>
          </div>
        </div>

        <div class="search-container">
          <input type="text" id="search-input" class="search-input" placeholder="Search Grand Line Services..." aria-label="Den Den Mushi Search Bar">
        </div>

        <div class="nav-stats-bar" id="nav-stats-bar"></div>
      </header>

      <main class="dashboard-main" id="dashboard-main"></main>

      <script src="/assets/js/app.js"></script>
    </body>
    </html>
    EOF

    # Copy Theme CSS & Custom CSS
    cp ${../../../layers/00-cyberia/02-assets/templates/homepage-theme.css} $out/public/assets/css/theme.css
    cat << 'EOF' > $out/public/assets/css/custom.css
    ${cfg.customCSS}
    EOF

    # Copy Theme JS & Custom JS
    cat ${../../../layers/00-cyberia/02-assets/templates/homepage-theme.js} > $out/public/assets/js/app.js
    echo "${cfg.customJS}" >> $out/public/assets/js/app.js

    # Vendor Google Fonts from nixpkgs
    cp ${pkgs.google-fonts}/share/fonts/truetype/Orbitron\[wght\].ttf $out/public/assets/fonts/Orbitron.ttf
    cp ${pkgs.google-fonts}/share/fonts/truetype/Exo2\[wght\].ttf $out/public/assets/fonts/Exo2.ttf
    cp ${pkgs.google-fonts}/share/fonts/truetype/SpaceGrotesk\[wght\].ttf $out/public/assets/fonts/SpaceGrotesk.ttf

    # Copy Avatars
    cp ${../../../layers/00-cyberia/02-assets/png-ico/Stella.png} $out/public/assets/images/Stella.png
    cp ${../../../layers/00-cyberia/02-assets/png-ico/Lufy.png} $out/public/assets/images/Lufy.png
    cp ${../../../layers/00-cyberia/02-assets/png-ico/Zoro.png} $out/public/assets/images/Zoro.png
    cp ${../../../layers/00-cyberia/02-assets/png-ico/Nami.png} $out/public/assets/images/Nami.png
    cp ${../../../layers/00-cyberia/02-assets/png-ico/Sanji.png} $out/public/assets/images/Sanji.png
    cp ${../../../layers/00-cyberia/02-assets/png-ico/Nicorobin.png} $out/public/assets/images/Nicorobin.png
    cp ${../../../layers/00-cyberia/02-assets/png-ico/Chopper.png} $out/public/assets/images/Chopper.png
    cp ${../../../layers/00-cyberia/02-assets/png-ico/Brook.png} $out/public/assets/images/Brook.png
    cp ${../../../layers/00-cyberia/02-assets/png-ico/Franck.png} $out/public/assets/images/Franck.png
    cp ${../../../layers/00-cyberia/02-assets/png-ico/Usopp.png} $out/public/assets/images/Usopp.png
    cp ${../../../layers/00-cyberia/02-assets/png-ico/TransponderSnail.png} $out/public/assets/images/TransponderSnail.png
  '';

  # Python HTTP Daemon Server Script
  homepageServer = pkgs.writers.writePython3Bin "homepage-dashboard-server" { } ''
    import http.server
    import json
    import os
    import sys
    import time
    import urllib.request
    import urllib.error

    PORT = int(os.environ.get("HOMEPAGE_PORT", "3007"))
    STATIC_DIR = os.environ.get("HOMEPAGE_STATIC_DIR", "${staticPackage}/public")
    CONFIG_PATH = os.environ.get("HOMEPAGE_CONFIG_PATH", "${configJsonFile}")

    CACHE = {}

    class HomepageHandler(http.server.BaseHTTPRequestHandler):
        def log_message(self, format, *args):
            pass

        def do_GET(self):
            path = self.path.split('?')[0]

            if path == "/api/config":
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                try:
                    with open(CONFIG_PATH, "r") as f:
                        self.wfile.write(f.read().encode("utf-8"))
                except Exception as e:
                    self.wfile.write(json.dumps({"error": str(e)}).encode("utf-8"))
                return

            if path.startswith("/api/widget/"):
                widget_id = path[12:]
                self.handle_widget(widget_id)
                return

            if path == "/api/healthcheck":
                self.handle_healthcheck()
                return

            if path == "/":
                file_path = os.path.join(STATIC_DIR, "index.html")
            else:
                rel_path = path.lstrip("/")
                file_path = os.path.join(STATIC_DIR, rel_path)

            if os.path.exists(file_path) and os.path.isfile(file_path):
                self.send_response(200)
                if file_path.endswith(".html"):
                    self.send_header("Content-Type", "text/html; charset=utf-8")
                elif file_path.endswith(".css"):
                    self.send_header("Content-Type", "text/css")
                elif file_path.endswith(".js"):
                    self.send_header("Content-Type", "application/javascript")
                elif file_path.endswith(".ttf"):
                    self.send_header("Content-Type", "font/ttf")
                elif file_path.endswith(".png"):
                    self.send_header("Content-Type", "image/png")
                elif file_path.endswith(".svg"):
                    self.send_header("Content-Type", "image/svg+xml")
                self.end_headers()
                with open(file_path, "rb") as f:
                    self.wfile.write(f.read())
            else:
                self.send_response(404)
                self.end_headers()
                self.wfile.write(b"404 Not Found")

        def handle_widget(self, widget_id):
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()

            now = time.time()
            if widget_id in CACHE and (now - CACHE[widget_id][0] < 10):
                self.wfile.write(json.dumps(CACHE[widget_id][1]).encode("utf-8"))
                return

            try:
                with open(CONFIG_PATH, "r") as f:
                    config = json.load(f)
                widget_map = config.get("widget_map", {})
                svc_info = widget_map.get(widget_id)

                if not svc_info:
                    res = {"status": "ok", "bountyStat": "ACTIVE"}
                else:
                    target_url = svc_info.get("proxy_url")
                    secret_env = svc_info.get("secret_env")
                    headers = {"User-Agent": "Homepage-Dashboard/2.0"}

                    if secret_env:
                        api_key = os.environ.get(secret_env, "")
                        if secret_env.endswith("_API_KEY"):
                            headers["X-Api-Key"] = api_key
                        elif secret_env.endswith("_AUTH"):
                            headers["Authorization"] = api_key

                    req = urllib.request.Request(target_url, headers=headers)
                    with urllib.request.urlopen(req, timeout=5) as response:
                        raw_data = json.loads(response.read().decode("utf-8"))
                        res = {"status": "ok", "bountyStat": "OPERATIONAL"}

                CACHE[widget_id] = (now, res)
                self.wfile.write(json.dumps(res).encode("utf-8"))
            except Exception as e:
                res = {"error": f"Unreachable: {str(e)}", "status": 502}
                self.wfile.write(json.dumps(res).encode("utf-8"))

        def handle_healthcheck(self):
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            hc_file = "/run/nfp/healthcheck-targets.json"
            if os.path.exists(hc_file):
                try:
                    with open(hc_file, "r") as f:
                        targets = json.load(f)
                    self.wfile.write(json.dumps({"status": "ok", "targets": targets}).encode("utf-8"))
                    return
                except Exception:
                    pass
            self.wfile.write(json.dumps({"status": "ok", "uptime": "99.9%"}).encode("utf-8"))

    def run():
        server = http.server.HTTPServer(("0.0.0.0", PORT), HomepageHandler)
        print(f"Homepage Dashboard Server listening on port {PORT}...")
        server.serve_forever()

    if __name__ == "__main__":
        run()
  '';
in
{
  options.layers.layer-20.services.config.homepage-dashboard = {
    enable = mkEnableOption "Nix Flake Pirates Grandlix Homepage Dashboard";

    port = mkOption {
      type = types.port;
      default = 3007;
      description = "Port for homepage-dashboard-server daemon.";
    };

    environmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to SOPS EnvironmentFile for secret-requiring widgets.";
    };

    bookmarks = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              description = "Bookmark name.";
            };
            url = mkOption {
              type = types.str;
              description = "Bookmark target URL.";
            };
            category = mkOption {
              type = types.str;
              default = "Web Shortcuts";
              description = "Bookmark category.";
            };
            icon = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Bookmark icon.";
            };
          };
        }
      );
      default = [
        {
          name = "NixOS Discourse";
          url = "https://discourse.nixos.org";
          category = "Nix Community";
        }
        {
          name = "GitHub";
          url = "https://github.com";
          category = "Code";
        }
        {
          name = "Search";
          url = "https://searx.be";
          category = "Search";
        }
        {
          name = "Reddit";
          url = "https://reddit.com";
          category = "Social";
        }
        {
          name = "YouTube";
          url = "https://youtube.com";
          category = "Media";
        }
        {
          name = "Hacker News";
          url = "https://news.ycombinator.com";
          category = "News";
        }
      ];
      description = "Declarative list of Speeddial internet shortcuts/bookmarks.";
    };

    customCSS = mkOption {
      type = types.lines;
      default = "";
      description = "Extra custom CSS rules.";
    };

    customJS = mkOption {
      type = types.lines;
      default = "";
      description = "Extra custom JS logic.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = secretCheck;
        message =
          "homepage-dashboard: The following widgets require secrets via environmentFile, but environmentFile is null: "
          + concatStringsSep ", " (map (w: w.name) secretRequiringWidgets);
      }
    ];

    networking.firewall.allowedTCPPorts = [ cfg.port ];

    users.users.homepage-dashboard = {
      isSystemUser = true;
      group = "homepage-dashboard";
    };
    users.groups.homepage-dashboard = { };

    systemd.services.homepage-dashboard = {
      description = "Grandlix Homepage Dashboard Server Daemon";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        HOMEPAGE_PORT = toString cfg.port;
        HOMEPAGE_STATIC_DIR = "${staticPackage}/public";
        HOMEPAGE_CONFIG_PATH = "${configJsonFile}";
      };

      serviceConfig = {
        ExecStart = "${homepageServer}/bin/homepage-dashboard-server";
        User = "homepage-dashboard";
        Group = "homepage-dashboard";
        Restart = "on-failure";
        RestartSec = "5s";
        EnvironmentFile = mkIf (cfg.environmentFile != null) cfg.environmentFile;
      };
    };
  };
}
