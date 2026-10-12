# Tier: 22-ai
# Module: lead-triage-webhook.nix
# Purpose: Autonomous Inbound Lead Qualification & Deal Triage Webhook via Jev System-1.
# Option Path: services.lead-triage-webhook
# Enabling Host Tags: homelab, ai-server
# RAM Footprint: light (<100MB)
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.lead-triage-webhook;
in
{
  options.services.lead-triage-webhook = {
    enable = lib.mkEnableOption "Jev Autonomous Inbound Lead Qualification & Deal Triage Webhook";

    port = lib.mkOption {
      type = lib.types.port;
      default = 20131;
      description = "Port to listen on for inbound lead intake webhooks";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      description = "Host IP address to bind to";
    };

    jevUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://127.0.0.1:20130";
      description = "Endpoint URL for local Jev decision engine";
    };

    calcomUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://cal.com/topsh31f/discovery";
      description = "Cal.com automated booking link dispatched to hot leads";
    };

    ntfyUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://127.0.0.1:8099/ops-leads";
      description = "ntfy notification endpoint for urgent lead alerts";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/lead-triage";
      description = "Directory where lead records, hot lead cards, and review queues are stored";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open port in firewall";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.lead-triage-webhook = {
      description = "Jev Inbound Lead Qualification & Deal Triage Webhook";
      after = [
        "network.target"
        "jev-engine.service"
      ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        LEAD_WEBHOOK_HOST = cfg.host;
        LEAD_WEBHOOK_PORT = toString cfg.port;
        JEV_ENGINE_URL = cfg.jevUrl;
        CALCOM_URL = cfg.calcomUrl;
        NTFY_URL = cfg.ntfyUrl;
        LEAD_STORAGE_DIR = toString cfg.dataDir;
      };

      serviceConfig = {
        ExecStart = "${pkgs.python3}/bin/python3 ${./lead-triage-webhook.py}";
        Restart = "on-failure";
        RestartSec = 5;
        DynamicUser = true;
        StateDirectory = "lead-triage";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];

    environment.persistence."/persist" =
      lib.mkIf (config.layers.layer-10.system.config.impermanence.enable or false)
        {
          directories = [
            {
              directory = "/var/lib/lead-triage";
              mode = "0750";
            }
          ];
        };
  };
}
