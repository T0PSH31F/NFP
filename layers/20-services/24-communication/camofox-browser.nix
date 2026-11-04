{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.layers.layer-20.services.communication.camofox-browser;
  camoufoxBin = pkgs.camoufox;
  camofoxPkg = pkgs.jo-camofox-browser;

  runtimePath = lib.makeBinPath [
    pkgs.xvfb
    pkgs.x11vnc
    pkgs.novnc
    pkgs.python3Packages.websockify
    pkgs.gawk
    pkgs.which
    pkgs.coreutils
    pkgs.findutils
    pkgs.gnused
    pkgs.gnugrep
    pkgs.bash
  ];

in
{
  options.layers.layer-20.services.communication.camofox-browser = {
    enable = mkEnableOption "Camofox anti-detection browser server (jo-inc fork with VNC + persistence)";
    port = mkOption {
      type = types.port;
      default = 9377;
      description = "Port for the Camofox browser server";
    };
    vncPort = mkOption {
      type = types.port;
      default = 6080;
      description = "Port for the noVNC web client (visual login for OAuth)";
    };
    apiKey = mkOption {
      type = types.str;
      default = "";
      description = "API key for cookie import endpoint (CAMOFOX_API_KEY)";
    };
    accessKey = mkOption {
      type = types.str;
      default = "";
      description = "Bearer access key for the REST API (CAMOFOX_ACCESS_KEY)";
    };
    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/camofox";
      description = "Data directory for Camofox profiles, cookies, and traces";
    };
    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Open the Camofox port in the firewall";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      camofoxPkg
      camoufoxBin
      # lowPrio: xwayland wins the shared man/doc paths; Xvfb bin has no name collision
      (lib.lowPrio pkgs.xvfb)
      pkgs.x11vnc
      pkgs.novnc
    ];
    environment.variables.CAMOUFOX_EXECUTABLE = lib.getExe camoufoxBin;

    users.users.camofox = {
      isSystemUser = true;
      group = "camofox";
      home = cfg.dataDir;
      createHome = true;
    };
    users.groups.camofox = { };

    # Xvfb is launched with -shmem; a SIGKILLed browser/Xvfb leaks its SysV
    # shared-memory segment. At the stock kernel.shmmni=4096 the machine wedges
    # after ~4k launch attempts ("shmget: No space left on device") and Camofox
    # silently stops starting its browser. Raise the ceiling and reap orphans
    # on every start (see ExecStartPre below).
    boot.kernel.sysctl."kernel.shmmni" = 32768;

    # ── Gmail session cookies (SOPS-encrypted, never plaintext) ──────────
    # Each secret holds a JSON array of browser cookies for the account.
    # Populate with:
    #   sops layers/00-cyberia/03-treasure/secrets/external_services.yaml
    # and paste the cookie JSON array.  Empty values disable import.
    sops.secrets.gmail_cookies_wrighterik77 = {
      sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
      owner = "camofox";
      group = "camofox";
      mode = "0400";
    };
    sops.secrets.gmail_cookies_lovelainautomations = {
      sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
      owner = "camofox";
      group = "camofox";
      mode = "0400";
    };

    systemd = {
      tmpfiles.rules = [
        "d ${cfg.dataDir} 0755 camofox camofox -"
        "d ${cfg.dataDir}/profiles 0755 camofox camofox -"
        "d ${cfg.dataDir}/cookies 0755 camofox camofox -"
        "d ${cfg.dataDir}/traces 0755 camofox camofox -"
        "L+ /usr/share/novnc - - - - ${pkgs.novnc}/share/webapps/novnc"
        "L+ /usr/bin/awk - - - - ${pkgs.gawk}/bin/awk"
      ];

      services = {
        camofox-browser =
          let
            startScript = pkgs.writeShellScript "camofox-start" ''
              # Load SOPS-managed secrets from systemd LoadCredential
              if [ -f "''${CREDENTIALS_DIRECTORY:-}/camofox_api_key" ]; then
                export CAMOFOX_API_KEY="$(cat "''${CREDENTIALS_DIRECTORY}/camofox_api_key")"
              fi
              if [ -f "''${CREDENTIALS_DIRECTORY:-}/camofox_access_key" ]; then
                export CAMOFOX_ACCESS_KEY="$(cat "''${CREDENTIALS_DIRECTORY}/camofox_access_key")"
              fi
              exec ${camofoxPkg}/bin/jo-camofox-browser
            '';

            # Deterministic Gmail session provisioning.  Each account's cookie
            # jar is supplied as a SOPS-encrypted secret (never plaintext in the
            # repo) and injected into the browser only when non-empty.  Cookies
            # are persisted by the persistence plugin under CAMOFOX_PROFILE_DIR,
            # so subsequent boots reuse them without re-importing.
            importCookies = pkgs.writeShellScript "camofox-import-cookies" ''
              set -eu
              api_key="''${CAMOFOX_API_KEY:-}"
              [ -n "$api_key" ] || exit 0
              base="http://127.0.0.1:${toString cfg.port}"

              # Wait for the browser server to answer /health (max ~30s).
              i=0
              while [ "$i" -lt 30 ]; do
                if ${pkgs.curl}/bin/curl -sf "$base/health" >/dev/null 2>&1; then
                  break
                fi
                i=$((i + 1))
                sleep 1
              done

              for acct in wrighterik77 lovelainautomations; do
                f="''${CREDENTIALS_DIRECTORY:-}/gmail_cookies_$acct"
                [ -s "$f" ] || continue
                # Skip empty placeholder values ("" or []).
                normalized="$(tr -d '[:space:]' < "$f")"
                if [ -z "$normalized" ]; then
                  continue
                fi
                if [ "$normalized" = "[]" ] || [ "$normalized" = "\"\"" ]; then
                  continue
                fi
                ${pkgs.curl}/bin/curl -sf -X POST "$base/sessions/$acct/cookies" \
                  -H "Authorization: Bearer $api_key" \
                  -H "Content-Type: application/json" \
                  --data-binary "{\"cookies\":$(cat "$f")}" \
                  >/dev/null 2>&1 || true
              done
            '';

            # Reap orphaned SysV shared-memory segments owned by camofox before
            # the browser starts. A segment with zero attached processes is
            # guaranteed dead; removing it prevents the shmmni exhaustion above.
            cleanShm = pkgs.writeShellScript "camofox-clean-shm" ''
              ${pkgs.util-linux}/bin/ipcs -m 2>/dev/null \
                | awk '$3 == "camofox" && $6 == 0 { print $2 }' \
                | while read -r id; do
                    if [ -n "$id" ]; then
                      ${pkgs.util-linux}/bin/ipcrm -m "$id" 2>/dev/null || true
                    fi
                  done
              exit 0
            '';
          in
          {
            description = "Camofox anti-detection browser server (jo-inc fork)";
            after = [ "network.target" ];
            wantedBy = [ "multi-user.target" ];
            path = [
              pkgs.xvfb
              pkgs.x11vnc
              pkgs.novnc
              pkgs.python3Packages.websockify
              pkgs.gawk
              pkgs.gnugrep
              pkgs.gnused
              pkgs.which
              pkgs.nettools
              pkgs.procps
              pkgs.coreutils
              pkgs.curl
              pkgs.util-linux
            ];
            serviceConfig = {
              Type = "simple";
              User = "camofox";
              Group = "camofox";
              ExecStartPre = [ cleanShm ];
              ExecStart = startScript;
              # Provision HTTPS session cookies after the server is healthy.
              ExecStartPost = [ importCookies ];
              Restart = "on-failure";
              RestartSec = 5;
              StateDirectory = "camofox";
              StateDirectoryMode = "0755";
              Environment = [
                "PATH=${runtimePath}"
                "CAMOFOX_PORT=${toString cfg.port}"
                "CAMOFOX_DATA_DIR=${cfg.dataDir}"
                "CAMOFOX_PROFILE_DIR=${cfg.dataDir}/profiles"
                "CAMOFOX_COOKIES_DIR=${cfg.dataDir}/cookies"
                "CAMOFOX_TRACES_DIR=${cfg.dataDir}/traces"
                "BROWSER_IDLE_TIMEOUT_MS=300000"
                "MAX_SESSIONS=50"
                "CAMOFOX_CRASH_REPORT_ENABLED=false"
                "CAMOUFOX_EXECUTABLE=${lib.getExe camoufoxBin}"
                "ENABLE_VNC=1"
                "NOVNC_PORT=${toString cfg.vncPort}"
              ];
              LoadCredential =
                lib.optionals (cfg.apiKey != "") [
                  "camofox_api_key:${cfg.apiKey}"
                ]
                ++ lib.optionals (cfg.accessKey != "") [
                  "camofox_access_key:${cfg.accessKey}"
                ]
                ++ [
                  "gmail_cookies_wrighterik77:${config.sops.secrets.gmail_cookies_wrighterik77.path}"
                  "gmail_cookies_lovelainautomations:${config.sops.secrets.gmail_cookies_lovelainautomations.path}"
                ];
            };
          };

        # VNC bridge: disabled — x11vnc can't attach to Xvfb's MIT-SHM segments
        # (camofox user lacks shared memory access). noVNC websockify runs on :6080
        # via the built-in vnc-watcher, but x11vnc never starts. Visual login can
        # be done via SSH X forwarding or by running x11vnc manually as root:
        #   sudo x11vnc -display :99 -forever -shared -nopw -rfbport 5900
        # then open http://localhost:6080/vnc.html
        camofox-vnc = {
          description = "VNC bridge for Camofox (x11vnc attached to Xvfb) — DISABLED";
          after = [ "camofox-browser.service" ];
          wantedBy = lib.mkForce [ ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.coreutils}/bin/true";
            RemainAfterExit = true;
          };
        };
      };
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [
      cfg.port
      cfg.vncPort
    ];

    # Note: /var/lib/camofox is persisted centrally in layers/10-system/15-filesystem/impermanence.nix
  };
}
