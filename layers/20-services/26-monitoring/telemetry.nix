# OpenTelemetry Fleet Telemetry Pipeline Module
# Integrates with mrVanDalo/nixos-telemetry and standard OTel Collector
{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.layers.layer-20.services.config.telemetry;
  isLuffy = config.networking.hostName == "luffy";
in
{
  options.layers.layer-20.services.config.telemetry = {
    enable = mkEnableOption "OpenTelemetry-native fleet telemetry pipeline";

    role = mkOption {
      type = types.enum [
        "agent"
        "server"
        "standalone"
      ];
      default = if isLuffy then "server" else "agent";
      description = "Node role in the fleet telemetry topology (server aggregates on luffy, agents push from z0r0/sanji)";
    };

    otlpGrpcPort = mkOption {
      type = types.port;
      default = 4317;
      description = "OpenTelemetry Collector OTLP/gRPC port";
    };

    otlpHttpPort = mkOption {
      type = types.port;
      default = 4318;
      description = "OpenTelemetry Collector OTLP/HTTP port";
    };

    remoteCollector = mkOption {
      type = types.str;
      default = "luffy.nfp.nix:4317";
      description = "Remote OpenTelemetry collector endpoint for agent nodes";
    };

    prometheusEndpoint = mkOption {
      type = types.str;
      default = "http://127.0.0.1:9090/api/v1/write";
      description = "Prometheus metrics write endpoint (server mode)";
    };

    lokiEndpoint = mkOption {
      type = types.str;
      default = "http://127.0.0.1:3100/loki/api/v1/push";
      description = "Loki logs push endpoint (server mode)";
    };

    tracesEndpoint = mkOption {
      type = types.str;
      default = "http://luffy.nfp.nix:3000/api/public/otel/v1/traces";
      description = "Langfuse / Grafana Alloy OTLP traces destination";
    };
  };

  config = mkIf cfg.enable {
    # ── mrVanDalo/nixos-telemetry Integration ──────────────────────────
    telemetry = {
      enable = true;
      alloy.enable = true; # Scrapes journal logs via Grafana Alloy

      # Server role runs local sinks (Prometheus, Loki, Grafana)
      prometheus.enable = mkDefault (cfg.role == "server" || cfg.role == "standalone");
      loki.enable = mkDefault (cfg.role == "server" || cfg.role == "standalone");
      grafana.enable = mkDefault (cfg.role == "server" || cfg.role == "standalone");

      opentelemetry = {
        receiver.endpoint = mkIf (
          cfg.role == "server" || cfg.role == "standalone"
        ) "0.0.0.0:${toString cfg.otlpGrpcPort}";
        exporter.endpoints = mkIf (cfg.role == "agent") {
          fleet = cfg.remoteCollector;
        };
      };
    };

    # ── Firewall Rules (Tailnet) ───────────────────────────────────────
    networking.firewall.interfaces."tailscale0" = {
      allowedTCPPorts = [
        cfg.otlpGrpcPort
        cfg.otlpHttpPort
        8888 # OTel Collector metrics/health
      ];
    };

    # ── Service Contract for Homepage & Healthcheck ───────────────────
    nfp.services.opentelemetry-collector = {
      enable = true;
      host = config.networking.hostName;
      bind = "0.0.0.0";
      port = cfg.otlpHttpPort;
      tailnetName = "otel";
      tls = "none";
      healthcheck = {
        enable = true;
        path = "/";
        expectedStatus = [
          200
          404
        ];
      };
      homepage = {
        enable = true;
        category = "monitoring";
        order = 45;
        title = "OpenTelemetry";
        subtitle = "Fleet Telemetry Hub";
        icon = "opentelemetry";
        metric = {
          mode = "contract-sensor";
          adapter = "otel";
          fields = [
            "spans_received"
            "metrics_exported"
            "active_nodes"
          ];
        };
      };
    };
  };
}
