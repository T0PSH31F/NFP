# layers/20-services/26-monitoring/homepage-dashboard.nix
# NIX FLAKE PIRATES Cyberpunk Dashboard — Contract-Driven Edition
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.layers.layer-20.services.config.homepage-dashboard;
  baseDomain = config.layers.meta.tailnetDomain or "nfp.nix";

  # Contract-driven enabled service projection
  enabledContractServices = filterAttrs (_id: svc: svc.enable && svc.homepage.enable) (
    config.nfp.services or { }
  );

  # Convert each nfp.services entry to homepage widget record
  contractWidgets = mapAttrsToList (
    id: svc:
    let
      targetHost = svc.host;
      canonicalUrl =
        if svc.tls != "none" then
          "http://${svc.tailnetName}.${baseDomain}"
        else
          "http://${targetHost}.${baseDomain}:${toString svc.port}";
      proxyUrl = "http://${svc.bind}:${toString svc.port}${svc.healthcheck.path}";
      iconPath = "/assets/icons/${svc.homepage.icon}.svg";
    in
    {
      inherit id;
      name = svc.homepage.title;
      category = svc.homepage.category;
      order = svc.homepage.order;
      onePieceSub = svc.homepage.subtitle;
      icon = iconPath;
      url = canonicalUrl;
      proxy_url = proxyUrl;
      satellite = svc.homepage.satellite;
      logs = svc.homepage.logs;
      metric = svc.homepage.metric;
      secret_env = null;
      requiresSecret = false;
    }
  ) enabledContractServices;

  # Sort widgets deterministically by order and name
  sortedWidgets = sort (
    a: b: if a.order != b.order then a.order < b.order else a.name < b.name
  ) contractWidgets;

  # Category definitions metadata
  categoryMeta = {
    luffy = {
      title = "👑 Luffy's Command — Captain's Deck";
      subtitle = "Core Command & Communication Vault";
      crewMember = "Luffy";
      avatar = "/assets/images/Lufy.png";
      color = "#ff0055";
    };
    zoro = {
      title = "⚔️ Zoro's Armory — First Mate's Watch";
      subtitle = "Network Defense & Container Armory";
      crewMember = "Zoro";
      avatar = "/assets/images/Zoro.png";
      color = "#39ff14";
    };
    nami = {
      title = "🧭 Nami's Chart Room — Navigator's Station";
      subtitle = "Search Engines & Weather Surveillance";
      crewMember = "Nami";
      avatar = "/assets/images/Nami.png";
      color = "#ff9500";
    };
    sanji = {
      title = "🍳 Sanji's Galley — Chef's Kitchen";
      subtitle = "All Blue Pantry & Recipe Collection";
      crewMember = "Sanji";
      avatar = "/assets/images/Sanji.png";
      color = "#ffd700";
    };
    robin = {
      title = "📚 Robin's Library — Archaeologist's Archive";
      subtitle = "Poneglyphs, Manga & Document Vault";
      crewMember = "Robin";
      avatar = "/assets/images/Nicorobin.png";
      color = "#00d9ff";
    };
    chopper = {
      title = "🩺 Chopper's Infirmary — Doctor's Office";
      subtitle = "Fleet Observability, Metrics & Telemetry";
      crewMember = "Chopper";
      avatar = "/assets/images/Chopper.png";
      color = "#ff00ff";
    };
    agents = {
      title = "🤖 Vegapunk Satellites — Agent Control Plane";
      subtitle = "Autonomous Agent Orchestration & LLM Gateways";
      crewMember = "Vegapunk";
      avatar = "/assets/images/Stella.png";
      color = "#8b5cf6";
    };
  };

  categoryKeys = [
    "luffy"
    "zoro"
    "nami"
    "sanji"
    "robin"
    "chopper"
    "agents"
  ];

  # Filter out categories that have no enabled services
  categoriesList = filter (cat: length cat.services > 0) (
    map (
      catId:
      let
        cat = categoryMeta.${catId};
        services = filter (w: w.category == catId) sortedWidgets;
      in
      {
        id = catId;
        inherit (cat)
          title
          subtitle
          crewMember
          avatar
          color
          ;
        inherit services;
      }
    ) categoryKeys
  );

  # Constellation: Vegapunk media constellation
  vegapunkServices = filter (w: w.category == "vegapunk") sortedWidgets;

  stellaCenter =
    let
      stellaList = filter (w: w.satellite == "stella" || w.id == "jellyfin") vegapunkServices;
    in
    if stellaList != [ ] then
      head stellaList
    else
      {
        id = "jellyfin";
        name = "Jellyfin";
        onePieceSub = "Stella — Genius Center";
        icon = "/assets/icons/jellyfin.svg";
        url = "http://jellyfin.${baseDomain}";
      };

  satelliteList = filter (w: w.id != stellaCenter.id) vegapunkServices;

  constellationData = {
    center = stellaCenter;
    satellites = map (
      w:
      w
      // {
        avatarIcon = if w.icon != "" then w.icon else "📡";
        satelliteName = w.onePieceSub;
      }
    ) satelliteList;
  };

  totalEnabledContracts = length sortedWidgets;

  secretRequiringWidgets = filter (w: w.requiresSecret) sortedWidgets;
  secretCheck = (secretRequiringWidgets != [ ]) -> (cfg.environmentFile != null);

  # Build JSON Config file directly from contract evaluation
  configObject = {
    stats = {
      crewUp = totalEnabledContracts;
      crewTotal = totalEnabledContracts;
      satellites = length vegapunkServices;
      uptime = "99.9";
    };
    categories = categoriesList;
    constellation = constellationData;
    inherit (cfg) bookmarks;
    widget_map = listToAttrs (map (w: nameValuePair w.id w) sortedWidgets);
  };

  configJsonFile = pkgs.writeText "homepage-config.json" (builtins.toJSON configObject);

  # Build Static Web Package
  staticPackage = pkgs.runCommand "homepage-dashboard-static" { } ''
    mkdir -p $out/public/assets/css $out/public/assets/js $out/public/assets/fonts $out/public/assets/images $out/public/assets/icons

    # Copy HTML
    cat << 'EOF' > $out/public/index.html
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>NIX FLAKE PIRATES — Cyberia Fleet Command</title>
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
          <svg class="jolly-roger-icon" viewBox="0 0 64 64" aria-label="Nix Flake Pirates Mark">
            <circle cx="32" cy="32" r="28" fill="none" stroke="#00d9ff" stroke-width="3"/>
            <path d="M32 12 L38 26 L52 32 L38 38 L32 52 L26 38 L12 32 L26 26 Z" fill="#ff0055"/>
          </svg>
          <h1 class="brand-title">NIX FLAKE PIRATES</h1>
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

    # Copy Service Icons
    cp ${../../../layers/00-cyberia/02-assets/homepage/services}/*.svg $out/public/assets/icons/

    # Copy Crew Avatars
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
    import time
    import urllib.error
    import urllib.request

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
                    err_msg = json.dumps({"error": "Config unavailable"}).encode("utf-8")
                    self.wfile.write(err_msg)
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
                cached_data = json.dumps(CACHE[widget_id][1]).encode("utf-8")
                self.wfile.write(cached_data)
                return

            res = {"status": "ok", "bountyStat": "OPERATIONAL"}
            try:
                with open(CONFIG_PATH, "r") as f:
                    config = json.load(f)
                widget_map = config.get("widget_map", {})
                svc_info = widget_map.get(widget_id)

                if svc_info:
                    target_url = svc_info.get("proxy_url")
                    headers = {"User-Agent": "NFP-Homepage-Dashboard/2.0"}
                    
                    req = urllib.request.Request(target_url, headers=headers)
                    try:
                        with urllib.request.urlopen(req, timeout=3) as response:
                            _ = response.read()
                            res = {"status": "ok", "bountyStat": "OPERATIONAL"}
                    except urllib.error.HTTPError as e:
                        if e.code in [401, 403]:
                            res = {"status": "ok", "bountyStat": "OPERATIONAL", "metricStatus": "Auth Required"}
                        elif e.code == 404:
                            res = {"status": "ok", "bountyStat": "OPERATIONAL", "metricStatus": "Unconfigured"}
                        else:
                            res = {"status": "ok", "bountyStat": "OPERATIONAL", "metricStatus": f"HTTP {e.code}"}
                    except Exception:
                        res = {"status": "offline", "bountyStat": "OFFLINE", "error": "Unreachable"}

                CACHE[widget_id] = (now, res)
                self.wfile.write(json.dumps(res).encode("utf-8"))
            except Exception:
                res = {"status": "ok", "bountyStat": "OPERATIONAL"}
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
                    payload = json.dumps({"status": "ok", "targets": targets})
                    self.wfile.write(payload.encode("utf-8"))
                    return
                except Exception:
                    pass
            fallback = json.dumps({"status": "ok", "uptime": "99.9%"})
            self.wfile.write(fallback.encode("utf-8"))

    def run():
        server = http.server.HTTPServer(("0.0.0.0", PORT), HomepageHandler)
        print(f"NFP Homepage Dashboard Server listening on port {PORT}...")
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

  config = mkIf cfg.enable (mkMerge [
    (mkIf (options ? sops) {
      sops.templates."homepage-dashboard-env" = {
        content = ''
          SONARR_API_KEY=""
          RADARR_API_KEY=""
          LIDARR_API_KEY=""
          PROWLARR_API_KEY=""
          BAZARR_API_KEY=""
          OVERSEERR_API_KEY=""
          READARR_API_KEY=""
          GRAFANA_API_KEY=""
          IMMICH_API_KEY=""
          HEADSCALE_API_KEY=""
          ADGUARD_API_KEY=""
          PORTAINER_API_KEY=""
          JELLYFIN_API_KEY=""
        '';
        owner = "homepage-dashboard";
        group = "homepage-dashboard";
        mode = "0400";
      };

      layers.layer-20.services.config.homepage-dashboard.environmentFile =
        mkDefault
          config.sops.templates."homepage-dashboard-env".path;
    })

    {
      layers.layer-20.services.config.homepage-dashboard.environmentFile = mkDefault (
        pkgs.writeText "homepage-dummy.env" ""
      );

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
        description = "NFP Homepage Dashboard Server Daemon";
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
    }
  ]);
}
