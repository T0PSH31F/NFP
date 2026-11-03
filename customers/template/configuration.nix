# Multi-Tenant Customer Profile Template (jarvis-fleet)
# Bound to Clan-Core inventory and SOPS-Nix secret management.
{
  lib,
  pkgs,
  ...
}:
{
  jarvis = {
    enable = true;
    customerName = "Acme Services Corp";
    customerSlug = "acme-services";
    desktopChoice = "headless";
    deploymentTarget = "proxmox-qcow2";

    branding = {
      enable = true;
      productName = "Acme AI Manager";
      logoPath = null;
      primaryColor = "#0A2540";
      accentColor = "#00D4B6";
      supportContact = "help@acmecorp.com";
      personaName = "Acme Concierge";
    };

    quotas = {
      enable = true;
      roles = {
        junior = {
          tier0Unlimited = true;
          tier1DailyUsd = 1.0;
          tier2MonthlyUsd = 0.0;
        };
        senior = {
          tier0Unlimited = true;
          tier1DailyUsd = 10.0;
          tier2MonthlyUsd = 150.0;
        };
        exec = {
          tier0Unlimited = true;
          tier1DailyUsd = 100.0;
          tier2MonthlyUsd = 1000.0;
        };
      };
    };

    backup = {
      enable = true;
      replicaUrl = "file:///mnt/nas/backups/acme-services";
      monthlyFeeUsd = 499.0;
    };
  };

  layers.layer-10.system.config.security-hardening.enable = true;

  networking.hostName = lib.mkDefault "jarvis-acme-services";
  system.stateVersion = lib.mkDefault "25.05";

  environment.systemPackages = with pkgs; [
    curl
    jq
    sqlite
    bubblewrap
  ];
}
