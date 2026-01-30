{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  imports = [
    ./nvidia.nix
    ./hardware.nix
    # ./amd.nix
    ./intel.nix
    ./audio.nix
    ./bluetooth.nix
    ./touchpad.nix
    ./razer.nix
  ];

  # Common hardware support
  hardware = {
    # Enable redistributable firmware only
    enableRedistributableFirmware = true;

    # CPU microcode updates
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    # cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    # Graphics support
    graphics = {
      enable = true;

      # Common graphics packages
      extraPackages = with pkgs; [
        intel-media-driver # Intel VAAPI
        intel-vaapi-driver
        libva-vdpau-driver
        libvdpau-va-gl
        intel-compute-runtime # Intel OpenCL
      ];

      extraPackages32 = with pkgs.pkgsi686Linux; [
        intel-vaapi-driver
        libva-vdpau-driver
        libvdpau-va-gl
      ];
    };

    # USB support
    usb-modeswitch.enable = true;

    # Sensor support (for laptops)
    sensor.iio.enable = true;
  };

  # Kernel modules
  boot.kernelModules = [
    # Virtualization
    "kvm-intel"
    # "kvm-amd"

    # USB
    "usbhid"

    # Network
    "iwlwifi"
  ];

  # Power management
  powerManagement = {
    enable = true;
    cpuFreqGovernor = lib.mkDefault "performance";
  };

  # ==========================================================================
  # MEMORY MANAGEMENT & SYSTEM STABILITY
  # ==========================================================================

  # Zram - compressed swap in RAM (prevents disk thrashing)
  zramSwap = {
    enable = true;
    algorithm = "zstd"; # Best compression ratio
    memoryPercent = 50; # Use up to 50% of RAM for compressed swap
    priority = 100; # Higher priority than disk swap
  };

  # Kernel parameters for better memory management
  boot.kernel.sysctl = {
    # Increase swappiness - prefer compressed zram swap
    "vm.swappiness" = 100;

    # Improve responsiveness under memory pressure
    "vm.vfs_cache_pressure" = 100;

    # Increase inotify watches for file-heavy workloads
    "fs.inotify.max_user_watches" = 524288;

    # Better handling of memory-mapped files
    "vm.dirty_ratio" = 10;
    "vm.dirty_background_ratio" = 5;

    # Prevent OOM killer from killing important processes too late
    "vm.oom_kill_allocating_task" = 1;
  };

  services = {
    # Thermal management
    thermald.enable = mkDefault true;

    # Automatic CPU frequency scaling
    auto-cpufreq = {
      enable = false; # Disabled by default, conflicts with power-profiles-daemon
      settings = {
        battery = {
          governor = "powersave";
          turbo = "never";
        };
        charger = {
          governor = "performance";
          turbo = "auto";
        };
      };
    };
  };

  # Additional hardware-specific packages
  environment.systemPackages = with pkgs; [
    # Hardware info
    lshw
    hwinfo
    inxi
    dmidecode
    util-linux # provides lscpu
    pciutils # provides lspci
    usbutils # provides lsusb

    # Disk tools
    smartmontools
    hdparm
    nvme-cli

    # CPU tools
    cpufrequtils
    cpupower-gui

    # GPU tools
    mesa-demos
    vulkan-tools

    # Sensors
    lm_sensors

    # Power management
    powertop
    acpi

    # Benchmarking
    stress
    stress-ng
    s-tui
  ];

  # Udev rules for hardware
  services.udev = {
    enable = true;

    extraRules = ''
      # Allow users in wheel group to control backlight
      ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="*", GROUP="wheel", MODE="0664"

      # Allow users in wheel group to control LEDs
      ACTION=="add", SUBSYSTEM=="leds", KERNEL=="*", GROUP="wheel", MODE="0664"

      # Gaming controllers
      SUBSYSTEM=="usb", ATTRS{idVendor}=="045e", ATTRS{idProduct}=="028e", GROUP="wheel", MODE="0664"
      SUBSYSTEM=="usb", ATTRS{idVendor}=="045e", ATTRS{idProduct}=="028f", GROUP="wheel", MODE="0664"
    '';
  };

  # Virtual console configuration
  console = {
    earlySetup = true;
    font = lib.mkDefault "${pkgs.terminus_font}/share/consolefonts/ter-132n.psf.gz";
    packages = [ pkgs.terminus_font ];
  };

  # System services configuration
  services = {
    # Display server
    xserver = {
      enable = true;
      # Keyboard layout
      xkb = {
        layout = "us";
        variant = "";
        options = "caps:escape,compose:ralt";
      };
    };

    # Touchpad support
    libinput = {
      enable = true;
      touchpad = {
        naturalScrolling = true;
        tapping = true;
        clickMethod = "clickfinger";
      };
    };

    # Network
    resolved = {
      enable = true;
      dnssec = lib.mkDefault "true";
      domains = [ "~." ];
      fallbackDns = [
        "1.1.1.1"
        "8.8.8.8"
        "1.0.0.1"
        "8.8.4.4"
      ];
    };

    # Power management
    power-profiles-daemon.enable = true;
    upower = {
      enable = true;
      percentageLow = 15;
      percentageCritical = 5;
      percentageAction = 3;
    };

    # System monitoring
    smartd = {
      enable = true;
      autodetect = true;
    };

    # File indexing and search
    locate = {
      enable = true;
      interval = "daily";
      package = pkgs.plocate;
    };

    # Backup service (optional)
    restic = {
      backups = {
        # Example backup configuration
        # home = {
        #   paths = [ "/home/${cfg.user}" ];
        #   repository = "/backup/restic";
        #   passwordFile = "/etc/restic/password";
        #   timerConfig = {
        #     OnCalendar = "daily";
        #     Persistent = true;
        #   };
        #   pruneOpts = [
        #     "--keep-daily 7"
        #     "--keep-weekly 4"
        #     "--keep-monthly 12"
        #   ];
        # };
      };
    };

    # Firewall
    fail2ban = {
      enable = true;
      maxretry = 3;
      bantime = "1h";
      bantime-increment.enable = true;
    };

    # System maintenance
    fstrim = {
      enable = true;
      interval = "weekly";
    };

    # Scheduled tasks
    cron = {
      enable = true;
      systemCronJobs = [
        # Example: Update system database daily
        # "0 3 * * * root ${pkgs.nix-index}/bin/nix-index"
      ];
    };

    # Syncthing for file synchronization
    syncthing = {
      enable = true;
      user = "t0psh31f";
      dataDir = "/home/t0psh31f/Documents";
      configDir = "/home/t0psh31f/.config/syncthing";
    };

    # GVFS for mounting and trash support
    gvfs.enable = true;

    # Thumbnail generation
    tumbler.enable = true;

    # System daemons
    dbus = {
      enable = true;
      packages = with pkgs; [ dconf ];
    };

    # ACPI daemon for power management
    acpid.enable = true;

    # Automatic upgrades (disabled by default)
    # system.autoUpgrade = {
    #   enable = true;
    #   allowReboot = false;
    #   dates = "04:00";
    #   flake = "/etc/nixos#omnixy";
    # };

    # Earlyoom - proactive OOM killer (prevents system freeze)
    earlyoom = {
      enable = true;
      freeMemThreshold = 15; # Kill when free RAM < 15%
      freeSwapThreshold = 15; # Kill when free swap < 15%
      enableNotifications = true; # Desktop notifications on kill
      extraArgs = [
        "--prefer"
        "^(Web Content|chromium|firefox|electron)$" # Prefer killing browsers
        "--avoid"
        "^(Hyprland|waybar|sshd|systemd)$" # Avoid killing critical
      ];
    };

    # Ananicy-cpp - auto nice daemon for better process prioritization
    # ananicy-cpp = {
    #   enable = true;
    #   package = pkgs.ananicy-cpp;
    #   rulesProvider = pkgs.ananicy-rules-cachyos; # CachyOS rules are well-maintained
    # };

    # Logrotate
    logrotate = {
      enable = true;
      settings = {
        "/var/log/grandlix/*.log" = {
          frequency = "weekly";
          rotate = 4;
          compress = true;
          delaycompress = true;
          notifempty = true;
          create = "644 root root";
        };
      };
    };

    # System notifications over DBus
    systembus-notify.enable = lib.mkForce true;
  };

  # Systemd services
  systemd = {
    # User session environment
    user.extraConfig = ''
      DefaultEnvironment="PATH=/run/wrappers/bin:/home/t0psh31f/.nix-profile/bin:/etc/profiles/per-user/t0psh31f/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin"
    '';

    # Automatic cleanup
    timers.clear-tmp = {
      description = "Clear /tmp weekly";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true;
      };
    };

    services.clear-tmp = {
      description = "Clear /tmp directory";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.coreutils}/bin/find /tmp -type f -atime +7 -delete";
      };
    };
  };

  # Security policies
  security = {
    polkit = {
      enable = true;
      extraConfig = ''
        /* Allow members of wheel group to manage systemd services without password */
        polkit.addRule(function(action, subject) {
          if (action.id == "org.freedesktop.systemd1.manage-units" &&
              subject.isInGroup("wheel")) {
            return polkit.Result.YES;
          }
        });
      '';
    };

    # AppArmor
    apparmor = {
      enable = true;
      packages = with pkgs; [
        apparmor-utils
        apparmor-profiles
      ];
    };
  };
}
