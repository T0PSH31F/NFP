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
  networking.hostName = "z0r0";
  system.stateVersion = "25.05";

  # Use GRUB for better reliability with this specific hardware/impermanence setup
  boot.loader = {
    systemd-boot.enable = lib.mkForce true;
    efi.canTouchEfiVariables = true;
    # grub = {
    #  enable = true;
    #  device = "nodev";
    #  efiSupport = true;
    #  useOSProber = true;
  };
  boot.kernelParams = [ "i915.enable_psr=0" ];

  # ----------------------------------------------------------------------------
  # AVAILABLE PROFILES / TAGS
  # ----------------------------------------------------------------------------
  # Tags define the machine's role and automatically enable corresponding features.
  # See `layers/90-profiles/tags/` for explicit definitions.
  #
  # Hardware/Form Factor:
  #   "workstation" : Enables base limits, themes, and network tools (avahi, tailscale, ssh).
  #   "desktop"     : Enables graphical hardware features (bluetooth), automount, portals, flatpak.
  #   "laptop"      : Enables battery optimizations and wireless tools.
  #
  # Roles:
  #   "development" : Enables coding tools, Python, VSCode, and dev agents (Opencode, Antigravity).
  #   "gaming"      : Enables Steam, GameMode, Lutris, emulators, etc.
  #   "ai-server"   : Enables local AI backend (llms, sillytavern, wyoming, ai-services, dashboard).
  #   "homelab"     : Enables home infra (home-assistant, searxng, headscale, vaultwarden, etc).
  #   "cache-server": Enables Harmonia Nix binary cache.
  #   "media-server": Enables the *arr stack, Jellyfin, Deluge, etc.
  # ----------------------------------------------------------------------------

  # ============================================================================
  # 02 - LAYERED FEATURE FLAGS (Overrides)
  # ============================================================================
  # Note: Most features are automatically enabled via machine.tags -> 90-profiles
  layers = {
    layer-10.system = {
      hardware.kernel = "zen"; # Zen kernel for z0r0 laptop workstation
      peripherals.corsair.enable = true;
      peripherals.openrgb.enable = true;
      peripherals.razer.enable = lib.mkForce false; # Disabled: openrazer driver incompatible with linux 7.0.10
      mobile.android.enable = true;
      mobile.ios.enable = true;
      config.impermanence.enable = true;
      virtualization.enable = true;
      sessionResilience.enable = true;
    };
  };

  services = {
    # z0r0 is a desktop workstation — no always-on server services.
    # These modules default to enable=true in their own definitions,
    # so we override to false. The new tag system means z0r0 no longer
    # gets ai-server/ai-agent tag-driven enables, but module defaults
    # still need explicit disabling. Fix upstream (mkDefault false in
    # modules) to eliminate these overrides.
    llama-cpp-server.enable = lib.mkForce false;
    llama-swap.enable = lib.mkForce false;
    wyoming-services.enable = lib.mkForce false;

    ai-services = {
      ollama.enable = lib.mkForce false;
      open-webui.enable = lib.mkForce false;
      localai.enable = lib.mkForce false;
      chromadb.enable = lib.mkForce false;
    };
  };

  layers.layer-20.services.communication.rustdesk = {
    enable = true;
    client.enable = true;
    server.enable = false;
  };

  # Glances server for cross-machine system metrics
  services.glances-server.enable = true;

  # Netdata real-time monitoring
  layers.layer-20.services.config.netdata.enable = true;

  systemd.services.rclone-gdrive-mount.enable = false;

  clan.core.postgresql.enable = true;

  # ============================================================================
  # 05 - SECURITY & SECRETS (SOPS/ACME)
  # ============================================================================
  sops = {
    age.keyFile = "/persist/home/t0psh31f/.config/sops/age/keys.txt";
  };

  # Matrix homeserver (luffy) reachable via Tailnet MagicDNS (nfp.nix)
  # Historical extraHosts with raw 100.72 retained only for matrix.local bootstrap
  # (matrix.local flagged as later migration per Hermes task — do not extend)
  networking.extraHosts = ''
    ${config.layers.meta.fleetAddresses.luffy} matrix.local element.local
    ${config.layers.meta.fleetAddresses.luffy} luffy.d luffy-1
  '';

  # ============================================================================
  # 06 - STORE INTEGRITY & SAFE GARBAGE COLLECTION
  # ============================================================================
  # BUG (nixpkgs unstable): util-linux-2.42-bin contains symlinks to sibling
  # outputs (mount, login, swap) but nix's reference metadata does NOT track
  # them as references. This means `nix-store --gc` sees these outputs as
  # unreferenced garbage and DELETES them, even though the live system needs
  # them at boot. When they're missing, prepare-root fails with
  # "mount: command not found" and the entire boot cascades to failure
  # (impermanence bind-mounts fail, /boot won't mount, firewall fails, etc).
  #
  # This happened on 2026-06-19 after forceful nix-store --gc runs.
  # See RECOVERY_NOTE.md and docs/AGENT_ONBOARDING.md for full details.
  #
  # FIX: Create gcroots for all util-linux bin symlink targets at every
  # activation so nix-store --gc preserves them. This is scoped to z0r0
  # only (luffy has the same vulnerability but is left untouched per user
  # request — consider applying the same fix to luffy in the future).

  system.activationScripts.gcroot-util-linux = ''
    mkdir -p /nix/var/nix/gcroots
    _ulbin="${pkgs.util-linux.bin}"
    if [ -d "$_ulbin/bin" ]; then
      for link in "$_ulbin"/bin/*; do
        [ -L "$link" ] || continue
        target=$(readlink -f "$link" 2>/dev/null) || continue
        case "$target" in
          /nix/store/*)
            storepath=$(echo "$target" | cut -d/ -f1-4)
            name=$(basename "$storepath")
            ln -sfn "$storepath" "/nix/var/nix/gcroots/util-linux-fix-$name"
            ;;
        esac
      done
    fi
  '';

  system.activationScripts.clean-boot-entries = ''
    if [ -d /boot/loader/entries ]; then
      for f in /boot/loader/entries/*.conf; do
        [ -f "$f" ] || continue
        init_path=$(${pkgs.gnugrep}/bin/grep -E 'options.*init=' "$f" | ${pkgs.gnused}/bin/sed -E 's/.*init=([^ ]+).*/\1/')
        if [ -n "$init_path" ] && [ ! -e "$init_path" ]; then
          echo "Pruning orphan boot entry: $f (init $init_path missing)"
          rm -f "$f"
        fi
      done
    fi
  '';

  # Safe automatic garbage collection — only removes old generations,
  # never unreferenced paths that might have broken reference metadata.
  systemd.services.nix-safe-gc = {
    description = "Safe Nix GC (old generations only, preserves unreferenced-but-needed paths)";
    startAt = "Sun 04:00";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.nix}/bin/nix-collect-garbage --delete-older-than 14d";
      Nice = 19;
      IOSchedulingClass = "idle";
    };
  };

  # Provide a safe-gc convenience script so the user doesn't reach for
  # the dangerous `nix-store --gc` out of habit.
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "nix-safe-gc" ''
      echo "Running safe garbage collection (deleting generations older than ''${1:-14d})..."
      ${pkgs.nix}/bin/nix-collect-garbage --delete-older-than "''${1:-14d}"
      if [ -d /boot/loader/entries ]; then
        echo "Pruning orphan boot entries..."
        for f in /boot/loader/entries/*.conf; do
          [ -f "$f" ] || continue
          init_path=$(grep -E 'options.*init=' "$f" | sed -E 's/.*init=([^ ]+).*/\1/')
          if [ -n "$init_path" ] && [ ! -e "$init_path" ]; then
            echo "Removing orphan entry: $f"
            sudo rm -f "$f"
          fi
        done
      fi
      echo "Done. No unreferenced-but-needed paths were harmed."
    '')
  ];
}
