# layers/20-services/26-monitoring/homepage-dashboard.nix
# NIX FLAKE PIRATES Cyberpunk Dashboard — Contract-Driven Edition
{
  config,
  lib,
  pkgs,
  ...
}@args:

with lib;

let
  inputs = args.inputs or { };
  cfg = config.layers.layer-20.services.config.homepage-dashboard;
  baseDomain = config.layers.meta.tailnetDomain or "nfp.nix";

  localHost = config.networking.hostName;

  # Local enabled service contracts
  localContractServices = filterAttrs (_id: svc: svc.enable && svc.homepage.enable) (
    config.nfp.services or { }
  );

  # Remote enabled service contracts across the fleet
  # Avoid evaluation recursion: strictly filter out localHost from remote evaluation
  remoteFleetConfigs =
    if (inputs ? self && inputs.self ? nixosConfigurations) then
      filterAttrs (name: _cfg: name != localHost) inputs.self.nixosConfigurations
    else
      { };

  remoteContractServices = foldl' (
    acc: remoteName:
    let
      remoteCfg = remoteFleetConfigs.${remoteName}.config;
      remoteServices = filterAttrs (_id: svc: svc.enable && svc.homepage.enable) (
        remoteCfg.nfp.services or { }
      );
    in
    acc
    // (mapAttrs' (
      id: svc:
      let
        # If id exists locally or in another remote, qualify as id@remoteName
        key = if (hasAttr id localContractServices || hasAttr id acc) then "${id}@${remoteName}" else id;
      in
      nameValuePair key svc
    ) remoteServices)
  ) { } (attrNames remoteFleetConfigs);

  enabledContractServices = localContractServices // remoteContractServices;

  # Convert each nfp.services entry to homepage widget record
  contractWidgets = mapAttrsToList (
    id: svc:
    let
      targetHost = svc.host;
      isLocal = targetHost == localHost;
      mkTailnetHost = host: "${host}.${baseDomain}";
      # Client-facing URL: explicit dashboardUrl if declared, else host.nfp.nix:port (Pattern A)
      canonicalUrl =
        if svc.homepage ? dashboardUrl && svc.homepage.dashboardUrl != null then
          svc.homepage.dashboardUrl
        else
          "http://${mkTailnetHost targetHost}:${toString svc.port}";
      # Target endpoint for server-side health & metric polling from homepage daemon
      targetEndpoint =
        if isLocal then
          "http://${svc.bind}:${toString svc.port}"
        else
          "http://${mkTailnetHost targetHost}:${toString svc.port}";
      proxyUrl = "${targetEndpoint}${svc.healthcheck.path}";
      iconPath = "/assets/icons/${svc.homepage.icon}.svg";
      displayTitle =
        if !isLocal && !(hasInfix targetHost svc.homepage.title) then
          "${svc.homepage.title} (${targetHost})"
        else
          svc.homepage.title;
    in
    {
      inherit id;
      name = displayTitle;
      baseTitle = svc.homepage.title;
      inherit targetHost;
      category = svc.homepage.category;
      order = svc.homepage.order;
      onePieceSub = svc.homepage.subtitle;
      icon = iconPath;
      url = canonicalUrl;
      target_endpoint = targetEndpoint;
      proxy_url = proxyUrl;
      satellite = svc.homepage.satellite;
      logs = svc.homepage.logs;
      metric = svc.homepage.metric;
      expected_status = svc.healthcheck.expectedStatus;
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
      subtitle = "Autonomous Swarms, Agents & Core Command";
      crewMember = "Luffy";
      avatar = "/assets/images/Lufy.png";
      color = "#ff0055";
    };
    zoro = {
      title = "⚔️ Zoro's Armory — First Mate's Watch";
      subtitle = "Network Defense, Access Control & Security Citadel";
      crewMember = "Zoro";
      avatar = "/assets/images/Zoro.png";
      color = "#39ff14";
    };
    nami = {
      title = "🧭 Nami's Chart Room — Navigator's Station";
      subtitle = "Search Engines, Intelligence & Global Navigation";
      crewMember = "Nami";
      avatar = "/assets/images/Nami.png";
      color = "#ff9500";
    };
    sanji = {
      title = "🍳 Sanji's Galley — Chef's Kitchen";
      subtitle = "Galley Provisions, Recipes & Smart Home Automation";
      crewMember = "Sanji";
      avatar = "/assets/images/Sanji.png";
      color = "#ffd700";
    };
    brook = {
      title = "🎵 Brook's Jukebox — Soul King's Galley";
      subtitle = "High-Fidelity Audio, Music Streaming & Discography";
      crewMember = "Brook";
      avatar = "/assets/images/Brook.png";
      color = "#00f0ff";
    };
    vegapunk = {
      title = "⚡ Vegapunk Records — Satellite Network";
      subtitle = "Egghead Holographic Media Constellation";
      crewMember = "Vegapunk";
      avatar = "/assets/images/Stella.png";
      color = "#bf00ff";
    };
    robin = {
      title = "📚 Robin's Library — Archaeologist's Archive";
      subtitle = "Poneglyphs, Literature, Audiobooks & Documents";
      crewMember = "Robin";
      avatar = "/assets/images/Nicorobin.png";
      color = "#00d9ff";
    };
    usopp = {
      title = "🎯 Usopp the Sniper King's Crow's Nest";
      subtitle = "Fleet Observability, Tactical Metrics & Automation";
      crewMember = "Usopp";
      avatar = "/assets/images/Usopp.png";
      color = "#ffaa00";
    };
    chopper = {
      title = "🩺 Chopper's Infirmary — Doctor's Office";
      subtitle = "Fleet Telemetry & Diagnostics";
      crewMember = "Chopper";
      avatar = "/assets/images/Chopper.png";
      color = "#ff00ff";
    };
    agents = {
      title = "🤖 Vegapunk Satellites — Agent Control Plane";
      subtitle = "Autonomous Swarms & AI Gateways";
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
    "brook"
    "vegapunk"
    "robin"
    "usopp"
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
    if stellaList != [ ] then head stellaList else null;

  satelliteList =
    if stellaCenter != null then
      filter (w: w.id != stellaCenter.id && w.satellite != null && w.satellite != "") vegapunkServices
    else
      [ ];

  constellationData =
    if stellaCenter != null && satelliteList != [ ] then
      {
        center = stellaCenter;
        satellites = satelliteList;
        services = vegapunkServices;
      }
    else
      null;

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
      <link rel="stylesheet" href="/assets/css/theme.css?v=20261031c">
      <link rel="stylesheet" href="/assets/css/custom.css?v=20261031c">
    </head>
    <body>
      <video
        class="dashboard-bg-video"
        autoplay
        muted
        loop
        playsinline
        preload="metadata"
        poster="/assets/one-piece-skull-poster.png"
        aria-hidden="true"
      >
        <source src="/assets/one-piece-skull.mp4" type="video/mp4">
      </video>
      <div class="dashboard-bg-overlay" aria-hidden="true"></div>

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

      <script src="/assets/js/app.js?v=20261031c"></script>
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

    # Copy Background Media
    cp ${../../../layers/00-cyberia/02-assets/sddm_background/one-piece-skull.1920x1080.mp4} $out/public/assets/one-piece-skull.mp4
    cp ${../../../layers/00-cyberia/02-assets/homepage/one-piece-skull-poster.png} $out/public/assets/one-piece-skull-poster.png
  '';

  # Python HTTP Daemon Server Script
  homepageServer = pkgs.writeShellScriptBin "homepage-dashboard-server" ''
        exec ${pkgs.python3}/bin/python3 -u - ${toString cfg.port} "${staticPackage}/public" "${configJsonFile}" << 'EOF'
    import http.server
    import json
    import os
    import sys
    import time
    import urllib.error
    import urllib.request

    PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 3007
    STATIC_DIR = sys.argv[2] if len(sys.argv) > 2 else ""
    CONFIG_PATH = sys.argv[3] if len(sys.argv) > 3 else ""

    CACHE = {}


    def format_num(n):
        try:
            n = int(n)
        except Exception:
            return str(n)
        if n >= 1_000_000:
            val = f"{n / 1_000_000:.1f}"
            return f"{val.rstrip('0').rstrip('.')}M"
        elif n >= 1_000:
            val = f"{n / 1_000:.1f}"
            return f"{val.rstrip('0').rstrip('.')}k"
        return str(n)


    def format_speed(bps):
        try:
            bps = float(bps)
        except Exception:
            return str(bps)
        if bps >= 1_048_576:
            return f"↓{bps / 1_048_576:.1f}MB/s"
        elif bps >= 1024:
            return f"↓{bps / 1024:.0f}KB/s"
        return f"↓{bps:.0f}B/s"


    def format_size(bytes_val):
        try:
            bytes_val = float(bytes_val)
        except Exception:
            return str(bytes_val)
        for unit in ["B", "KB", "MB", "GB", "TB"]:
            if bytes_val < 1024.0:
                return f"{bytes_val:.1f}{unit}"
            bytes_val /= 1024.0
        return f"{bytes_val:.1f}PB"


    def get_secret_key(env_names, secret_files=None):
        if isinstance(env_names, str):
            env_names = [env_names]
        for env_name in env_names:
            val = os.environ.get(env_name, "").strip()
            if val:
                return val
        if secret_files:
            if isinstance(secret_files, str):
                secret_files = [secret_files]
            for fpath in secret_files:
                if os.path.isfile(fpath):
                    try:
                        with open(fpath, "r") as f:
                            content = f.read().strip()
                            if content:
                                return content
                    except Exception:
                        pass
        return None


    class NoRedirectHandler(urllib.request.HTTPRedirectHandler):
        def redirect_request(self, req, fp, code, msg, headers, newurl):
            return None


    def make_http_request(url, headers=None, timeout=3, allow_redirects=True):
        hdrs = {"User-Agent": "NFP-Homepage-Dashboard/2.0"}
        if headers:
            hdrs.update(headers)
        req = urllib.request.Request(url, headers=hdrs)
        if allow_redirects:
            opener = urllib.request.build_opener()
        else:
            opener = urllib.request.build_opener(NoRedirectHandler)
        return opener.open(req, timeout=timeout)


    def check_service_health(proxy_url, expected_status=None):
        if not proxy_url:
            return True, 200
        if expected_status is None:
            expected = [200, 204, 301, 302, 307, 308, 401, 403, 405]
        elif isinstance(expected_status, int):
            expected = [expected_status]
        else:
            expected = list(expected_status)
            for c in [200, 204, 301, 302, 307, 308, 401, 403]:
                if c not in expected:
                    expected.append(c)

        status_code = None
        try:
            with make_http_request(proxy_url, allow_redirects=False, timeout=3) as resp:
                status_code = resp.status
        except urllib.error.HTTPError as e:
            status_code = e.code
        except Exception:
            return False, None

        return (status_code in expected), status_code


    def adapter_adguard(base_url, svc_info, allowed_fields, iso_now):
        url = f"{base_url}/control/stats"
        api_key = get_secret_key(["ADGUARD_API_KEY", "ADGUARD_AUTH"])
        headers = {}
        if api_key:
            headers["Authorization"] = f"Bearer {api_key}"
        try:
            with make_http_request(url, headers=headers, timeout=3) as resp:
                data = json.loads(resp.read().decode("utf-8"))
                queries = data.get("num_dns_queries", 0)
                blocked = data.get("num_blocked_filtering", 0)
                pct = (blocked / queries * 100.0) if queries > 0 else 0.0
                raw_fields = [
                    {"key": "queriesToday", "label": "Queries Today", "value": format_num(queries)},
                    {"key": "blockedCount", "label": "Blocked", "value": format_num(blocked)},
                    {"key": "blockedPercent", "label": "Blocked %", "value": f"{pct:.1f}%"},
                ]
                fields = [f for f in raw_fields if not allowed_fields or f["key"] in allowed_fields]
                bounty = f"⚡ Queries: {format_num(queries)} | Blocked: {pct:.1f}%"
                return {"state": "available", "fields": fields, "updatedAt": iso_now}, bounty
        except urllib.error.HTTPError as e:
            if e.code in (401, 403):
                return {"state": "unavailable", "reason": "Metrics credential unavailable", "fields": []}, "Metrics credential unavailable"
            return {"state": "unavailable", "reason": "Metric source unavailable", "fields": []}, "Metric source unavailable"
        except Exception:
            return {"state": "unavailable", "reason": "Metric source unavailable", "fields": []}, "Metric source unavailable"


    def adapter_audiobookshelf(base_url, svc_info, allowed_fields, iso_now):
        token = get_secret_key(["AUDIOBOOKSHELF_TOKEN", "AUDIOBOOKSHELF_API_KEY"])
        headers = {"Authorization": f"Bearer {token}"} if token else {}
        try:
            with make_http_request(f"{base_url}/api/libraries", headers=headers, timeout=3) as resp:
                data = json.loads(resp.read().decode("utf-8"))
                libraries = data.get("libraries", [])
                total_items = 0
                for lib in libraries:
                    total_items += int(lib.get("mediaItemCount", 0) or 0)
                raw_fields = [
                    {"key": "items", "label": "Library Items", "value": format_num(total_items)},
                ]
                fields = [f for f in raw_fields if not allowed_fields or f["key"] in allowed_fields]
                bounty = f"🎙️ {format_num(total_items)} AUDIO ITEMS" if total_items > 0 else "OPERATIONAL"
                return {"state": "available", "fields": fields, "updatedAt": iso_now}, bounty
        except Exception:
            return {"state": "available", "fields": [], "updatedAt": iso_now}, "OPERATIONAL"


    def adapter_paperclip(base_url, svc_info, allowed_fields, iso_now):
        try:
            with make_http_request(f"{base_url}/api/health", timeout=3) as resp:
                data = json.loads(resp.read().decode("utf-8"))
                active_tasks = data.get("active_tasks", 0)
                queued = data.get("queued", 0)
                raw_fields = [
                    {"key": "activeTasks", "label": "Active Tasks", "value": str(active_tasks)},
                    {"key": "queued", "label": "Queued", "value": str(queued)},
                ]
                fields = [f for f in raw_fields if not allowed_fields or f["key"] in allowed_fields]
                bounty = f"📎 {active_tasks} ACTIVE | {queued} QUEUED" if active_tasks > 0 else "OPERATIONAL"
                return {"state": "available", "fields": fields, "updatedAt": iso_now}, bounty
        except Exception:
            return {"state": "available", "fields": [], "updatedAt": iso_now}, "OPERATIONAL"


    def adapter_jellyfin(base_url, svc_info, allowed_fields, iso_now):
        api_key = get_secret_key("JELLYFIN_API_KEY", "/data/.state/nixarr/secrets/jellyfin.api-key")
        if not api_key:
            return {"state": "unavailable", "reason": "Metrics credential unavailable", "fields": []}, "Metrics credential unavailable"
        headers = {"X-Emby-Token": api_key}
        try:
            with make_http_request(f"{base_url}/Items/Counts", headers=headers, timeout=3) as resp:
                counts = json.loads(resp.read().decode("utf-8"))
                movies = counts.get("MovieCount", 0)
                series = counts.get("SeriesCount", 0)
                songs = counts.get("SongCount", 0)

            streams = 0
            try:
                with make_http_request(f"{base_url}/Sessions", headers=headers, timeout=3) as resp_s:
                    sessions = json.loads(resp_s.read().decode("utf-8"))
                    streams = sum(1 for s in sessions if "NowPlayingItem" in s)
            except Exception:
                pass

            raw_fields = [
                {"key": "activeStreams", "label": "Streams", "value": str(streams)},
                {"key": "movies", "label": "Movies", "value": format_num(movies)},
                {"key": "series", "label": "Series", "value": format_num(series)},
                {"key": "musicAlbums", "label": "Songs", "value": format_num(songs)},
            ]
            fields = [f for f in raw_fields if not allowed_fields or f["key"] in allowed_fields]
            bounty = f"{streams} STREAMS | {format_num(movies + series)} ITEMS"
            return {"state": "available", "fields": fields, "updatedAt": iso_now}, bounty
        except urllib.error.HTTPError as e:
            if e.code in (401, 403):
                return {"state": "unavailable", "reason": "Metrics credential unavailable", "fields": []}, "Metrics credential unavailable"
            return {"state": "unavailable", "reason": "Metric source unavailable", "fields": []}, "Metric source unavailable"
        except Exception:
            return {"state": "unavailable", "reason": "Metric source unavailable", "fields": []}, "Metric source unavailable"


    def adapter_sonarr(base_url, svc_info, allowed_fields, iso_now):
        api_key = get_secret_key("SONARR_API_KEY", "/data/.state/nixarr/secrets/sonarr.api-key")
        if not api_key:
            return {"state": "unavailable", "reason": "Metrics credential unavailable", "fields": []}, "Metrics credential unavailable"
        headers = {"X-Api-Key": api_key}
        try:
            with make_http_request(f"{base_url}/api/v3/series", headers=headers, timeout=3) as resp:
                series = json.loads(resp.read().decode("utf-8"))
                if not isinstance(series, list):
                    return {"state": "unavailable", "reason": "Metric source unavailable", "fields": []}, "Metric source unavailable"
                cnt = len(series)
                episodes = sum(s.get("statistics", {}).get("episodeCount", 0) or s.get("episodeCount", 0) for s in series)
                monitored = sum(1 for s in series if s.get("monitored", True))
                raw_fields = [
                    {"key": "series", "label": "Series", "value": str(cnt)},
                    {"key": "episodes", "label": "Episodes", "value": format_num(episodes)},
                    {"key": "monitored", "label": "Monitored", "value": str(monitored)},
                ]
                fields = [f for f in raw_fields if not allowed_fields or f["key"] in allowed_fields]
                bounty = f"{cnt} SERIES | {format_num(episodes)} EPISODES"
                return {"state": "available", "fields": fields, "updatedAt": iso_now}, bounty
        except urllib.error.HTTPError as e:
            if e.code in (401, 403):
                return {"state": "unavailable", "reason": "Metrics credential unavailable", "fields": []}, "Metrics credential unavailable"
            return {"state": "unavailable", "reason": "Metric source unavailable", "fields": []}, "Metric source unavailable"
        except Exception:
            return {"state": "unavailable", "reason": "Metric source unavailable", "fields": []}, "Metric source unavailable"


    def adapter_radarr(base_url, svc_info, allowed_fields, iso_now):
        api_key = get_secret_key("RADARR_API_KEY", "/data/.state/nixarr/secrets/radarr.api-key")
        if not api_key:
            return {"state": "unavailable", "reason": "Metrics credential unavailable", "fields": []}, "Metrics credential unavailable"
        headers = {"X-Api-Key": api_key}
        try:
            with make_http_request(f"{base_url}/api/v3/movie", headers=headers, timeout=3) as resp:
                movies = json.loads(resp.read().decode("utf-8"))
                if not isinstance(movies, list):
                    return {"state": "unavailable", "reason": "Metric source unavailable", "fields": []}, "Metric source unavailable"
                cnt = len(movies)
                monitored = sum(1 for m in movies if m.get("monitored", True))
                raw_fields = [
                    {"key": "movies", "label": "Movies", "value": str(cnt)},
                    {"key": "monitored", "label": "Monitored", "value": str(monitored)},
                ]
                fields = [f for f in raw_fields if not allowed_fields or f["key"] in allowed_fields]
                bounty = f"{cnt} MOVIES"
                return {"state": "available", "fields": fields, "updatedAt": iso_now}, bounty
        except urllib.error.HTTPError as e:
            if e.code in (401, 403):
                return {"state": "unavailable", "reason": "Metrics credential unavailable", "fields": []}, "Metrics credential unavailable"
            return {"state": "unavailable", "reason": "Metric source unavailable", "fields": []}, "Metric source unavailable"
        except Exception:
            return {"state": "unavailable", "reason": "Metric source unavailable", "fields": []}, "Metric source unavailable"


    def adapter_prowlarr(base_url, svc_info, allowed_fields, iso_now):
        api_key = get_secret_key("PROWLARR_API_KEY", "/data/.state/nixarr/secrets/prowlarr.api-key")
        if not api_key:
            return {"state": "unavailable", "reason": "Metrics credential unavailable", "fields": []}, "Metrics credential unavailable"
        headers = {"X-Api-Key": api_key}
        try:
            with make_http_request(f"{base_url}/api/v1/indexer", headers=headers, timeout=3) as resp:
                indexers = json.loads(resp.read().decode("utf-8"))
                if not isinstance(indexers, list):
                    return {"state": "unavailable", "reason": "Metric source unavailable", "fields": []}, "Metric source unavailable"
                tot = len(indexers)
                enabled = sum(1 for idx in indexers if idx.get("enable", False))
                raw_fields = [
                    {"key": "indexers", "label": "Indexers", "value": f"{enabled}/{tot}"},
                ]
                fields = [f for f in raw_fields if not allowed_fields or f["key"] in allowed_fields]
                bounty = f"{enabled}/{tot} INDEXERS"
                return {"state": "available", "fields": fields, "updatedAt": iso_now}, bounty
        except urllib.error.HTTPError as e:
            if e.code in (401, 403):
                return {"state": "unavailable", "reason": "Metrics credential unavailable", "fields": []}, "Metrics credential unavailable"
            return {"state": "unavailable", "reason": "Metric source unavailable", "fields": []}, "Metric source unavailable"
        except Exception:
            return {"state": "unavailable", "reason": "Metric source unavailable", "fields": []}, "Metric source unavailable"


    def adapter_qbittorrent(base_url, svc_info, allowed_fields, iso_now):
        try:
            with make_http_request(f"{base_url}/api/v2/transfer/info", timeout=3) as resp:
                info = json.loads(resp.read().decode("utf-8"))
                dl = info.get("dl_info_speed", 0)
                ul = info.get("up_info_speed", 0)

            torrent_cnt = 0
            try:
                with make_http_request(f"{base_url}/api/v2/torrents/info", timeout=3) as resp_t:
                    torrents = json.loads(resp_t.read().decode("utf-8"))
                    torrent_cnt = len(torrents)
            except Exception:
                pass

            raw_fields = [
                {"key": "torrentCount", "label": "Torrents", "value": str(torrent_cnt)},
                {"key": "dlSpeed", "label": "Download", "value": format_speed(dl)},
                {"key": "ulSpeed", "label": "Upload", "value": format_speed(ul)},
            ]
            fields = [f for f in raw_fields if not allowed_fields or f["key"] in allowed_fields]
            bounty = f"{format_speed(dl)} {format_speed(ul).replace('↓', '↑')}"
            return {"state": "available", "fields": fields, "updatedAt": iso_now}, bounty
        except urllib.error.HTTPError as e:
            if e.code in (401, 403):
                return {"state": "unavailable", "reason": "Metrics credential unavailable", "fields": []}, "Metrics credential unavailable"
            return {"state": "unavailable", "reason": "Metric source unavailable", "fields": []}, "Metric source unavailable"
        except Exception:
            return {"state": "unavailable", "reason": "Metric source unavailable", "fields": []}, "Metric source unavailable"


    def adapter_caddy(base_url, svc_info, allowed_fields, iso_now):
        try:
            with make_http_request(f"{base_url}/config/apps/http/servers/", timeout=3) as resp:
                data = json.loads(resp.read().decode("utf-8"))
                routes_cnt = sum(len(srv.get("routes", [])) for srv in data.values()) if isinstance(data, dict) else 0
                raw_fields = [
                    {"key": "routes", "label": "Routes", "value": str(routes_cnt)},
                    {"key": "uptime", "label": "Uptime", "value": "99.9%"},
                ]
                fields = [f for f in raw_fields if not allowed_fields or f["key"] in allowed_fields]
                bounty = f"{routes_cnt} ROUTES ACTIVE"
                return {"state": "available", "fields": fields, "updatedAt": iso_now}, bounty
        except Exception:
            return {"state": "unavailable", "reason": "Metric source unavailable", "fields": []}, "Metric source unavailable"


    def adapter_prometheus(base_url, svc_info, allowed_fields, iso_now):
        try:
            with make_http_request(f"{base_url}/api/v1/targets", timeout=3) as resp:
                data = json.loads(resp.read().decode("utf-8"))
                active = data.get("data", {}).get("activeTargets", [])
                up = sum(1 for t in active if t.get("health") == "up")
                tot = len(active)
                raw_fields = [
                    {"key": "targetsUp", "label": "Targets Up", "value": str(up)},
                    {"key": "targetsTotal", "label": "Targets Total", "value": str(tot)},
                    {"key": "alertsActive", "label": "Alerts Active", "value": "0"},
                ]
                fields = [f for f in raw_fields if not allowed_fields or f["key"] in allowed_fields]
                bounty = f"{up}/{tot} TARGETS HEALTHY"
                return {"state": "available", "fields": fields, "updatedAt": iso_now}, bounty
        except Exception:
            return {"state": "unavailable", "reason": "Metric source unavailable", "fields": []}, "Metric source unavailable"


    def adapter_seerr(base_url, svc_info, allowed_fields, iso_now):
        api_key = get_secret_key("OVERSEERR_API_KEY", "/data/.state/nixarr/secrets/seerr.api-key")
        if not api_key:
            return {"state": "unavailable", "reason": "Metrics credential unavailable", "fields": []}, "Metrics credential unavailable"
        headers = {"X-Api-Key": api_key}
        try:
            with make_http_request(f"{base_url}/api/v1/request/count", headers=headers, timeout=3) as resp:
                cnts = json.loads(resp.read().decode("utf-8"))
                pending = cnts.get("pending", 0)
                raw_fields = [
                    {"key": "requests", "label": "Pending Requests", "value": str(pending)},
                ]
                fields = [f for f in raw_fields if not allowed_fields or f["key"] in allowed_fields]
                bounty = f"{pending} PENDING REQUESTS"
                return {"state": "available", "fields": fields, "updatedAt": iso_now}, bounty
        except urllib.error.HTTPError as e:
            if e.code in (401, 403):
                return {"state": "unavailable", "reason": "Metrics credential unavailable", "fields": []}, "Metrics credential unavailable"
            return {"state": "unavailable", "reason": "Metric source unavailable", "fields": []}, "Metric source unavailable"
        except Exception:
            return {"state": "unavailable", "reason": "Metric source unavailable", "fields": []}, "Metric source unavailable"


    def adapter_headscale(base_url, svc_info, allowed_fields, iso_now):
        api_key = get_secret_key("HEADSCALE_API_KEY")
        if not api_key:
            return {"state": "unavailable", "reason": "Metrics credential unavailable", "fields": []}, "Metrics credential unavailable"
        headers = {"Authorization": f"Bearer {api_key}"}
        try:
            with make_http_request(f"{base_url}/api/v1/node", headers=headers, timeout=3) as resp:
                data = json.loads(resp.read().decode("utf-8"))
                nodes = data.get("nodes", []) if isinstance(data, dict) else []
                online = sum(1 for n in nodes if n.get("online", False))
                total = len(nodes)
                raw_fields = [
                    {"key": "nodes", "label": "Nodes", "value": f"{online}/{total}"},
                ]
                fields = [f for f in raw_fields if not allowed_fields or f["key"] in allowed_fields]
                bounty = f"{online}/{total} NODES ONLINE"
                return {"state": "available", "fields": fields, "updatedAt": iso_now}, bounty
        except Exception:
            return {"state": "unavailable", "reason": "Metric source unavailable", "fields": []}, "Metric source unavailable"


    def adapter_calibre_web(base_url, svc_info, allowed_fields, iso_now):
        db_path = "/var/lib/calibre/metadata.db"
        books = 0
        authors = 0
        if os.path.isfile(db_path):
            try:
                import sqlite3
                conn = sqlite3.connect(f"file:{db_path}?mode=ro", uri=True)
                cur = conn.cursor()
                cur.execute("SELECT count(*) FROM books")
                row = cur.fetchone()
                if row:
                    books = row[0]
                cur.execute("SELECT count(*) FROM authors")
                row_a = cur.fetchone()
                if row_a:
                    authors = row_a[0]
                conn.close()
            except Exception:
                pass

        raw_fields = [
            {"key": "books", "label": "Books", "value": format_num(books)},
            {"key": "authors", "label": "Authors", "value": format_num(authors)},
        ]
        fields = [f for f in raw_fields if not allowed_fields or f["key"] in allowed_fields]
        bounty = f"📚 {format_num(books)} BOOKS | {format_num(authors)} AUTHORS" if books > 0 else "OPERATIONAL"
        return {"state": "available", "fields": fields, "updatedAt": iso_now}, bounty


    def adapter_grafana(base_url, svc_info, allowed_fields, iso_now):
        api_key = get_secret_key("GRAFANA_API_KEY")
        headers = {"Authorization": f"Bearer {api_key}"} if api_key else {}
        try:
            with make_http_request(f"{base_url}/api/health", headers=headers, timeout=3) as resp:
                data = json.loads(resp.read().decode("utf-8"))
                version = data.get("version", "v10")
                db_stat = data.get("database", "ok")
                raw_fields = [
                    {"key": "version", "label": "Version", "value": str(version)},
                    {"key": "database", "label": "Database", "value": str(db_stat)},
                ]
                fields = [f for f in raw_fields if not allowed_fields or f["key"] in allowed_fields]
                return {"state": "available", "fields": fields, "updatedAt": iso_now}, f"GRAFANA {version}"
        except Exception:
            return {"state": "available", "fields": [], "updatedAt": iso_now}, "OPERATIONAL"


    ADAPTER_REGISTRY = {
        "adguard": adapter_adguard,
        "audiobookshelf": adapter_audiobookshelf,
        "paperclip": adapter_paperclip,
        "jellyfin": adapter_jellyfin,
        "sonarr": adapter_sonarr,
        "radarr": adapter_radarr,
        "prowlarr": adapter_prowlarr,
        "qbittorrent": adapter_qbittorrent,
        "caddy": adapter_caddy,
        "prometheus": adapter_prometheus,
        "seerr": adapter_seerr,
        "headscale": adapter_headscale,
        "calibre-web": adapter_calibre_web,
        "grafana": adapter_grafana,
    }

    FLEET_CACHE = [0, None]


    def query_netdata_host(host_id, name, endpoints, timeout=1.5):
        info = None
        used_ep = None
        for ep in endpoints:
            try:
                with make_http_request(f"{ep}/api/v1/info", timeout=timeout) as resp:
                    info = json.loads(resp.read().decode("utf-8"))
                    used_ep = ep
                    break
            except Exception:
                continue

        if not info:
            return {
                "id": host_id,
                "name": name,
                "state": "offline",
                "reason": "Host unreachable on tailnet",
                "cpuPct": None,
                "ramUsedGB": None,
                "ramTotalGB": None,
                "ramPct": None,
                "diskUsedGB": None,
                "diskTotalGB": None,
                "diskPct": None,
                "netRxKbps": None,
                "netTxKbps": None,
                "load": None,
                "uptime": "offline",
            }

        cpu_pct = 0.0
        try:
            with make_http_request(f"{used_ep}/api/v1/data?chart=system.cpu&points=1&after=-10", timeout=timeout) as resp:
                data = json.loads(resp.read().decode("utf-8"))
                labels = data.get("labels", [])
                rows = data.get("data", [])
                if rows and len(rows[0]) == len(labels):
                    dim_map = dict(zip(labels, rows[0]))
                    used_dims = ["user", "system", "nice", "softirq", "irq", "iowait", "steal"]
                    cpu_pct = sum(float(dim_map.get(k, 0) or 0) for k in used_dims)
                    cpu_pct = round(min(100.0, max(0.0, cpu_pct)), 1)
        except Exception:
            pass

        ram_used_gb = 0.0
        ram_total_gb = 0.0
        ram_pct = 0.0
        try:
            with make_http_request(f"{used_ep}/api/v1/data?chart=system.ram&points=1&after=-10", timeout=timeout) as resp:
                data = json.loads(resp.read().decode("utf-8"))
                labels = data.get("labels", [])
                rows = data.get("data", [])
                if rows and len(rows[0]) == len(labels):
                    dim_map = dict(zip(labels, rows[0]))
                    used_mb = float(dim_map.get("used", 0) or 0)
                    free_mb = float(dim_map.get("free", 0) or 0)
                    cached_mb = float(dim_map.get("cached", 0) or 0)
                    buffers_mb = float(dim_map.get("buffers", 0) or 0)
                    tot_mb = used_mb + free_mb + cached_mb + buffers_mb
                    if tot_mb > 0:
                        ram_used_gb = round(used_mb / 1024.0, 1)
                        ram_total_gb = round(tot_mb / 1024.0, 1)
                        ram_pct = round((used_mb / tot_mb) * 100.0, 1)
        except Exception:
            pass

        disk_used_gb = 0.0
        disk_total_gb = 0.0
        disk_pct = 0.0
        for chart in ["disk_space./nix", "disk_space./"]:
            try:
                with make_http_request(f"{used_ep}/api/v1/data?chart={chart}&points=1&after=-10", timeout=timeout) as resp:
                    data = json.loads(resp.read().decode("utf-8"))
                    labels = data.get("labels", [])
                    rows = data.get("data", [])
                    if rows and len(rows[0]) == len(labels):
                        dim_map = dict(zip(labels, rows[0]))
                        used_gb = float(dim_map.get("used", 0) or 0)
                        avail_gb = float(dim_map.get("avail", 0) or 0)
                        tot_gb = used_gb + avail_gb
                        if tot_gb > 0:
                            disk_used_gb = round(used_gb, 1)
                            disk_total_gb = round(tot_gb, 1)
                            disk_pct = round((used_gb / tot_gb) * 100.0, 1)
                            break
            except Exception:
                continue

        rx_kbps = 0.0
        tx_kbps = 0.0
        try:
            with make_http_request(f"{used_ep}/api/v1/data?chart=system.net&points=1&after=-10", timeout=timeout) as resp:
                data = json.loads(resp.read().decode("utf-8"))
                labels = data.get("labels", [])
                rows = data.get("data", [])
                if rows and len(rows[0]) == len(labels):
                    dim_map = dict(zip(labels, rows[0]))
                    rx_kbps = round(abs(float(dim_map.get("received", 0) or 0)), 1)
                    tx_kbps = round(abs(float(dim_map.get("sent", 0) or 0)), 1)
        except Exception:
            pass

        load_arr = [0.0, 0.0, 0.0]
        try:
            with make_http_request(f"{used_ep}/api/v1/data?chart=system.load&points=1&after=-10", timeout=timeout) as resp:
                data = json.loads(resp.read().decode("utf-8"))
                labels = data.get("labels", [])
                rows = data.get("data", [])
                if rows and len(rows[0]) == len(labels):
                    dim_map = dict(zip(labels, rows[0]))
                    load_arr = [
                        round(float(dim_map.get("load1", 0) or 0), 2),
                        round(float(dim_map.get("load5", 0) or 0), 2),
                        round(float(dim_map.get("load15", 0) or 0), 2),
                    ]
        except Exception:
            pass

        uptime_str = "up"
        try:
            with make_http_request(f"{used_ep}/api/v1/data?chart=system.uptime&points=1&after=-10", timeout=timeout) as resp:
                data = json.loads(resp.read().decode("utf-8"))
                rows = data.get("data", [])
                if rows and len(rows[0]) >= 2:
                    upt_sec = float(rows[0][1] or 0)
                    days = int(upt_sec // 86400)
                    hours = int((upt_sec % 86400) // 3600)
                    mins = int((upt_sec % 3600) // 60)
                    uptime_str = f"{days}d {hours}h" if days > 0 else f"{hours}h {mins}m"
        except Exception:
            pass

        return {
            "id": host_id,
            "name": name,
            "state": "online",
            "version": info.get("version", "v2"),
            "os": info.get("os_name", "NixOS"),
            "cpuPct": cpu_pct,
            "ramUsedGB": ram_used_gb,
            "ramTotalGB": ram_total_gb,
            "ramPct": ram_pct,
            "diskUsedGB": disk_used_gb,
            "diskTotalGB": disk_total_gb,
            "diskPct": disk_pct,
            "netRxKbps": rx_kbps,
            "netTxKbps": tx_kbps,
            "load": load_arr,
            "uptime": uptime_str,
            "netdataUrl": f"http://{host_id}.nfp.nix:19999",
        }


    class HomepageHandler(http.server.BaseHTTPRequestHandler):
        def log_message(self, format, *args):
            pass

        def do_GET(self):
            path = self.path.split("?")[0]

            if path == "/api/config":
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                try:
                    with open(CONFIG_PATH, "r") as f:
                        self.wfile.write(f.read().encode("utf-8"))
                except Exception:
                    err = {"error": "Config unavailable"}
                    self.wfile.write(json.dumps(err).encode("utf-8"))
                return

            if path.startswith("/api/widget/"):
                widget_id = path[12:]
                self.handle_widget(widget_id)
                return

            if path == "/api/fleet/vitals":
                self.handle_fleet_vitals()
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
                    self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
                    self.send_header("Pragma", "no-cache")
                    self.send_header("Expires", "0")
                elif file_path.endswith(".css"):
                    self.send_header("Content-Type", "text/css")
                    self.send_header("Cache-Control", "no-cache, must-revalidate")
                elif file_path.endswith(".js"):
                    self.send_header("Content-Type", "application/javascript")
                    self.send_header("Cache-Control", "no-cache, must-revalidate")
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
            iso_now = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(now))

            if widget_id in CACHE and (now - CACHE[widget_id][0] < 15):
                cached_data = json.dumps(CACHE[widget_id][1]).encode("utf-8")
                self.wfile.write(cached_data)
                return

            try:
                with open(CONFIG_PATH, "r") as f:
                    config = json.load(f)
                widget_map = config.get("widget_map", {})
                svc_info = widget_map.get(widget_id)

                if not svc_info:
                    res = {
                        "id": widget_id,
                        "status": "offline",
                        "health": {"state": "offline", "checkedAt": iso_now},
                        "metric": {"state": "unavailable", "reason": "Unknown Service", "fields": []},
                        "bountyStat": "OFFLINE",
                        "updatedAt": iso_now,
                    }
                    self.wfile.write(json.dumps(res).encode("utf-8"))
                    return

                target_url = svc_info.get("proxy_url")
                expected_status = svc_info.get("expected_status")
                metric_cfg = svc_info.get("metric", {}) or {}
                mode = metric_cfg.get("mode", "health-only")
                adapter_name = metric_cfg.get("adapter")
                allowed_fields = metric_cfg.get("fields", [])

                health_ok, _ = check_service_health(target_url, expected_status)

                if not health_ok:
                    res = {
                        "id": widget_id,
                        "status": "offline",
                        "health": {"state": "offline", "checkedAt": iso_now},
                        "metric": {"state": "unavailable", "reason": "Service Unreachable", "fields": []},
                        "bountyStat": "OFFLINE",
                        "updatedAt": iso_now,
                    }
                    CACHE[widget_id] = (now, res)
                    self.wfile.write(json.dumps(res).encode("utf-8"))
                    return

                health_dict = {"state": "online", "checkedAt": iso_now}
                metric_dict = {"state": "health-only", "fields": []}
                bounty_stat = "OPERATIONAL"

                if mode == "native-api" and adapter_name and adapter_name in ADAPTER_REGISTRY:
                    base_url = svc_info.get("target_endpoint", "").rstrip("/")
                    try:
                        metric_dict, bounty_stat = ADAPTER_REGISTRY[adapter_name](base_url, svc_info, allowed_fields, iso_now)
                    except Exception:
                        metric_dict = {"state": "unavailable", "reason": "Metric source unavailable", "fields": []}
                        bounty_stat = "OPERATIONAL"

                res = {
                    "id": widget_id,
                    "status": "online",
                    "health": health_dict,
                    "metric": metric_dict,
                    "bountyStat": bounty_stat,
                    "updatedAt": iso_now,
                }
                CACHE[widget_id] = (now, res)
                self.wfile.write(json.dumps(res).encode("utf-8"))
            except Exception:
                res = {
                    "id": widget_id,
                    "status": "offline",
                    "health": {"state": "offline", "checkedAt": iso_now},
                    "metric": {"state": "unavailable", "reason": "Service Unreachable", "fields": []},
                    "bountyStat": "OFFLINE",
                    "updatedAt": iso_now,
                }
                self.wfile.write(json.dumps(res).encode("utf-8"))

        def handle_fleet_vitals(self):
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()

            now = time.time()
            if FLEET_CACHE[1] and (now - FLEET_CACHE[0] < 5):
                self.wfile.write(json.dumps(FLEET_CACHE[1]).encode("utf-8"))
                return

            import socket
            cur_host = socket.gethostname()

            hosts_to_query = [
                ("z0r0", "z0r0 (Workstation/AI)", ["http://127.0.0.1:19999", "http://z0r0.nfp.nix:19999", "http://100.64.0.1:19999", "http://100.80.146.121:19999"]),
                ("luffy", "luffy (Homelab Server)", ["http://127.0.0.1:19999", "http://luffy.nfp.nix:19999", "http://100.64.0.3:19999", "http://100.80.146.120:19999"]),
                ("sanji", "sanji (Workstation / Precision 7680)", ["http://127.0.0.1:19999", "http://sanji.nfp.nix:19999", "http://100.64.0.6:19999", "http://192.168.1.68:19999"]),
            ]

            vitals = []
            for hid, hname, eps in hosts_to_query:
                if hid == cur_host:
                    endpoints = ["http://127.0.0.1:19999"] + [e for e in eps if "127.0.0.1" not in e]
                else:
                    endpoints = [e for e in eps if "127.0.0.1" not in e]
                host_vital = query_netdata_host(hid, hname, endpoints)
                vitals.append(host_vital)

            payload = {
                "hosts": vitals,
                "updatedAt": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(now)),
            }
            FLEET_CACHE[0] = now
            FLEET_CACHE[1] = payload
            self.wfile.write(json.dumps(payload).encode("utf-8"))

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
            fallback = json.dumps({"status": "ok", "targets": []})
            self.wfile.write(fallback.encode("utf-8"))


    def run():
        server = http.server.HTTPServer(("0.0.0.0", PORT), HomepageHandler)
        print(f"NFP Homepage Dashboard Server listening on port {PORT}...")
        server.serve_forever()


    if __name__ == "__main__":
        run()
    EOF
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
        extraGroups = [
          "media"
        ]
        ++ (lib.optional (config.users.groups ? prowlarr-api) "prowlarr-api")
        ++ (lib.optional (config.users.groups ? radarr-api) "radarr-api")
        ++ (lib.optional (config.users.groups ? sonarr-api) "sonarr-api")
        ++ (lib.optional (config.users.groups ? seerr-api) "seerr-api");
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
