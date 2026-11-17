# Security Hardening & Malware Protection
# Non-breaking kernel sysctls, ClamAV signature updates, and optional scheduled scanning.
{
  config,
  lib,
  pkgs,
  options,
  ...
}:
let
  cfg = config.layers.layer-10.system.security;
in
{
  options.layers.layer-10.system.security = {
    clamavDaemon = lib.mkEnableOption "ClamAV resident daemon and nightly scheduled scan";
  };

  config = {
    # Security audit & on-demand scanning CLI tools available on all fleet nodes
    environment.systemPackages = with pkgs; [
      clamav
      lynis
    ];

    # Keep ClamAV signature databases updated on all machines (zero idle daemon RAM unless clamavDaemon = true)
    services.clamav = {
      updater.enable = true;
      daemon = lib.mkIf cfg.clamavDaemon {
        enable = true;
        settings = {
          MaxThreads = 2;
          LogTime = true;
        };
      };
      scanner = lib.mkIf cfg.clamavDaemon {
        enable = true;
        interval = "*-*-* 04:00:00";
        scanDirectories = [
          "/home"
          "/tmp"
          "/var/tmp"
          "/var/lib/calibre-web"
          "/var/lib/filebrowser"
          "/storage/Media/qbittorrent"
        ];
      };
    };

    systemd.services.clamav-daemon = lib.mkIf cfg.clamavDaemon {
      serviceConfig = {
        MemoryHigh = "2G";
        Nice = 19;
        IOSchedulingClass = "idle";
      };
    };

    # Kernel & network stack security sysctls (Tailscale-compatible loose RPF = 2)
    # Priority 900 overrides nixpkgs mkDefault (1000) while still letting host/service configs override.
    boot.kernel.sysctl = lib.mapAttrs (_: lib.mkOverride 900) {
      "kernel.kptr_restrict" = 2;
      "kernel.dmesg_restrict" = 1;
      "kernel.unprivileged_bpf_disabled" = 1;
      "kernel.yama.ptrace_scope" = 1;
      "fs.protected_fifos" = 2;
      "fs.protected_regular" = 2;
      "fs.suid_dumpable" = 0;
      "net.ipv4.conf.all.rp_filter" = 2;
      "net.ipv4.conf.default.rp_filter" = 2;
      "net.ipv4.conf.all.accept_redirects" = 0;
      "net.ipv4.conf.default.accept_redirects" = 0;
      "net.ipv6.conf.all.accept_redirects" = 0;
      "net.ipv6.conf.default.accept_redirects" = 0;
      "net.ipv4.conf.all.send_redirects" = 0;
      "net.ipv4.conf.default.send_redirects" = 0;
      "net.ipv4.conf.all.accept_source_route" = 0;
      "net.ipv6.conf.all.accept_source_route" = 0;
      "net.ipv4.tcp_syncookies" = 1;
    };
  }
  // lib.optionalAttrs (options.environment ? persistence) {
    environment.persistence."/persist" =
      lib.mkIf (config.layers.layer-10.system.config.impermanence.enable or false)
        {
          directories = [
            {
              directory = "/var/lib/clamav";
              user = "clamav";
              group = "clamav";
              mode = "0755";
            }
          ];
        };
  };
}
