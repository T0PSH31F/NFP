# Module evaluation & VM check — verifies homepage-dashboard module evaluates and runs correctly
{
  name = "homepage-dashboard-module";
  nodes.machine =
    {
      lib,
      pkgs ? null,
      ...
    }:
    {
      imports = [
        ../../80-lib/81-helpers/mkServiceContract.nix
        ../../20-services/26-monitoring/homepage-dashboard.nix
      ];

      options = {
        layers.layer-10.system.config.impermanence.enable = lib.mkEnableOption "impermanence";
        environment.persistence = lib.mkOption {
          type = lib.types.attrs;
          default = { };
        };
        sops.templates = lib.mkOption {
          type = lib.types.attrs;
          default = { };
        };
      };

      config = {
        layers.layer-20.services.config.homepage-dashboard = {
          enable = true;
          port = 3007;
        };

        systemd.services.homepage-dashboard.environment = {
          SONARR_API_KEY = "test-sonarr-key";
          JELLYFIN_API_KEY = "test-jellyfin-key";
        };

        systemd.services.mock-sensors = {
          description = "Mock Service Endpoints for Homepage Dashboard Test";
          wantedBy = [ "multi-user.target" ];
          before = [ "homepage-dashboard.service" ];
          serviceConfig = {
            ExecStart = pkgs.writeScript "mock-sensors" ''
              #!${pkgs.python3}/bin/python3
              import http.server
              import socketserver
              import threading
              import time

              class MockHandler(http.server.BaseHTTPRequestHandler):
                  def log_message(self, *args):
                      pass

                  def do_GET(self):
                      port = self.server.server_address[1]

                      if port == 2019:
                          # caddy: /config/ and /config/apps/http/servers/
                          self.send_response(200)
                          self.send_header("Content-Type", "application/json")
                          self.end_headers()
                          if "/config/apps/http/servers/" in self.path:
                              self.wfile.write(b'{"srv0": {"routes": [{"match": []}]}}')
                          else:
                              self.wfile.write(b'{"srv0": {"routes": [{"match": []}]}}')
                      elif port == 3000:
                          # adguard: /control/stats
                          self.send_response(200)
                          self.send_header("Content-Type", "application/json")
                          self.end_headers()
                          self.wfile.write(b'{"num_dns_queries": 1250, "num_blocked_filtering": 350, "num_replaced_safebrowsing": 0}')
                      elif port == 8096:
                          # jellyfin: /health, /Items/Counts, /Sessions
                          self.send_response(200)
                          self.send_header("Content-Type", "application/json")
                          self.end_headers()
                          if "/Items/Counts" in self.path:
                              self.wfile.write(b'{"MovieCount": 120, "SeriesCount": 45, "SongCount": 800}')
                          elif "/Sessions" in self.path:
                              self.wfile.write(b'[{"NowPlayingItem": {"Name": "Episode 1"}}]')
                          else:
                              self.wfile.write(b'{"Health": "Healthy"}')
                      elif port == 8989:
                          # sonarr: /api/v3/system/status, /api/v3/series
                          self.send_response(200)
                          self.send_header("Content-Type", "application/json")
                          self.end_headers()
                          if "/api/v3/series" in self.path:
                              self.wfile.write(b'[{"id": 1, "statistics": {"episodeCount": 24}}, {"id": 2, "statistics": {"episodeCount": 12}}]')
                          else:
                              self.wfile.write(b'{"status": "ok"}')
                      elif port == 8990:
                          # mock 401 service: healthcheck succeeds on /health, but /api/v3/movie returns 401
                          if self.path == "/health":
                              self.send_response(200)
                              self.send_header("Content-Type", "application/json")
                              self.end_headers()
                              self.wfile.write(b'{"status": "ok"}')
                          else:
                              self.send_response(401)
                              self.send_header("Content-Type", "application/json")
                              self.end_headers()
                              self.wfile.write(b'{"error": "Unauthorized"}')
                      else:
                          self.send_response(200)
                          self.send_header("Content-Type", "application/json")
                          self.end_headers()
                          self.wfile.write(b'{}')

              class ThreadedTCPServer(socketserver.ThreadingMixIn, socketserver.TCPServer):
                  allow_reuse_address = True

              for p in [2019, 3000, 8096, 8989, 8990]:
                  srv = ThreadedTCPServer(("127.0.0.1", p), MockHandler)
                  t = threading.Thread(target=srv.serve_forever, daemon=True)
                  t.start()

              while True:
                  time.sleep(1)
            '';
            Restart = "always";
          };
        };

        nfp.services = {
          caddy = {
            enable = true;
            host = "luffy";
            bind = "127.0.0.1";
            port = 2019;
            tailnetName = "caddy";
            tls = "headscale";
            healthcheck = {
              enable = true;
              path = "/config/";
              expectedStatus = [ 200 ];
            };
            homepage = {
              enable = true;
              category = "zoro";
              title = "Caddy";
              subtitle = "Santoryu Navigation Routes";
              icon = "caddy";
              metric = {
                mode = "native-api";
                adapter = "caddy";
                fields = [
                  "routes"
                  "uptime"
                ];
              };
            };
          };

          adguard = {
            enable = true;
            host = "luffy";
            bind = "127.0.0.1";
            port = 3000;
            tailnetName = "adguard";
            tls = "headscale";
            healthcheck = {
              enable = true;
              path = "/control/stats";
              expectedStatus = [
                200
                401
              ];
            };
            homepage = {
              enable = true;
              category = "zoro";
              title = "AdGuard";
              subtitle = "First Mate's Third Sword";
              icon = "adguard";
              metric = {
                mode = "native-api";
                adapter = "adguard";
                fields = [
                  "queriesToday"
                  "blockedCount"
                  "blockedPercent"
                ];
              };
            };
          };

          jellyfin = {
            enable = true;
            host = "luffy";
            bind = "127.0.0.1";
            port = 8096;
            tailnetName = "jellyfin";
            tls = "headscale";
            healthcheck = {
              enable = true;
              path = "/health";
              expectedStatus = [ 200 ];
            };
            homepage = {
              enable = true;
              category = "vegapunk";
              title = "Jellyfin";
              subtitle = "Grand Line Theater";
              icon = "jellyfin";
              satellite = "stella";
              metric = {
                mode = "native-api";
                adapter = "jellyfin";
                fields = [
                  "movies"
                  "series"
                  "musicAlbums"
                  "activeStreams"
                ];
              };
            };
          };

          sonarr = {
            enable = true;
            host = "luffy";
            bind = "127.0.0.1";
            port = 8989;
            tailnetName = "sonarr";
            tls = "headscale";
            healthcheck = {
              enable = true;
              path = "/api/v3/system/status";
              expectedStatus = [ 200 ];
            };
            homepage = {
              enable = true;
              category = "vegapunk";
              title = "Sonarr";
              subtitle = "Anime Transponder";
              icon = "sonarr";
              satellite = "shaka";
              metric = {
                mode = "native-api";
                adapter = "sonarr";
                fields = [
                  "series"
                  "episodes"
                ];
              };
            };
          };

          auth-fail-svc = {
            enable = true;
            host = "luffy";
            bind = "127.0.0.1";
            port = 8990;
            tailnetName = "auth-fail-svc";
            tls = "headscale";
            healthcheck = {
              enable = true;
              path = "/health";
              expectedStatus = [ 200 ];
            };
            homepage = {
              enable = true;
              category = "vegapunk";
              title = "Auth Fail Service";
              subtitle = "York Satellite Unauth";
              icon = "radarr";
              satellite = "york";
              metric = {
                mode = "native-api";
                adapter = "radarr";
                fields = [ "movies" ];
              };
            };
          };

          dashboard-url-svc = {
            enable = true;
            host = "luffy";
            bind = "127.0.0.1";
            port = 3008;
            tailnetName = "dashboard-url-svc";
            tls = "headscale";
            healthcheck = {
              enable = true;
              path = "/health";
              expectedStatus = [ 200 ];
            };
            homepage = {
              enable = true;
              category = "chopper";
              title = "Explicit Dashboard Svc";
              subtitle = "Custom Dashboard URL";
              icon = "grafana";
              dashboardUrl = "https://custom-dashboard.nfp.nix/explore";
              metric = {
                mode = "health-only";
              };
            };
          };

          offline-svc = {
            enable = true;
            host = "luffy";
            bind = "127.0.0.1";
            port = 9999;
            tailnetName = "offline-svc";
            tls = "headscale";
            healthcheck = {
              enable = true;
              path = "/";
              expectedStatus = [ 200 ];
            };
            homepage = {
              enable = true;
              category = "luffy";
              title = "Offline Service";
              subtitle = "Unreachable Node";
              icon = "filebrowser";
              metric = {
                mode = "native-api";
                adapter = "filebrowser";
                fields = [
                  "files"
                  "size"
                ];
              };
            };
          };

          disabled-svc = {
            enable = false;
            host = "luffy";
            bind = "127.0.0.1";
            port = 9998;
            tailnetName = "disabled-svc";
            tls = "headscale";
            healthcheck = {
              enable = true;
              path = "/";
              expectedStatus = [ 200 ];
            };
            homepage = {
              enable = true;
              category = "zoro";
              title = "Disabled Service";
              subtitle = "Should Not Appear";
              icon = "jackett";
            };
          };
        };

        layers.layer-10.system.config.impermanence.enable = false;
        networking.hostName = "luffy";
        system.stateVersion = "25.05";
      };
    };

  testScript = ''
    import json
    import re
    import time

    machine.wait_for_unit("mock-sensors.service")
    machine.wait_for_open_port(2019)
    machine.wait_for_open_port(3000)
    machine.wait_for_open_port(8096)
    machine.wait_for_open_port(8989)
    machine.wait_for_open_port(8990)

    machine.wait_for_unit("homepage-dashboard.service")
    machine.wait_for_open_port(3007)

    # 1. HTML serves NIX FLAKE PIRATES brand title and local theme assets; no raw icon paths as visible text
    html = machine.succeed("curl -fsS http://localhost:3007")
    assert "NIX FLAKE PIRATES" in html, "HTML missing NIX FLAKE PIRATES brand title"
    assert "GRANDLIX" not in html, "HTML still contains obsolete GRANDLIX brand title"
    assert "/assets/css/theme.css" in html, "HTML missing theme CSS link"
    assert "/assets/js/app.js" in html, "HTML missing app JS link"
    assert "http://" not in html and "https://" not in html, "HTML contains external URL references"

    app_js = machine.succeed("curl -fsS http://localhost:3007/assets/js/app.js")
    # Verify icon paths are rendered through <img> elements, never raw text content
    assert 'class="service-card-icon"' in app_js, "app.js missing service-card-icon img class"
    assert 'class="satellite-bubble-img"' in app_js, "app.js missing satellite-bubble-img class"
    assert not re.search(r'>\s*\/assets\/icons\/', html), "HTML contains raw /assets/icons/ text outside attributes"

    # 2. /api/config lists contract-driven categories, bookmarks, widget_map, and valid constellation
    config_raw = machine.succeed("curl -fsS http://localhost:3007/api/config")
    config = json.loads(config_raw)
    assert "categories" in config, "/api/config missing categories"
    assert "bookmarks" in config, "/api/config missing bookmarks"
    assert "widget_map" in config, "/api/config missing widget_map"

    wmap = config["widget_map"]
    assert "caddy" in wmap, "/api/config missing caddy"
    assert "adguard" in wmap, "/api/config missing adguard"
    assert "jellyfin" in wmap, "/api/config missing jellyfin"
    assert "sonarr" in wmap, "/api/config missing sonarr"
    assert "auth-fail-svc" in wmap, "/api/config missing auth-fail-svc"
    assert "dashboard-url-svc" in wmap, "/api/config missing dashboard-url-svc"
    assert "offline-svc" in wmap, "/api/config missing offline-svc"
    assert "disabled-svc" not in wmap, "/api/config leaked disabled-svc into widget_map"

    # Verify client launch URLs: Pattern A for standard services, custom URL for dashboardUrl, no localhost leak
    assert wmap["adguard"]["url"] == "http://luffy.nfp.nix:3000", f"Unexpected Pattern A URL for adguard: {wmap['adguard']['url']}"
    assert wmap["dashboard-url-svc"]["url"] == "https://custom-dashboard.nfp.nix/explore", f"Expected custom dashboard URL, got {wmap['dashboard-url-svc']['url']}"
    for wid, winfo in wmap.items():
        assert "localhost" not in winfo["url"] and "127.0.0.1" not in winfo["url"], f"Service {wid} leaked localhost into client URL: {winfo['url']}"
        assert winfo["url"].startswith("http://") or winfo["url"].startswith("https://"), f"Invalid client URL scheme for {wid}: {winfo['url']}"

    # Verify accessibility and truthful indicator presence in app.js
    assert 'role="button"' in app_js, "app.js missing role=button for constellation accessibility"
    assert 'tabindex="0"' in app_js, "app.js missing tabindex=0 for constellation keyboard navigation"
    assert 'snail-checking' in app_js, "app.js missing snail-checking class"
    assert 'REACHABLE' in app_js, "app.js missing REACHABLE text"

    # 3. Real sample metrics visibly render for enabled services with adapters
    adguard_data = json.loads(machine.succeed("curl -fsS http://localhost:3007/api/widget/adguard"))
    assert adguard_data["health"]["state"] == "online", f"adguard health expected online, got {adguard_data.get('health')}"
    assert adguard_data["metric"]["state"] == "available", f"adguard metric expected available, got {adguard_data.get('metric')}"
    adguard_keys = [f["key"] for f in adguard_data["metric"]["fields"]]
    assert "queriesToday" in adguard_keys, "adguard missing queriesToday field"
    assert "blockedCount" in adguard_keys, "adguard missing blockedCount field"
    assert "blockedPercent" in adguard_keys, "adguard missing blockedPercent field"
    assert "⚡ Queries: 1.2k" in adguard_data["bountyStat"], f"adguard unexpected bounty: {adguard_data.get('bountyStat')}"

    caddy_data = json.loads(machine.succeed("curl -fsS http://localhost:3007/api/widget/caddy"))
    assert caddy_data["metric"]["state"] == "available", "caddy metric expected available"
    caddy_keys = [f["key"] for f in caddy_data["metric"]["fields"]]
    assert "routes" in caddy_keys and "uptime" in caddy_keys, "caddy missing fields"
    assert "1 ROUTES ACTIVE" in caddy_data["bountyStat"], f"caddy unexpected bounty: {caddy_data.get('bountyStat')}"

    jellyfin_data = json.loads(machine.succeed("curl -fsS http://localhost:3007/api/widget/jellyfin"))
    assert jellyfin_data["metric"]["state"] == "available", "jellyfin metric expected available"
    jellyfin_keys = [f["key"] for f in jellyfin_data["metric"]["fields"]]
    assert "movies" in jellyfin_keys and "series" in jellyfin_keys and "activeStreams" in jellyfin_keys
    assert "1 STREAMS | 165 ITEMS" in jellyfin_data["bountyStat"], f"jellyfin unexpected bounty: {jellyfin_data.get('bountyStat')}"

    sonarr_data = json.loads(machine.succeed("curl -fsS http://localhost:3007/api/widget/sonarr"))
    assert sonarr_data["metric"]["state"] == "available", "sonarr metric expected available"
    sonarr_keys = [f["key"] for f in sonarr_data["metric"]["fields"]]
    assert "series" in sonarr_keys and "episodes" in sonarr_keys
    assert "2 SERIES | 36 EPISODES" in sonarr_data["bountyStat"], f"sonarr unexpected bounty: {sonarr_data.get('bountyStat')}"

    # 4. Health-success + metric credential unavailable renders online status plus sanitized reason
    auth_fail_data = json.loads(machine.succeed("curl -fsS http://localhost:3007/api/widget/auth-fail-svc"))
    assert auth_fail_data["health"]["state"] == "online", f"auth-fail-svc health expected online, got {auth_fail_data.get('health')}"
    assert auth_fail_data["status"] == "online", "auth-fail-svc status expected online"
    assert auth_fail_data["metric"]["state"] == "unavailable", f"auth-fail-svc metric state expected unavailable, got {auth_fail_data.get('metric')}"
    assert auth_fail_data["metric"]["reason"] == "Metrics credential unavailable", f"auth-fail-svc unexpected reason: {auth_fail_data.get('metric')}"
    assert auth_fail_data["bountyStat"] == "Metrics credential unavailable", f"auth-fail-svc unexpected bounty: {auth_fail_data.get('bountyStat')}"

    # 5. Health failure renders offline independently
    offline_data = json.loads(machine.succeed("curl -fsS http://localhost:3007/api/widget/offline-svc"))
    assert offline_data["health"]["state"] == "offline", f"offline-svc health expected offline, got {offline_data.get('health')}"
    assert offline_data["status"] == "offline", "offline-svc status expected offline"
    assert offline_data["metric"]["state"] == "unavailable", "offline-svc metric expected unavailable"
    assert offline_data["bountyStat"] == "OFFLINE", f"offline-svc bounty expected OFFLINE, got {offline_data.get('bountyStat')}"

    # 6. Raw parser/HTTP error strings and secrets never leak in responses
    for wid in wmap:
        raw = machine.succeed(f"curl -fsS http://localhost:3007/api/widget/{wid}")
        for forbidden in ["Traceback", "HTTPError", "urllib", "Exception", "/data/.state", "test-sonarr-key", "test-jellyfin-key"]:
            assert forbidden not in raw, f"Leaked forbidden string '{forbidden}' in widget {wid} response: {raw}"

    # 7. Vegapunk section contains bounded center/satellite layout on desktop
    theme_css = machine.succeed("curl -fsS http://localhost:3007/assets/css/theme.css")
    assert ".constellation-stage-wrapper" in theme_css, "theme.css missing .constellation-stage-wrapper"
    assert "overflow: hidden" in theme_css, "theme.css missing overflow: hidden in constellation"
    assert ".constellation-orbit-stage" in theme_css, "theme.css missing .constellation-orbit-stage"
    assert "width: 420px" in theme_css, "theme.css missing bounded width 420px for orbit stage"
    assert ".constellation-stella-node" in theme_css, "theme.css missing .constellation-stella-node"

    # 8. Vegapunk section falls back to non-overflowing grid on narrow viewport
    assert "@media (max-width: 768px)" in theme_css, "theme.css missing 768px media query"
    assert ".constellation-stage-wrapper { display: none; }" in theme_css, "theme.css missing mobile display: none fallback"

    # 9. No static disabled service card or fake metric appears
    assert "disabled-svc" not in wmap, "disabled-svc present in widget_map"
    for cat in config["categories"]:
        for svc in cat.get("services", []):
            assert svc["id"] != "disabled-svc", f"disabled-svc leaked into category {cat.get('id')}"

    constellation = config.get("constellation")
    assert constellation is not None, "constellation expected when Jellyfin and satellites are enabled"
    assert constellation["center"]["id"] == "jellyfin", f"Expected Jellyfin as constellation center, got {constellation['center']}"
    satellite_ids = [s["id"] for s in constellation["satellites"]]
    assert "sonarr" in satellite_ids, "sonarr missing from satellites"
    assert "auth-fail-svc" in satellite_ids, "auth-fail-svc missing from satellites"
    assert "disabled-svc" not in satellite_ids, "disabled-svc present in satellites"

    # 10. All current active service asset URLs return HTTP 200
    css_status = machine.succeed("curl -s -o /dev/null -w '%{http_code}' http://localhost:3007/assets/css/theme.css")
    assert css_status.strip() == "200", f"theme.css returned {css_status}"

    js_status = machine.succeed("curl -s -o /dev/null -w '%{http_code}' http://localhost:3007/assets/js/app.js")
    assert js_status.strip() == "200", f"app.js returned {js_status}"

    for wid, winfo in wmap.items():
        icon_path = winfo.get("icon")
        if icon_path and icon_path.startswith("/assets/"):
            st = machine.succeed(f"curl -s -o /dev/null -w '%{{http_code}}' http://localhost:3007{icon_path}")
            assert st.strip() == "200", f"Icon for {wid} ({icon_path}) returned {st}"

    # 11. Cache determinism & non-inflation test
    for _ in range(3):
        repeat_config = json.loads(machine.succeed("curl -fsS http://localhost:3007/api/config"))
        assert list(repeat_config["widget_map"].keys()) == list(wmap.keys()), "Non-deterministic widget ordering in /api/config"

    initial_cached = json.loads(machine.succeed("curl -fsS http://localhost:3007/api/widget/adguard"))
    time.sleep(0.5)
    second_cached = json.loads(machine.succeed("curl -fsS http://localhost:3007/api/widget/adguard"))
    assert initial_cached["updatedAt"] == second_cached["updatedAt"], "Cache miss: updatedAt timestamp changed within TTL window"
    assert sorted(initial_cached.keys()) == sorted(second_cached.keys()), "Cache inflated response keys"
  '';
}
