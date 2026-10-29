{
  config,
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
    "intel-13th-gen"
    "gpu-compute"
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
      config.nas-mounts.enable = true;
      virtualization.enable = true;
      sessionResilience.enable = true;
    };
    layer-30.theming.themes.greeter.type = "noctalia-greeter";
    layer-40.desktop.noctalia.idle = {
      dpmsIgnoreAc = true; # Never shut screen off while plugged in to AC power
      lockIgnoreAc = true; # Never lock screen while plugged in to AC power
    };
    desktop = {
      experience = "noctalia";
      noctalia.defaultCompositor = "hyprland";
    };
  };

  # Prevent display power-off / blanking when plugged in
  boot.kernelParams = [ "consoleblank=0" ];

  # ============================================================================
  # 03 - HARDWARE & GRAPHICS (Dell Precision 7680)
  # ============================================================================
  # Intel 13th Gen Raptor Lake UHD (PCI:0:2:0) + Nvidia RTX 1000 Ada (PCI:1:0:0)
  hardware.nvidia = {
    enable = true;
    powerManagement.finegrained = false; # Keep dGPU awake so physical HDMI port receives display clock
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
  # 04 - SERVICES & AI STACK
  # ============================================================================
  services = {
    logind.settings.Login = {
      IdleAction = "ignore";
      LidSwitchExternalPower = "ignore";
    };

    ai-services = {
      ollama = {
        enable = true;
        acceleration = "cuda";
      };
      kong-gateway = {
        enable = false;
      };
      omniroute = {
        enable = false;
        environmentFile = config.sops.templates."omniroute-env".path;
      };
      freellmapi.enable = false;
      freellmpool.enable = false;
    };

    jev-engine = {
      enable = true;
      port = 20130;
      host = "0.0.0.0";
      mode = "local";
    };

    email-triage-daemon = {
      enable = true;
      jevUrl = "http://127.0.0.1:20130";
      himalayaAccount = "wrighterik77";
      confidenceThreshold = 0.80;
      interval = "5m";
    };

    infrastructure.langfuse = {
      enable = true;
      port = 3005;
    };

    polyfloor.enable = true;
    wyoming-services.enable = true;
  };

  layers.layer-71.harness.dream-cycle.enable = true;

  layers.layer-73.memory.task-watcher.enable = true;

  layers.layer-40.desktop.screenpipe.enable = true;

  layers.layer-76.hermes-live-voice.enable = true;

  layers.layer-78.llm-routers.jev-router-plugin = {
    enable = true;
    port = 20127;
    host = "127.0.0.1";
    openFirewall = false;
    upstreamRouterUrl = "http://100.64.0.1:20128";
    jevEngineUrl = "http://127.0.0.1:20130";
    localSlmUrl = "http://127.0.0.1:11434";
  };

  # ============================================================================
  # 05 - SECURITY & SECRETS (SOPS)
  # ============================================================================
  sops = {
    age.keyFile = "/persist/home/t0psh31f/.config/sops/age/keys.txt";
  };
}
