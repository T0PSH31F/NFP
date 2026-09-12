{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.layers.layer-20.services.config.download-clients;
  mediaCfg = config.layers.layer-20.services.config.media-stack;
in
{
  options.layers.layer-20.services.config.download-clients = {
    enable = mkEnableOption "Download clients management";

    deluge = {
      enable = mkEnableOption "Deluge torrent client";
      port = mkOption {
        type = types.port;
        default = 8112;
      };
    };

    transmission = {
      enable = mkEnableOption "Transmission torrent client";
      port = mkOption {
        type = types.port;
        default = 9091;
      };
    };

    aria2 = {
      enable = mkEnableOption "Aria2 download client";
      port = mkOption {
        type = types.port;
        default = 6800;
      };
    };
  };

  config = mkIf cfg.enable {
    clan.core.vars.generators.deluge = mkIf cfg.deluge.enable {
      files."authFile" = {
        secret = true;
        owner = mediaCfg.user;
        inherit (mediaCfg) group;
      };
      script = ''
        PASSWORD=$(${pkgs.openssl}/bin/openssl rand -hex 16)
        echo "localclient:$PASSWORD:10" > "$out/authFile"
      '';
    };

    # Deluge
    services.deluge = mkIf cfg.deluge.enable {
      enable = true;
      web.enable = true;
      web.port = cfg.deluge.port;
      declarative = true;
      authFile = config.clan.core.vars.generators.deluge.files."authFile".path;
      config = {
        download_location = "${mediaCfg.downloadsDir}/torrents";
        max_active_downloading = 5;
        max_active_seeding = 10;
        max_active_limit = 15;
        random_port = false;
        listen_ports = [
          6881
          6889
        ];
        enc_prefer_rc4 = true;
        enc_level = 1;
      };
      inherit (mediaCfg) user;
      inherit (mediaCfg) group;
    };

    systemd.services.deluged = mkIf cfg.deluge.enable {
      serviceConfig.ExecStartPre = [
        "+${pkgs.writeShellScript "deluged-perms" ''
          mkdir -p /var/lib/deluge/.config/deluge
          chown -R ${mediaCfg.user}:${mediaCfg.group} /var/lib/deluge
          chmod -R u+rwX,g+rX,o= /var/lib/deluge
        ''}"
      ];
    };

    # Transmission
    services.transmission = mkIf cfg.transmission.enable {
      enable = true;
      package = pkgs.transmission_4;
      inherit (mediaCfg) user;
      inherit (mediaCfg) group;
      settings = {
        rpc-bind-address = "0.0.0.0";
        rpc-port = cfg.transmission.port;
        rpc-whitelist-enabled = false;
        download-dir = "${mediaCfg.downloadsDir}/transmission";
      };
    };

    # Aria2
    environment.systemPackages = mkIf cfg.aria2.enable [
      pkgs.aria2
      pkgs.python3Packages.aria2p
    ];

    services.aria2 = mkIf cfg.aria2.enable {
      enable = true;
      openPorts = true;
      rpcSecretFile = config.clan.core.vars.generators.aria2.files."rpc_secret".path;
      settings = {
        dir = "${mediaCfg.downloadsDir}/aria2";
        enable-rpc = true;
        rpc-listen-port = cfg.aria2.port;
        rpc-listen-all = true;
        max-concurrent-downloads = 5;
        continue = true;
        save-session = "/var/lib/aria2/session.gz";
        input-file = "/var/lib/aria2/session.gz";
        save-session-interval = 60;
      };
    };

    systemd.services.aria2 = mkIf cfg.aria2.enable {
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        User = mkForce mediaCfg.user;
        Group = mkForce mediaCfg.group;
      };
    };

    clan.core.vars.generators.aria2 = mkIf cfg.aria2.enable {
      files."rpc_secret" = {
        secret = true;
        owner = mediaCfg.user;
        inherit (mediaCfg) group;
      };
      prompts."rpc_secret" = {
        type = "hidden";
        description = "Aria2 RPC Secret Token";
      };
      script = ''
        if [ -f "$prompts/rpc_secret" ]; then
          cat "$prompts/rpc_secret" > "$out/rpc_secret"
        else
          head -c 32 /dev/urandom | base64 | tr -d '\n' > "$out/rpc_secret"
        fi
      '';
    };

    # Directories
    systemd.tmpfiles.rules =
      (optional cfg.transmission.enable "d /var/lib/transmission 0750 ${mediaCfg.user} ${mediaCfg.group} -")
      ++ (optionals cfg.aria2.enable [
        "d ${mediaCfg.downloadsDir}/aria2 0755 ${mediaCfg.user} ${mediaCfg.group} -"
        "d /var/lib/aria2 0750 ${mediaCfg.user} ${mediaCfg.group} -"
        "f /var/lib/aria2/session.gz 0644 ${mediaCfg.user} ${mediaCfg.group} -"
      ]);

    # Firewall
    networking.firewall.allowedTCPPorts =
      (optional cfg.deluge.enable cfg.deluge.port)
      ++ (optional cfg.transmission.enable cfg.transmission.port)
      ++ (optionals cfg.aria2.enable [
        cfg.aria2.port
        6801
      ]);

    # Persistence
    environment.persistence."/persist" = mkIf config.layers.layer-10.system.config.impermanence.enable {
      directories =
        (optional cfg.deluge.enable {
          directory = "/var/lib/deluge";
          inherit (mediaCfg) user;
          inherit (mediaCfg) group;
          mode = "0750";
        })
        ++ (optional cfg.transmission.enable "/var/lib/transmission")
        ++ (optional cfg.aria2.enable "/var/lib/aria2");
    };
  };
}
