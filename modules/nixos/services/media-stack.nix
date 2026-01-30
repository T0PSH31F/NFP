{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  options.services-config.media-stack = {
    enable = mkEnableOption "Complete media management stack (Homarr, Deluge, aria2, *arr suite)";

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/media";
      description = "Base directory for media storage";
    };

    downloadsDir = mkOption {
      type = types.str;
      default = "/var/lib/media/downloads";
      description = "Downloads directory";
    };

    user = mkOption {
      type = types.str;
      default = "media";
      description = "User for media services";
    };

    group = mkOption {
      type = types.str;
      default = "media";
      description = "Group for media services";
    };
  };

  config = mkIf config.services-config.media-stack.enable {
    # ============================================================================
    # USER & GROUP
    # ============================================================================
    users.users.${config.services-config.media-stack.user} = {
      isSystemUser = true;
      group = config.services-config.media-stack.group;
      home = config.services-config.media-stack.dataDir;
      createHome = true;
    };

    users.groups.${config.services-config.media-stack.group} = { };

    # ============================================================================
    # DIRECTORY STRUCTURE
    # ============================================================================
    systemd.tmpfiles.rules = [
      "d ${config.services-config.media-stack.dataDir} 0755 ${config.services-config.media-stack.user} ${config.services-config.media-stack.group} -"
      "d ${config.services-config.media-stack.downloadsDir} 0755 ${config.services-config.media-stack.user} ${config.services-config.media-stack.group} -"
      "d ${config.services-config.media-stack.dataDir}/tv 0755 ${config.services-config.media-stack.user} ${config.services-config.media-stack.group} -"
      "d ${config.services-config.media-stack.dataDir}/movies 0755 ${config.services-config.media-stack.user} ${config.services-config.media-stack.group} -"
      "d ${config.services-config.media-stack.dataDir}/music 0755 ${config.services-config.media-stack.user} ${config.services-config.media-stack.group} -"
      "d ${config.services-config.media-stack.dataDir}/books 0755 ${config.services-config.media-stack.user} ${config.services-config.media-stack.group} -"
      "d ${config.services-config.media-stack.dataDir}/torrents 0755 ${config.services-config.media-stack.user} ${config.services-config.media-stack.group} -"
      # Fix Prowlarr state directory ownership
      "d /var/lib/prowlarr 0750 ${config.services-config.media-stack.user} ${config.services-config.media-stack.group} -"
      "d /var/lib/sonarr 0750 ${config.services-config.media-stack.user} ${config.services-config.media-stack.group} -"
      "d /var/lib/radarr 0750 ${config.services-config.media-stack.user} ${config.services-config.media-stack.group} -"
      "d /var/lib/lidarr 0750 ${config.services-config.media-stack.user} ${config.services-config.media-stack.group} -"
      "d /var/lib/readarr 0750 ${config.services-config.media-stack.user} ${config.services-config.media-stack.group} -"
      "d /var/lib/bazarr 0750 ${config.services-config.media-stack.user} ${config.services-config.media-stack.group} -"
      "d /var/lib/deluge 0750 ${config.services-config.media-stack.user} ${config.services-config.media-stack.group} -"
      "d /var/lib/aria2 0750 ${config.services-config.media-stack.user} ${config.services-config.media-stack.group} -"
      # Ensure aria2 session directory is writable
      "f /var/lib/aria2/session.gz 0644 ${config.services-config.media-stack.user} ${config.services-config.media-stack.group} -"
      # Ensure directories are created with correct permissions for impermanence
      "d /var/lib/aria2 0755 ${config.services-config.media-stack.user} ${config.services-config.media-stack.group} -"
      "d /var/lib/prowlarr 0755 ${config.services-config.media-stack.user} ${config.services-config.media-stack.group} -"
      # Additional tmpfiles rules to ensure directories are created before services start
      "d /var/lib/aria2 0755 ${config.services-config.media-stack.user} ${config.services-config.media-stack.group} -"
      "d /var/lib/prowlarr 0755 ${config.services-config.media-stack.user} ${config.services-config.media-stack.group} -"
      "d /var/lib/sonarr 0755 ${config.services-config.media-stack.user} ${config.services-config.media-stack.group} -"
      "d /var/lib/radarr 0755 ${config.services-config.media-stack.user} ${config.services-config.media-stack.group} -"
      "d /var/lib/lidarr 0755 ${config.services-config.media-stack.user} ${config.services-config.media-stack.group} -"
      "d /var/lib/readarr 0755 ${config.services-config.media-stack.user} ${config.services-config.media-stack.group} -"
      "d /var/lib/bazarr 0755 ${config.services-config.media-stack.user} ${config.services-config.media-stack.group} -"
      "d /var/lib/deluge 0755 ${config.services-config.media-stack.user} ${config.services-config.media-stack.group} -"
    ];

    # ============================================================================
    # DELUGE - Torrent Client
    # ============================================================================
    services.deluge = {
      enable = true;
      web.enable = true;
      web.port = 8112;

      # Deluge daemon settings
      declarative = true;
      config = {
        download_location = "${config.services-config.media-stack.downloadsDir}/torrents";
        max_active_downloading = 5;
        max_active_seeding = 10;
        max_active_limit = 15;

        # Network settings
        random_port = false;
        listen_ports = [
          6881
          6889
        ];

        # Encryption
        enc_prefer_rc4 = true;
        enc_level = 1; # Prefer encryption
      };

      # Override user/group
      user = config.services-config.media-stack.user;
      group = config.services-config.media-stack.group;
    };

    # ============================================================================
    # ARIA2 - Download Manager
    # ============================================================================
    services.aria2 = {
      enable = true;

      settings = {
        dir = "${config.services-config.media-stack.downloadsDir}/aria2";

        # RPC
        enable-rpc = true;
        rpc-listen-port = 6800;
        rpc-listen-all = true;

        # Performance
        max-concurrent-downloads = 5;
        max-connection-per-server = 16;
        min-split-size = "10M";
        split = 16;

        # Continue downloads
        continue = true;

        # Save session
        save-session = "/var/lib/aria2/session.gz";
        input-file = "/var/lib/aria2/session.gz";
        save-session-interval = 60;
      };
    };

    # ============================================================================
    # SONARR - TV Shows
    # ============================================================================
    services.sonarr = {
      enable = true;
      user = config.services-config.media-stack.user;
      group = config.services-config.media-stack.group;
    };

    # ============================================================================
    # RADARR - Movies
    # ============================================================================
    services.radarr = {
      enable = true;
      user = config.services-config.media-stack.user;
      group = config.services-config.media-stack.group;
    };

    # ============================================================================
    # PROWLARR - Indexer Manager
    # ============================================================================
    services.prowlarr = {
      enable = true;
    };

    # Fix Prowlarr state directory ownership and permissions
    systemd.services.prowlarr = {
      serviceConfig = {
        User = lib.mkForce config.services-config.media-stack.user;
        Group = lib.mkForce config.services-config.media-stack.group;
        StateDirectory = lib.mkForce "prowlarr";
        StateDirectoryMode = lib.mkForce "0750";
        # Fix NAMESPACE issue with impermanence
        PrivateTmp = lib.mkForce false;
        ProtectSystem = lib.mkForce false;
        ProtectHome = lib.mkForce false;
        ReadWritePaths = [ "/var/lib/prowlarr" ];
      };
    };

  # Ensure data is persisted


  environment.persistence."/persist" = mkIf config.system-config.impermanence.enable {


    directories = [



      config.services-config.media-stack.dataDir


      config.services-config.media-stack.downloadsDir


      "/var/lib/deluge"


      "/var/lib/aria2"


      "/var/lib/sonarr"


      "/var/lib/radarr"


      "/var/lib/prowlarr"


      "/var/lib/lidarr"


      "/var/lib/readarr"


      "/var/lib/bazarr"


      "/var/lib/redis"



    ];


  };

  };
}
