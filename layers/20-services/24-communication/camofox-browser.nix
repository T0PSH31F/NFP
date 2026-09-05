{
  config,
  lib,
  pkgs,
  inputs,
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
      pkgs.xvfb
      pkgs.x11vnc
      pkgs.novnc
    ];
    environment.variables.CAMOUFOX_EXECUTABLE = lib.getExe camoufoxBin;

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 camofox camofox -"
      "d ${cfg.dataDir}/profiles 0755 camofox camofox -"
      "d ${cfg.dataDir}/cookies 0755 camofox camofox -"
      "d ${cfg.dataDir}/traces 0755 camofox camofox -"
      "L+ /usr/share/novnc - - - - ${pkgs.novnc}/share/webapps/novnc"
      "L+ /usr/bin/awk - - - - ${pkgs.gawk}/bin/awk"
    ];

    users.users.camofox = {
      isSystemUser = true;
      group = "camofox";
      home = cfg.dataDir;
      createHome = true;
    };
    users.groups.camofox = { };

    systemd.services.camofox-browser =
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
        ];
        serviceConfig = {
          Type = "simple";
          User = "camofox";
          Group = "camofox";
          ExecStart = startScript;
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
            ];
        };
      };

    # VNC bridge: disabled — x11vnc can't attach to Xvfb's MIT-SHM segments
    # (camofox user lacks shared memory access). noVNC websockify runs on :6080
    # via the built-in vnc-watcher, but x11vnc never starts. Visual login can
    # be done via SSH X forwarding or by running x11vnc manually as root:
    #   sudo x11vnc -display :99 -forever -shared -nopw -rfbport 5900
    # then open http://localhost:6080/vnc.html
    systemd.services.camofox-vnc = {
      description = "VNC bridge for Camofox (x11vnc attached to Xvfb) — DISABLED";
      after = [ "camofox-browser.service" ];
      wantedBy = lib.mkForce [ ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.coreutils}/bin/true";
        RemainAfterExit = true;
      };
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [
      cfg.port
      cfg.vncPort
    ];
  };
}
