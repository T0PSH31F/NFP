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
      openFirewall = cfg.openFirewall;

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
      };
    };

    # Ensure n8n data directory is persisted
    # This integrates with impermanence if enabled
    environment.persistence."/persist" = mkIf (cfg.enable && config.system-config.impermanence.enable) {
      directories = [
        cfg.dataDir
      ];
    };

    # Fix for STATE_DIRECTORY failure with impermanence
    systemd.services.n8n.serviceConfig = {
      StateDirectory = lib.mkForce [ ]; # Disable systemd management
    };

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
      # For Python nodes
      python3
    ];

    # Optional: Add a systemd service for health monitoring
    systemd.services.n8n-healthcheck = {
      description = "n8n Health Check";
      after = [ "n8n.service" ];
      requires = [ "n8n.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.curl}/bin/curl -sf http://localhost:${toString cfg.port}/healthz || exit 1";
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
