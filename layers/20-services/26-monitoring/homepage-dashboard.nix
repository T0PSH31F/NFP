{ config, lib, ... }:

with lib;

let
  cfg = config.layers.layer-20.services.config.homepage-dashboard;
  hostName = config.networking.hostName or "unknown";
  hasEnv = cfg.environmentFile != null;

  # Custom CSS for gradient effects & strict card height stabilization to prevent error ballooning
  gradientCSS = ''
    .greeting-text {
      background: linear-gradient(135deg, #667eea, #764ba2, #f093fb);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      background-clip: text;
      font-weight: bold;
    }
    .datetime-widget [class*="text-xl"] {
      background: linear-gradient(135deg, #667eea, #764ba2);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      background-clip: text;
    }

    /* Card Height & Layout Stabilization — Prevents ballooning on error */
    .service-card, .card, div[class*="card"] {
      max-height: 180px !important;
      overflow: hidden !important;
      contain: content !important;
    }

    /* Status dot & ping indicator height cap fix */
    .service-ping, .service-status, .ping-dot, .status-dot, .service-status-dot, [class*="ping-"], [class*="status-"] {
      max-height: 1.5rem !important;
      max-width: 1.5rem !important;
      overflow: hidden !important;
    }

    /* Compact API error pill styling */
    .service-widget-error, .widget-error, [class*="widget-error"], [class*="Error"] {
      max-height: 24px !important;
      overflow: hidden !important;
      padding: 2px 6px !important;
      font-size: 0.7rem !important;
      background: rgba(239, 68, 68, 0.12) !important;
      border: 1px solid rgba(239, 68, 68, 0.25) !important;
      border-radius: 4px !important;
      color: #fca5a5 !important;
    }

    .service-widget-error *, .widget-error * {
      font-size: 0.7rem !important;
      white-space: nowrap !important;
      text-overflow: ellipsis !important;
      overflow: hidden !important;
      margin: 0 !important;
    }

    /* Prevent giant background decorative circles from overflowing cards */
    div[class*="rounded-full"] {
      max-width: 100% !important;
      max-height: 100% !important;
      opacity: 0.15 !important;
    }
  '';

  # ---------------------------------------------------------------------------
  # Address constants — mDNS / Tailscale hostnames for multi-device LAN access
  # ---------------------------------------------------------------------------
  # ---------------------------------------------------------------------------
  # Address constants — mDNS / Tailscale hostnames for multi-device LAN access
  # ---------------------------------------------------------------------------
  z0r0 = "z0r0.local";
  luffy = "luffy.local";
  nami = "nami.local";

  # The "other" machine — for glances remote stats widget
  remoteMachine = if hostName == "z0r0" then "luffy" else "z0r0";
  remoteIP = if hostName == "z0r0" then luffy else z0r0;

  ports = {
    # z0r0
    prometheus = 9090;
    loki = 3100;
    grafana = 3008;
    adguard = 3002;
    sillytavern = 8000;
    langfuse = 3005;
    brainService = 8010;
    llamaCpp = 8081;
    signalCli = 8080;
    hermesWorkspace = 3000;
    hermesDashboard = 9119;
    hermesWebui = 8788;
    aionUi = 3006;
    glances = 61208;

    # nami — cloud control plane
    headscale = 8086;
    paperclip = 3101;
    missionControl = 3099;
    kongGateway = 8090;
    omniroute = 20129;
    gno = 3456;

    # luffy — media
    jellyfin = 8096;
    sonarr = 8989;
    radarr = 7878;
    lidarr = 8686;
    readarr = 8787;
    prowlarr = 9696;
    bazarr = 6767;
    qbittorrent = 8095;
    aria2 = 6800;
    calibreWeb = 8093;
    yourSpotify = 3457;
    kavita = 5050;
    komga = 25600;

    # luffy — ai
    ollama = 11434;
    openWebui = 8088;
    jan = 1337;
    maxkb = 32784;
    simStudio = 32790;
    postgres = 5432;

    # luffy — infra
    vaultwarden = 8222;
    searxng = 8888;
    filebrowser = 8089;
    spacedrive = 32768;
    karakeep = 3007;

    # luffy — comms
    matrixSynapse = 8008;
    elementWeb = 8444;
    mautrixWhatsapp = 29317;
    mautrixSignal = 29318;
    rustdeskSignal = 21116;

    # luffy — automation
    n8n = 5678;
    homeAssistant = 8123;
    crawl4ai = 32775;
    skyvernUi = 32776;
    skyvernApi = 32779;

    # luffy — reverse proxy
    caddyAdmin = 2019;

    # luffy — new services
    opencompany = 5680;

    # z0r0 — AI routers & control plane
    freellmpool = 8082;
    freellmapi = 3003;
    mistralMcp = 3333;
    extremeRouter = 20128;
    polyfloor = 8001;
    everos = 8092;
    contextForge = 8094;
  };

  hostOf =
    machine:
    if machine == "z0r0" then
      z0r0
    else if machine == "nami" then
      nami
    else
      luffy;

  mkService =
    name:
    {
      machine,
      serviceName ? name,
      port,
      icon,
      description,
      widget ? null,
      siteMonitor ? null,
    }:
    let
      host = hostOf machine;
      href = "http://${host}:${toString port}";
    in
    {
      ${serviceName} = {
        inherit icon description;
        inherit href;
        siteMonitor = if siteMonitor != null then siteMonitor else href;
      }
      // optionalAttrs (hasEnv && widget != null) { inherit widget; };
    };

  zSrv =
    n: p: ic: desc:
    mkService n {
      machine = "z0r0";
      port = ports.${p};
      icon = ic;
      description = "${desc} @z0r0";
    };
  lSrv =
    n: p: ic: desc:
    mkService n {
      machine = "luffy";
      port = ports.${p};
      icon = ic;
      description = "${desc} @luffy";
    };
  nSrv =
    n: p: ic: desc:
    mkService n {
      machine = "nami";
      port = ports.${p};
      icon = ic;
      description = "${desc} @nami";
    };

  zSrvW =
    n: p: ic: desc: widget:
    mkService n {
      machine = "z0r0";
      port = ports.${p};
      icon = ic;
      description = "${desc} @z0r0";
      inherit widget;
    };
  lSrvW =
    n: p: ic: desc: widget:
    mkService n {
      machine = "luffy";
      port = ports.${p};
      icon = ic;
      description = "${desc} @luffy";
      inherit widget;
    };
  nSrvW =
    n: p: ic: desc: widget:
    mkService n {
      machine = "nami";
      port = ports.${p};
      icon = ic;
      description = "${desc} @nami";
      inherit widget;
    };

  # ---------------------------------------------------------------------------
  # Service groups  —  Speeddial at top, then Observability, AI, Infra, Comms, Media, Auto
  # ---------------------------------------------------------------------------
  groups = {
    Speeddial = [
      (zSrv "Hermes Workspace" "hermesWorkspace" "mdi-robot-outline" "Agent Command Center")
      (lSrv "Open WebUI" "openWebui" "open-webui.png" "Local LLM Chat")
      (lSrv "SearXNG" "searxng" "searxng.png" "Meta Search Engine")
      (nSrv "Kong Gateway" "kongGateway" "mdi-api" "Unified LLM/API Gateway")
      (zSrvW "Grafana" "grafana" "grafana.png" "Dashboards & Visualization" {
        type = "grafana";
        url = "http://${hostOf "z0r0"}:${toString ports.grafana}";
        username = "admin";
        password = "admin";
      })
      (lSrv "Vaultwarden" "vaultwarden" "vaultwarden.png" "Password Manager")
    ];

    Observability = [
      (zSrvW "Prometheus" "prometheus" "prometheus.png" "Metrics Collection" {
        type = "prometheus";
        url = "http://${hostOf "z0r0"}:${toString ports.prometheus}";
      })
      (zSrv "Loki" "loki" "loki.png" "Log Aggregation")
      (zSrvW "Grafana" "grafana" "grafana.png" "Dashboards & Visualization" {
        type = "grafana";
        url = "http://${hostOf "z0r0"}:${toString ports.grafana}";
        username = "admin";
        password = "admin";
      })
      (lSrvW "AdGuard Home" "adguard" "adguard-home.png" "DNS Filtering" {
        type = "adguard";
        url = "http://${hostOf "luffy"}:${toString ports.adguard}";
        username = "admin";
        password = "admin";
      })
    ];

    "AI / Agents" = [
      (lSrv "Ollama" "ollama" "ollama.png" "LLM Inference Server")
      (lSrv "Open WebUI" "openWebui" "open-webui.png" "Chat Frontend")
      (lSrv "PostgreSQL" "postgres" "si-postgresql" "PG + pgvector + lantern")
      (lSrv "MaxKB" "maxkb" "mdi-book-search" "Knowledge Base")
      (lSrv "Jan" "jan" "mdi-desktop-tower-monitor" "Local AI Desktop")
      (zSrv "Hermes Workspace" "hermesWorkspace" "mdi-robot-outline" "Agent Command Center")
      (zSrv "Hermes Dashboard" "hermesDashboard" "mdi-chart-timeline-variant" "Agent Metrics & Sessions")
      (zSrv "SillyTavern" "sillytavern" "sillytavern.png" "AI Character Chat")
      (zSrv "llama.cpp" "llamaCpp" "mdi-brain" "Inference Server")
      (zSrvW "Langfuse" "langfuse" "mdi-chart-line-variant" "LLM Observability" {
        type = "customapi";
        url = "http://${hostOf "z0r0"}:${toString ports.langfuse}/api/public/metrics";
        refresh = 10000;
      })
      (zSrv "Brain Service" "brainService" "mdi-brain" "AI Brain Layer")
      (zSrv "Hermes WebUI" "hermesWebui" "mdi-react" "Web UI Dashboard")
      (zSrv "AionUi" "aionUi" "mdi-account-group" "AI Agent Cowork UI")
      (nSrv "Paperclip" "paperclip" "mdi-paperclip" "AI Team Orchestration")
      (nSrv "Mission Control" "missionControl" "mdi-rocket-launch" "Agent Control Plane")
      (nSrv "Kong Gateway" "kongGateway" "mdi-api" "Unified LLM/API Gateway")
      (zSrv "ExtremeRouter" "extremeRouter" "mdi-router-network"
        "AI Gateway — 154+ Providers, RTK Savings"
      )
      (nSrv "OmniRoute" "omniroute" "mdi-routes" "Nami AI Router")
      (zSrv "FreeLLMPool" "freellmpool" "mdi-pool" "Free-Tier LLM Pool")
      (zSrv "FreeLLMAPI" "freellmapi" "mdi-api" "Free-Tier LLM Router")
      (zSrv "Mistral MCP" "mistralMcp" "mdi-brain" "Mistral AI Tool Server")
      (lSrv "OpenCompany" "opencompany" "mdi-office-building" "AI Workflow Canvas")
      (zSrv "Polyfloor OS" "polyfloor" "mdi-layers-triple" "Multi-floor AI Agent OS")
      (zSrv "EverOS Memory Engine" "everos" "mdi-brain-freeze" "Memory Chassis & Engine")
      (zSrv "ContextForge Gateway" "contextForge" "mdi-router-wireless" "MCP Context Gateway")
      (nSrv "gno Memory Storage" "gno" "mdi-database-search" "Cloud Knowledge Index")
    ];

    Infrastructure = [
      (lSrv "Vaultwarden" "vaultwarden" "vaultwarden.png" "Password Manager")
      (nSrvW "Headscale" "headscale" "headscale.png" "Tailscale Control Server" {
        type = "headscale";
        url = "http://${hostOf "nami"}:${toString ports.headscale}";
        nodeId = "\${HOMEPAGE_HEADSCALE_NODE_ID}";
        key = "\${HOMEPAGE_HEADSCALE_KEY}";
      })
      (lSrv "SearXNG" "searxng" "searxng.png" "Meta Search Engine")
      (lSrv "FileBrowser" "filebrowser" "filebrowser.png" "Web File Manager")
      (lSrv "Spacedrive" "spacedrive" "si-spacedrive" "Virtual File System")
      (lSrv "Karakeep" "karakeep" "mdi-bookmark-multiple" "Bookmark Manager")
      (lSrvW "Caddy" "caddyAdmin" "caddy.png" "Reverse Proxy" {
        type = "caddy";
        url = "http://${hostOf "luffy"}:${toString ports.caddyAdmin}";
      })
    ];

    Communications = [
      (lSrv "Matrix Synapse" "matrixSynapse" "matrix.png" "Federated Chat Server")
      (lSrv "Element Web" "elementWeb" "element.png" "Matrix Client")
      (lSrv "Mautrix WhatsApp" "mautrixWhatsapp" "whatsapp.png" "WhatsApp Bridge")
      (lSrv "Mautrix Signal" "mautrixSignal" "signal.png" "Signal Bridge")
      (zSrv "Signal CLI" "signalCli" "si-signal" "Signal Daemon")
      (lSrv "RustDesk" "rustdeskSignal" "mdi-monitor-share" "Remote Desktop")
    ];

    Media = [
      (lSrvW "Jellyfin" "jellyfin" "jellyfin.png" "Media Server" {
        type = "jellyfin";
        url = "http://${hostOf "luffy"}:${toString ports.jellyfin}";
        key = "\${HOMEPAGE_JELLYFIN_KEY}";
        enableBlocks = true;
        enableNowPlaying = true;
        enableUser = true;
      })
      (lSrvW "Sonarr" "sonarr" "sonarr.png" "TV Series Management" {
        type = "sonarr";
        url = "http://${hostOf "luffy"}:${toString ports.sonarr}";
        key = "\${HOMEPAGE_SONARR_KEY}";
        enableQueue = true;
      })
      (lSrvW "Radarr" "radarr" "radarr.png" "Movie Management" {
        type = "radarr";
        url = "http://${hostOf "luffy"}:${toString ports.radarr}";
        key = "\${HOMEPAGE_RADARR_KEY}";
        enableQueue = true;
      })
      (lSrv "Lidarr" "lidarr" "lidarr.png" "Music Management")
      (lSrv "Readarr" "readarr" "readarr.png" "Book Management")
      (lSrvW "Prowlarr" "prowlarr" "prowlarr.png" "Indexer Manager" {
        type = "prowlarr";
        url = "http://${hostOf "luffy"}:${toString ports.prowlarr}";
        key = "\${HOMEPAGE_PROWLARR_KEY}";
      })
      (lSrv "Bazarr" "bazarr" "bazarr.png" "Subtitle Management")
      (lSrvW "qBittorrent" "qbittorrent" "qbittorrent.png" "Torrent Client" {
        type = "qbittorrent";
        url = "http://${hostOf "luffy"}:${toString ports.qbittorrent}";
        username = "admin";
        password = "adminadmin";
        enableLeechProgress = true;
        enableLeechSize = true;
      })
      (lSrv "Aria2" "aria2" "aria2.png" "Download Manager")
      (lSrv "Calibre-Web" "calibreWeb" "calibre-web.png" "E-Book Library")
      (lSrvW "Kavita" "kavita" "kavita.png" "Comic / Manga Reader" {
        type = "kavita";
        url = "http://${hostOf "luffy"}:${toString ports.kavita}";
        username = "admin";
        password = "admin";
      })
      (lSrv "Komga" "komga" "mdi-book-multiple" "Comic / Manga Library")
      (lSrvW "Your Spotify" "yourSpotify" "spotify.png" "Spotify Analytics" {
        type = "yourspotify";
        url = "http://${hostOf "luffy"}:${toString ports.yourSpotify}";
        key = "\${HOMEPAGE_SPOTIFY_KEY}";
        interval = "month";
      })
    ];

    Automation = [
      (lSrv "n8n" "n8n" "n8n.png" "Workflow Automation")
      (lSrvW "Home Assistant" "homeAssistant" "home-assistant.png" "Home Automation" {
        type = "homeassistant";
        url = "http://${hostOf "luffy"}:${toString ports.homeAssistant}";
        key = "\${HOMEPAGE_HASS_KEY}";
        custom = [
          { state = "sensor.temperature"; }
          {
            state = "sun.sun";
            label = "sun";
          }
        ];
      })
      (lSrv "Crawl4AI" "crawl4ai" "mdi-spider-web" "Web Scraper API")
      (lSrv "Skyvern UI" "skyvernUi" "mdi-weather-lightning" "Browser Automation UI")
      (lSrv "Skyvern API" "skyvernApi" "mdi-api" "Automation API")
    ];
  };

  toGroupAttrs = name: entries: { ${name} = entries; };

in
{
  options.layers.layer-20.services.config.homepage-dashboard = {
    enable = mkEnableOption "Homepage Dashboard";
    port = mkOption {
      type = types.port;
      default = 8082;
      description = "Port to expose Homepage Dashboard on";
    };
    lovable = {
      enable = mkEnableOption "Lovable (One Piece / Cyberpunk) theme";
      cssPath = mkOption {
        type = types.path;
        default = ../../../layers/00-cyberia/02-assets/templates/homepage-theme.css;
        description = "Path to Lovable CSS theme";
      };
      jsPath = mkOption {
        type = types.path;
        default = ../../../layers/00-cyberia/02-assets/templates/homepage-theme.js;
        description = "Path to Lovable JS effects";
      };
    };
    environmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to env file with widget API keys (HOMEPAGE_*_KEY)";
    };
  };

  config = mkIf cfg.enable {
    services.homepage-dashboard = mkMerge [
      {
        enable = true;
        listenPort = cfg.port;
        environmentFiles = optional (cfg.environmentFile != null) cfg.environmentFile;
        # Allow tailnet clients (100.64.0.0/10) + LAN to access the dashboard
        allowedHosts = concatStringsSep "," [
          "localhost:${toString cfg.port}"
          "127.0.0.1:${toString cfg.port}"
          "100.64.0.3:${toString cfg.port}"
          "192.168.1.54:${toString cfg.port}"
        ];

        docker = {
          local = {
            socket = "/run/podman/podman.sock";
          };
        };

        settings = {
          title = "Nix Flake Pirates";
          favicon = "https://raw.githubusercontent.com/gethomepage/homepage/main/public/homepage.png";
          theme = "dark";
          color = "slate";
          background = {
            opacity = 0;
          };
          layout = {
            Speeddial = {
              style = "row";
              columns = 6;
              icon = "mdi-lightning-bolt-circle";
              header = true;
            };
            Observability = {
              style = "row";
              columns = 5;
              icon = "mdi-chart-line";
              header = true;
            };
            "AI / Agents" = {
              style = "row";
              columns = 5;
              icon = "mdi-robot";
              header = true;
            };
            Infrastructure = {
              style = "row";
              columns = 4;
              icon = "mdi-server";
              header = true;
            };
            Communications = {
              style = "row";
              columns = 3;
              icon = "mdi-chat";
              header = true;
            };
            Media = {
              style = "row";
              columns = 4;
              icon = "mdi-multimedia";
              header = true;
            };
            Automation = {
              style = "row";
              columns = 4;
              icon = "mdi-autorenew";
              header = true;
            };
          };
          headerStyle = "boxedWidgets";
          cardBlur = "sm";
          hideVersion = true;
          language = "en-GB";
          statusStyle = "dot";
          iconStyle = "theme";
          useEqualHeights = true;
          disableUpdateCheck = true;
          quicklaunch = {
            searchDescriptions = true;
            hideInternetSearch = false;
            showSearchSuggestions = true;
          };
          bookmarks = [
            {
              "Developer Tools" = [
                {
                  "NixOS Package Search" = [
                    {
                      abbr = "NIX";
                      href = "https://search.nixos.org";
                      description = "NixOS package and option search";
                    }
                  ];
                }
                {
                  "Clan Documentation" = [
                    {
                      abbr = "CLN";
                      href = "https://docs.clan.lol";
                      description = "Clan core flake management docs";
                    }
                  ];
                }
                {
                  "GitHub" = [
                    {
                      abbr = "GH";
                      href = "https://github.com";
                      description = "Code hosting & pull requests";
                    }
                  ];
                }
                {
                  "Searchix" = [
                    {
                      abbr = "SIX";
                      href = "https://searchix.ovh";
                      description = "Nix, Home Manager & Flake options search";
                    }
                  ];
                }
                {
                  "Agentaflow" = [
                    {
                      abbr = "AF";
                      href = "https://agentaflow.space";
                      description = "AI Agent workflow engine";
                    }
                  ];
                }
              ];
            }
            {
              "AI & Intelligence" = [
                {
                  "Google AI Studio" = [
                    {
                      abbr = "GIS";
                      href = "https://aistudio.google.com";
                      description = "Gemini API developer portal";
                    }
                  ];
                }
                {
                  "Perplexity AI" = [
                    {
                      abbr = "PPL";
                      href = "https://www.perplexity.ai";
                      description = "AI Search & Research engine";
                    }
                  ];
                }
              ];
            }
            {
              "Media & Entertainment" = [
                {
                  "YouTube" = [
                    {
                      abbr = "YT";
                      href = "https://youtube.com";
                      description = "Video streaming";
                    }
                  ];
                }
                {
                  "wco.tv" = [
                    {
                      abbr = "WCO";
                      href = "https://wco.tv";
                      description = "Anime & Animation streaming";
                    }
                  ];
                }
                {
                  "EverythingMoe" = [
                    {
                      abbr = "EM";
                      href = "https://everythingmoe.com";
                      description = "Anime index & resources";
                    }
                  ];
                }
                {
                  "TorrentSeeker" = [
                    {
                      abbr = "TS";
                      href = "https://torrentseeker.com";
                      description = "Meta torrent search";
                    }
                  ];
                }
              ];
            }
          ];
        };

        widgets = [
          # ── Title — NFP (gradient styled via customCSS) ──
          {
            greeting = {
              text_size = "4xl";
              text = "NFP";
            };
          }
          # ── Search 1 — Perplexity (research-grade) ──
          {
            search = {
              provider = "custom";
              customSearch = "https://www.perplexity.ai/search?q=%s";
              target = "_blank";
              showSearchSuggestions = false;
            };
          }
          # ── Search 2 — SearXNG (privacy-first meta search) ──
          {
            search = {
              provider = "custom";
              customSearch = "http://${luffy}:${toString ports.searxng}/search?q=%s";
              target = "_blank";
              showSearchSuggestions = true;
            };
          }
        ]
        ++ optional hasEnv {
          weather = {
            provider = "openweather";
            apiKey = "\${HOMEPAGE_OPENWEATHER_KEY}";
            units = "metric";
          };
        }
        ++ [
          # ── Local system resources (expanded) ──
          {
            resources = {
              label = "${hostName} System";
              cpu = true;
              memory = true;
              disk = "/";
              uptime = true;
              expanded = true;
            };
          }
          # ── Remote machine stats via Glances ──
          {
            glances = {
              label = "${remoteMachine} System";
              url = "http://${remoteIP}:${toString ports.glances}";
              cpu = true;
              mem = true;
              disk = "/";
              uptime = true;
              expanded = true;
            };
          }
          # ── Date / time — gradient styled via customCSS ──
          {
            datetime = {
              text_size = "xl";
              format = {
                dateStyle = "full";
                timeStyle = "medium";
                hour12 = false;
              };
              locale = "en-GB";
            };
          }
          # ── Grafana Observability Kiosk ──
          {
            iframe = {
              title = "Grafana Observability Kiosk";
              src = "http://${hostOf "z0r0"}:${toString ports.grafana}/d/hermes-activity?kiosk";
              height = "350";
            };
          }
        ];

        services = mapAttrsToList toGroupAttrs groups;

        customCSS = gradientCSS;
      }

      (mkIf cfg.lovable.enable {
        customCSS = gradientCSS + builtins.readFile cfg.lovable.cssPath;
        customJS = builtins.readFile cfg.lovable.jsPath;
      })
    ];

    # Firewall
    networking.firewall.allowedTCPPorts = [
      cfg.port
      ports.glances
    ];

    # User / Group
    users.users.homepage-dashboard = {
      isSystemUser = true;
      group = "homepage-dashboard";
    };
    users.groups.homepage-dashboard = { };

    # Impermanence support
    environment.persistence."/persist" =
      mkIf (config.layers.layer-10.system.config.impermanence.enable or false)
        {
          directories = [
            {
              directory = "/var/lib/homepage-dashboard";
              user = "homepage-dashboard";
              group = "homepage-dashboard";
              mode = "0700";
            }
          ];
        };

    # Systemd — fix StateDirectory clash with impermanence
    systemd.services.homepage-dashboard = {
      serviceConfig = {
        StateDirectory = mkForce [ ];
        ReadWritePaths = [ "/var/lib/homepage-dashboard" ];
        Restart = "on-failure";
        RestartSec = "5s";
      };
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/homepage-dashboard 0700 homepage-dashboard homepage-dashboard -"
      "d /var/lib/homepage-dashboard/images 0755 homepage-dashboard homepage-dashboard -"
      "L+ /var/lib/homepage-dashboard/images/robin.png - - - - ${../../../layers/00-cyberia/02-assets/png-ico/Nicorobin.png}"
      "L+ /var/lib/homepage-dashboard/images/vegapunk.png - - - - ${../../../layers/00-cyberia/02-assets/png-ico/Stella.png}"
      "L+ /var/lib/homepage-dashboard/images/franky.png - - - - ${../../../layers/00-cyberia/02-assets/png-ico/Franck.png}"
      "L+ /var/lib/homepage-dashboard/images/nami.png - - - - ${../../../layers/00-cyberia/02-assets/png-ico/Nami.png}"
      "L+ /var/lib/homepage-dashboard/images/sanji.png - - - - ${../../../layers/00-cyberia/02-assets/png-ico/Sanji.png}"
      "L+ /var/lib/homepage-dashboard/images/usopp.png - - - - ${../../../layers/00-cyberia/02-assets/png-ico/Usopp.png}"
      "L+ /var/lib/homepage-dashboard/images/luffy.png - - - - ${../../../layers/00-cyberia/02-assets/png-ico/Lufy.png}"
      "L+ /var/lib/homepage-dashboard/images/zoro.png - - - - ${../../../layers/00-cyberia/02-assets/png-ico/Zoro.png}"
    ]
    ++ optional (config.layers.layer-10.system.config.impermanence.enable or false
    ) "d /persist/var/lib/homepage-dashboard 0700 homepage-dashboard homepage-dashboard -";
  };
}
