{
  config,
  lib,
  pkgs,
  ...
}:
{
  # ============================================================================
  # 00 - CORE IMPORTS
  # ============================================================================
  imports = [
    ./hardware.nix

    ../../layers/10-system/13-users/t0psh31f.nix
  ];

  # ============================================================================
  # 01 - MACHINE IDENTITY
  # ============================================================================
  networking.hostName = "sanji";
  system.stateVersion = "26.05";

  # Bootloader (systemd-boot with EFI)
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # ----------------------------------------------------------------------------
  # AVAILABLE PROFILES / TAGS
  # ----------------------------------------------------------------------------
  # desktop: Noctalia-Hyprland, wayland portals, pipewire, blueman, GUI packages
  # workstation: base limits, themes, networking (tailscale, ssh)
  # laptop: battery optimizations, brightnessctl, power-profiles
  # development: coding tools, VSCode, python, git
  # ai-router: Kong Gateway, OmniRoute, FreeLLMAPI, FreeLLMPool
  # ai-inference: Ollama local LLM runtime
  # agent-orchestrator: Hermes, MCP, agent sandboxes, Mission Control, Polyfloor
  # ----------------------------------------------------------------------------
  machine.tags = [
    "desktop"
    "workstation"
    "laptop"
    "development"
    "ai-router"
    "ai-inference"
    "agent-orchestrator"
  ];

  programs.herdr.enable = true;

  # ============================================================================
  # 02 - LAYERED FEATURE FLAGS (Overrides)
  # ============================================================================
  layers = {
    layer-10.system = {
      hardware.kernel = "zen";
      mobile.android.enable = true;
      config.impermanence.enable = true;
      config.nas-mount.enable = false;
      virtualization.enable = true;
      sessionResilience.enable = true;
    };
    layer-30.theming.themes.greeter.type = "tuigreet";
    layer-40.desktop.noctalia.idle = {
      dpmsIgnoreAc = true; # Never shut screen off while plugged in to AC power
    };
    desktop.experience = "noctalia-hyprland";
  };

  # Prevent display power-off / blanking when plugged in
  boot.kernelParams = [ "consoleblank=0" ];
  services.logind.settings.Login = {
    IdleAction = "ignore";
    LidSwitchExternalPower = "ignore";
  };

  # ============================================================================
  # 03 - HARDWARE & GRAPHICS (Dell Precision 7680)
  # ============================================================================
  # Intel 13th Gen Raptor Lake UHD (PCI:0:2:0) + Nvidia RTX 1000 Ada (PCI:1:0:0)
  hardware.nvidia = {
    enable = true;
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # ============================================================================
  # 04 - AI ROUTER & LOCAL INFERENCE STACK (Migrated from nami/luffy)
  # ============================================================================
  # Local inference on RTX 1000 Ada (4GB VRAM) for 2B-3B abliterated/uncensored models
  services.ai-services.ollama = {
    enable = true;
    acceleration = "cuda";
  };

  # Always-on AI router stack
  services.ai-services = {
    kong-gateway.enable = true;
    omniroute.enable = true;
    freellmapi.enable = true;
    freellmpool.enable = true;
  };

  # OmniRoute credential sync from ExtremeRouter
  services.ai-services.omniroute.environmentFile = config.sops.templates."omniroute-env".path;

  # Kong router listener and upstream alignment
  services.ai-services.kong-gateway.routers.extreme-router.host = "100.64.0.1";
  services.ai-services.kong-gateway.routers.freellmapi.port = lib.mkForce 3001;
  services.ai-services.kong-gateway.routers.freellmpool.port = lib.mkForce 8080;

  # Jev System-1 Decision Engine & Discriminative LLM Router Pre-Flight Hook
  services.jev-engine = {
    enable = true;
    port = 20130;
    host = "0.0.0.0";
    mode = "local";
  };

  layers.layer-78.llm-routers.jev-router-plugin = {
    enable = true;
    port = 20127;
    upstreamRouterUrl = "http://127.0.0.1:8090";
    jevEngineUrl = "http://127.0.0.1:20130";
    localSlmUrl = "http://127.0.0.1:11434";
  };

  # Autonomous Email Triage Daemon (Himalaya IMAP & Maildir)
  services.email-triage-daemon = {
    enable = true;
    jevUrl = "http://127.0.0.1:20130";
    himalayaAccount = "wrighterik77";
    confidenceThreshold = 0.80;
    interval = "5m";
  };

  # Langfuse LLM Observability & Tracing Platform
  services.infrastructure.langfuse = {
    enable = true;
    port = 3005;
  };

  # Polyfloor agent company OS (talks to Kong on localhost:8090)
  services.polyfloor.enable = true;

  # ============================================================================
  # 05 - SECURITY & SECRETS (SOPS)
  # ============================================================================
  sops = {
    age.keyFile = "/persist/home/t0psh31f/.config/sops/age/keys.txt";
  };
}
