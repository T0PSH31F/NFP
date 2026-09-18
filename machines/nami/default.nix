# nami — Alibaba Elastic Compute (US West-1, us-west-1b) cloud control plane + AI router
# Instance ID : i-rj951wld3zoyv1lr6nk7
# Public IP   : 47.254.90.69
# Private IP  : 172.21.238.38
# SSH key     : id_25519 t0psh31f@ganglib.gang  (~/.ssh/)
#
# Roles: network-router (Headscale, Homepage), ai-router (Kong, Omniroute),
#        agent-orchestrator (Hermes, Mission Control, Paperclip).
# Memory services stay on luffy for privacy. gno runs here (always-on).
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [ ./hardware.nix ];

  networking.hostName = "nami";
  system.stateVersion = "25.05";

  machine.tags = [
    "network-router"
    "ai-router"
    "agent-orchestrator"
    "ai-agent"
  ];

  # Fleet monitoring: scrape node-exporters on z0r0 + luffy via tailnet IPs.
  # Requires tailscale mesh up (control = luffy's headscale via luffy's reverse tunnel).
  layers.layer-20.services.config.monitoring.fleetNodeTargets = [
    "100.64.0.1:9100" # z0r0
    "100.64.0.3:9100" # luffy
  ];

  sops.age.keyFile = "/var/lib/sops/nami/key.txt";

  # === Headscale — fleet VPN control server (via network-router tag) ===
  services.headscale-server = {
    serverUrl = "http://headscale.lovelain.duckdns.org";
  };

  # === Polyfloor AI company OS (talks to Kong on localhost:8090) ===
  services.polyfloor.enable = true;

  # === Privacy-gate: memory services stay on luffy; DNS filtering stays on luffy ===
  services.honcho.enable = lib.mkForce false;
  services.ai-services.brain-service.enable = lib.mkForce false;
  layers.layer-20.services.config.adguard.enable = lib.mkForce false;

  # === Cloud VM: disable media stack, desktop/GUI apps, Firefox C++ build & bulk agent catalog ===
  layers.layer-20.services.config.media-stack.enable = lib.mkForce false;
  layers.layer-20.services.config.nixarr-stack.enable = lib.mkForce false;
  layers.layer-20.services.config.download-clients.enable = lib.mkForce false;
  layers.layer-20.services.communication.camofox-browser.enable = lib.mkForce false;
  layers.layer-76.hermes.enableDesktop = lib.mkForce false;
  layers.layer-71.harness.antigravity.enableIde = lib.mkForce false;
  layers.layer-79.skills.llm-agents-catalog.enable = lib.mkForce false;
  services.aria2.enable = lib.mkForce false;
  services.sabnzbd.enable = lib.mkForce false;
  systemd.services.rclone-gdrive-mount.enable = lib.mkForce false;

  # === gno: retrieval/workspace/graph OCI container (disabled until public image available) ===
  layers.layer-73.memory.gno = {
    enable = false;
    port = 3456;
    dataDir = "/var/lib/gno";
    corpusDir = "/var/lib/gno/corpus"; # Synced from luffy via rsync/cron
  };

  # === Cloud VM: ext4 root, no tmpfs/impermanence ===
  layers.layer-10.system.config.impermanence.enable = lib.mkForce false;

  # === Virtualization: Podman for OCI containers (Omniroute, Mission Control, gno) ===
  virtualisation.podman = {
    enable = true;
    dockerSocket.enable = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  # === AI-router: Kong kept as sole gateway, align freellm ports for side-by-side test ===
  # freellmapi:3001 / freellmpool:8080 are module defaults; Kong previously expected 3003/8083 — align to actual ports
  services.ai-services.kong-gateway.routers.freellmapi.port = lib.mkForce 3001;
  services.ai-services.kong-gateway.routers.freellmpool.port = lib.mkForce 8080;
  services.ai-services.kong-gateway.enable = lib.mkDefault true;

  # === Home Manager: headless cloud host overrides ===
  home-manager.useUserPackages = lib.mkForce false;
  home-manager.users.t0psh31f.dconf.enable = false;

  # === SSH (Alibaba security group: public from admin IP only) ===
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = lib.mkOverride 0 false;
      PermitRootLogin = lib.mkOverride 0 "prohibit-password";
    };
  };

  # === Firewall: SSH + gno + headscale + HTTPS ===
  networking.firewall.allowedTCPPorts = [
    22
    80 # Caddy HTTP (ACME challenges)
    443 # Caddy HTTPS (Headscale, Homepage)
    3456 # gno
    8086 # Headscale API
  ];

  # === Restic backups ===
  layers.layer-20.services.backups.restic.enable = lib.mkDefault true;
}
