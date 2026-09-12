{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.n8n-server;
in
{
  options.services.n8n-server = {
    enable = mkEnableOption "n8n workflow automation platform";

    port = mkOption {
      type = types.port;
      default = 5678;
      description = "Port for n8n web interface";
    };

    webhookUrl = mkOption {
      type = types.str;
      default = "http://localhost:5678";
      description = "Public URL for webhooks (set to your domain for external access)";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/n8n";
      description = "Directory to store n8n data";
    };

    timezone = mkOption {
      type = types.str;
      default = "America/Los_Angeles";
      description = "Timezone for scheduled nodes (Cron, etc.)";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Open firewall port for n8n";
    };
  };

  config = mkIf cfg.enable {
    # Use the built-in n8n NixOS module
    services.n8n = {
      enable = true;
      inherit (cfg) openFirewall;

      environment = {
        # Server configuration
        port = toString cfg.port;
        protocol = "http";

        # Webhook configuration
        WEBHOOK_URL = cfg.webhookUrl;

        # Timezone for cron/scheduler nodes
        GENERIC_TIMEZONE = cfg.timezone;

        # Execution settings
        EXECUTIONS_DATA_SAVE_ON_ERROR = "all";
        EXECUTIONS_DATA_SAVE_ON_SUCCESS = "all";
        EXECUTIONS_DATA_SAVE_ON_PROGRESS = "true";
        EXECUTIONS_DATA_SAVE_MANUAL_EXECUTIONS = "true";

        # Queue mode for better performance (optional)
        # EXECUTIONS_MODE = "queue";

        # Workaround for nixpkgs bug where default null raises "cannot coerce null to a string"
        N8N_RUNNERS_AUTH_TOKEN_FILE = lib.mkForce "/dev/null";
      };
    };

    # Ensure data is persisted
    environment.persistence."/persist" = mkIf config.layers.layer-10.system.config.impermanence.enable {
      directories = [
        {
          directory = cfg.dataDir;
          user = "n8n";
          group = "n8n";
          mode = "0700";
        }
      ];
    };

    # Fix for STATE_DIRECTORY failure with impermanence
    systemd.services.n8n = {
      wants = [ "network-online.target" ];
      after = [
        "network-online.target"
        "postgresql.service"
        "persist.mount"
      ];
      serviceConfig = {
        DynamicUser = lib.mkForce false; # Must be false for persistent storage
        User = "n8n";
        Group = "n8n";
        StateDirectory = lib.mkForce [ ];
        ReadWritePaths = [ cfg.dataDir ];
        # Robustness
        Restart = lib.mkForce "always";
        RestartSec = lib.mkForce "10s";
        StartLimitIntervalSec = 0;
      };
    };

    # Ensure the user exists since DynamicUser is disabled
    users.users.n8n = {
      isSystemUser = true;
      group = "n8n";
      home = cfg.dataDir;
    };
    users.groups.n8n = { };

    systemd.tmpfiles.rules = [
      "d /persist${cfg.dataDir} 0700 n8n n8n -"
      "d ${cfg.dataDir} 0700 n8n n8n -"
    ];

    # Additional packages for n8n integrations
    environment.systemPackages = with pkgs; [
      # For executing shell commands in workflows
      bash
      curl
      jq
      nodejs
      python3
      # For Python nodes
    ];

    # Optional: Add a systemd service for health monitoring
    systemd.services.n8n-healthcheck = {
      description = "n8n Health Check";
      after = [ "n8n.service" ];
      requires = [ "n8n.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.curl}/bin/curl --max-time 10 -sf http://localhost:${toString cfg.port}/healthz";
      };
    };

    # Timer for periodic health checks
    systemd.timers.n8n-healthcheck = {
      description = "n8n Health Check Timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*:0/5"; # Every 5 minutes
        Persistent = true;
      };
    };
  };
}
