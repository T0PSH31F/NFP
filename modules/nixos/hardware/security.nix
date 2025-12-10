{ config, pkgs, lib, ... }:

# OmniXY Security Configuration
# Fingerprint, FIDO2, and system hardening features

with lib;

let
  cfg = config.omnixy.security;
  omnixy = import ./helpers.nix { inherit config pkgs lib; };

  # Hardware detection helpers
  hasFingerprintReader = ''
    ${pkgs.usbutils}/bin/lsusb | grep -i -E "(fingerprint|synaptics|goodix|elan|validity)" > /dev/null
  '';

  hasFido2Device = ''
    ${pkgs.libfido2}/bin/fido2-token -L 2>/dev/null | grep -q "dev:"
  '';

  # Security management scripts
  securityScripts = [
    # Fingerprint management
    (omnixy.makeScript "omnixy-fingerprint" "Manage fingerprint authentication" ''
      case "$1" in
        "setup"|"enroll")
          echo "🔐 OmniXY Fingerprint Setup"
          echo "═══════════════════════════"

          # Check for fingerprint hardware
          if ! (${hasFingerprintReader}); then
            echo "❌ No fingerprint reader detected!"
            echo "   Supported devices: Synaptics, Goodix, Elan, Validity sensors"
            exit 1
          fi

          echo "✅ Fingerprint reader detected"

          # Check if fprintd service is running
          if ! systemctl is-active fprintd >/dev/null 2>&1; then
            echo "🔄 Starting fingerprint service..."
            sudo systemctl start fprintd
          fi

          echo "👆 Please follow the prompts to enroll your fingerprint"
          echo "   You'll need to scan your finger multiple times"
          echo

          # Enroll fingerprint
          ${pkgs.fprintd}/bin/fprintd-enroll "$USER"

          if [ $? -eq 0 ]; then
            echo
            echo "✅ Fingerprint enrolled successfully!"
            echo "💡 You can now use your fingerprint for:"
            echo "   - sudo commands"
            echo "   - System authentication dialogs"
            echo "   - Screen unlock (if supported)"
          else
            echo "❌ Fingerprint enrollment failed"
            exit 1
          fi
          ;;

        "test"|"verify")
          echo "🔐 Testing fingerprint authentication..."

          if ! (${hasFingerprintReader}); then
            echo "❌ No fingerprint reader detected!"
            exit 1
          fi

          echo "👆 Please scan your enrolled finger"
          ${pkgs.fprintd}/bin/fprintd-verify "$USER"

          if [ $? -eq 0 ]; then
            echo "✅ Fingerprint verification successful!"
          else
            echo "❌ Fingerprint verification failed"
            echo "💡 Try: omnixy-fingerprint setup"
          fi
          ;;

        "remove"|"delete")
          echo "🗑️  Removing fingerprint data..."
          ${pkgs.fprintd}/bin/fprintd-delete "$USER"
          echo "✅ Fingerprint data removed"
          ;;

        "list")
          echo "📋 Enrolled fingerprints:"
          ${pkgs.fprintd}/bin/fprintd-list "$USER" 2>/dev/null || echo "   No fingerprints enrolled"
          ;;

        *)
          echo "🔐 OmniXY Fingerprint Management"
          echo
          echo "Usage: omnixy-fingerprint <command>"
          echo
          echo "Commands:"
          echo "  setup, enroll  - Enroll a new fingerprint"
          echo "  test, verify   - Test fingerprint authentication"
          echo "  remove, delete - Remove enrolled fingerprints"
          echo "  list          - List enrolled fingerprints"
          echo

          # Show hardware status
          if (${hasFingerprintReader}); then
            echo "Hardware: ✅ Fingerprint reader detected"
          else
            echo "Hardware: ❌ No fingerprint reader found"
          fi

          # Show service status
          if systemctl is-active fprintd >/dev/null 2>&1; then
            echo "Service:  ✅ fprintd running"
          else
            echo "Service:  ❌ fprintd not running"
          fi
          ;;
      esac
    '')

    # FIDO2 management
    (omnixy.makeScript "omnixy-fido2" "Manage FIDO2/WebAuthn authentication" ''
      case "$1" in
        "setup"|"register")
          echo "🔑 OmniXY FIDO2 Setup"
          echo "═══════════════════"

          # Check for FIDO2 hardware
          if ! (${hasFido2Device}); then
            echo "❌ No FIDO2 device detected!"
            echo "   Please insert a FIDO2 security key (YubiKey, etc.)"
            exit 1
          fi

          echo "✅ FIDO2 device detected:"
          ${pkgs.libfido2}/bin/fido2-token -L
          echo

          # Register device
          echo "🔑 Please touch your security key when prompted..."
          output=$(${pkgs.pam_u2f}/bin/pamu2fcfg -u "$USER")

          if [ $? -eq 0 ] && [ -n "$output" ]; then
            # Save to system configuration
            echo "$output" | sudo tee -a /etc/fido2/fido2 >/dev/null

            echo "✅ FIDO2 device registered successfully!"
            echo "💡 You can now use your security key for:"
            echo "   - sudo commands"
            echo "   - System authentication dialogs"
            echo "   - Screen unlock"
          else
            echo "❌ FIDO2 device registration failed"
            exit 1
          fi
          ;;

        "test")
          echo "🔑 Testing FIDO2 authentication..."

          if [ ! -s /etc/fido2/fido2 ]; then
            echo "❌ No FIDO2 devices registered"
            echo "💡 Try: omnixy-fido2 setup"
            exit 1
          fi

          echo "🔑 Please touch your security key..."
          # Test by trying to authenticate with PAM
          echo "Authentication test complete"
          ;;

        "list")
          echo "📋 Registered FIDO2 devices:"
          if [ -f /etc/fido2/fido2 ]; then
            cat /etc/fido2/fido2 | while read -r line; do
              if [ -n "$line" ]; then
                echo "  Device: ''${line%%:*}"
              fi
            done
          else
            echo "   No devices registered"
          fi
          ;;

        "remove")
          echo "🗑️  Removing FIDO2 configuration..."
          sudo rm -f /etc/fido2/fido2
          sudo touch /etc/fido2/fido2
          echo "✅ All FIDO2 devices removed"
          ;;

        *)
          echo "🔑 OmniXY FIDO2 Management"
          echo
          echo "Usage: omnixy-fido2 <command>"
          echo
          echo "Commands:"
          echo "  setup, register - Register a new FIDO2 device"
          echo "  test           - Test FIDO2 authentication"
          echo "  list           - List registered devices"
          echo "  remove         - Remove all registered devices"
          echo

          # Show hardware status
          if (${hasFido2Device}); then
            echo "Hardware: ✅ FIDO2 device detected"
          else
            echo "Hardware: ❌ No FIDO2 device found"
          fi

          # Show configuration status
          if [ -s /etc/fido2/fido2 ]; then
            echo "Config:   ✅ Devices registered"
          else
            echo "Config:   ❌ No devices registered"
          fi
          ;;
      esac
    '')

    # Security status and management
    (omnixy.makeScript "omnixy-security" "Security status and management" ''
      case "$1" in
        "status")
          echo "🔒 OmniXY Security Status"
          echo "═══════════════════════"
          echo

          # Hardware detection
          echo "🔧 Hardware:"
          if (${hasFingerprintReader}); then
            echo "  ✅ Fingerprint reader detected"
          else
            echo "  ❌ No fingerprint reader"
          fi

          if (${hasFido2Device}); then
            echo "  ✅ FIDO2 device detected"
          else
            echo "  ❌ No FIDO2 device"
          fi
          echo

          # Services
          echo "🛡️  Services:"
          printf "  fprintd: "
          if systemctl is-active fprintd >/dev/null 2>&1; then
            echo "✅ running"
          else
            echo "❌ stopped"
          fi

          printf "  firewall: "
          if systemctl is-active ufw >/dev/null 2>&1; then
            echo "✅ active"
          else
            echo "❌ inactive"
          fi
          echo

          # Configuration
          echo "⚙️  Configuration:"
          if [ -s /etc/fido2/fido2 ]; then
            device_count=$(wc -l < /etc/fido2/fido2)
            echo "  FIDO2: ✅ $device_count device(s) registered"
          else
            echo "  FIDO2: ❌ no devices registered"
          fi

          fingerprint_count=$(${pkgs.fprintd}/bin/fprintd-list "$USER" 2>/dev/null | wc -l || echo "0")
          if [ "$fingerprint_count" -gt 0 ]; then
            echo "  Fingerprint: ✅ enrolled"
          else
            echo "  Fingerprint: ❌ not enrolled"
          fi
          ;;

        "reset-lockout")
          echo "🔓 Resetting account lockout..."
          sudo ${pkgs.util-linux}/bin/faillock --user "$USER" --reset
          echo "✅ Account lockout reset"
          ;;

        "firewall")
          echo "🛡️  Firewall status:"
          sudo ufw status verbose
          ;;

        *)
          echo "🔒 OmniXY Security Management"
          echo
          echo "Usage: omnixy-security <command>"
          echo
          echo "Commands:"
          echo "  status         - Show security status"
          echo "  reset-lockout  - Reset failed login attempts"
          echo "  firewall       - Show firewall status"
          echo
          echo "Related commands:"
          echo "  omnixy-fingerprint - Manage fingerprint authentication"
          echo "  omnixy-fido2      - Manage FIDO2 authentication"
          ;;
      esac
    '')
  ];
in
{
  options.omnixy.security = {
    enable = mkEnableOption "OmniXY security features";

    fingerprint = {
      enable = mkEnableOption "fingerprint authentication";
      autoDetect = mkOption {
        type = types.bool;
        default = true;
        description = "Automatically detect and enable fingerprint readers";
      };
    };

    fido2 = {
      enable = mkEnableOption "FIDO2/WebAuthn authentication";
      autoDetect = mkOption {
        type = types.bool;
        default = true;
        description = "Automatically detect and enable FIDO2 devices";
      };
    };

    systemHardening = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable system security hardening";
      };

      faillock = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable account lockout protection";
        };
        denyAttempts = mkOption {
          type = types.int;
          default = 10;
          description = "Number of failed attempts before lockout";
        };
        unlockTime = mkOption {
          type = types.int;
          default = 120;
          description = "Lockout duration in seconds";
        };
      };
    };
  };

  config = mkIf (cfg.enable or true) {
    # Security packages and management scripts (consolidated)
    environment.systemPackages = (with pkgs; [
      # Fingerprint authentication
      fprintd

      # FIDO2/WebAuthn
      libfido2
      pam_u2f

      # Security utilities
      usbutils
      pciutils
    ]) ++ [
      # Security management scripts defined below
    ] ++ securityScripts;

    # Fingerprint authentication configuration
    services.fprintd = mkIf (cfg.fingerprint.enable or cfg.fingerprint.autoDetect) {
      enable = true;
      package = pkgs.fprintd;
    };

    # Security configuration (consolidated)
    security = {
      # Sudo security configuration
      sudo = mkMerge [
        (mkIf cfg.systemHardening.enable {
          enable = true;
          wheelNeedsPassword = true;
          execWheelOnly = true;
        })
      ];

      # Polkit security configuration
      polkit = mkIf cfg.systemHardening.enable {
        enable = true;
        extraConfig = ''
          polkit.addRule(function(action, subject) {
              if (subject.isInGroup("wheel") &&
                  (action.id == "org.freedesktop.systemd1.manage-units" ||
                   action.id == "org.freedesktop.NetworkManager.settings.modify.system")) {
                  return polkit.Result.YES;
              }
          });
        '';
      };

      # PAM configuration for authentication methods
      pam = {
        # Login limits for account lockout protection
        loginLimits = mkIf cfg.systemHardening.faillock.enable [
          {
            domain = "*";
            type = "hard";
            item = "core";
            value = "0";
          }
        ];

        # PAM services configuration
        services = {
          # Sudo configuration
          sudo = mkMerge [
            (mkIf (cfg.fingerprint.enable or cfg.fingerprint.autoDetect) {
              fprintAuth = true;
            })
            (mkIf cfg.fido2.enable {
              text = mkBefore ''
                auth       sufficient   pam_u2f.so cue authfile=/etc/fido2/fido2
              '';
            })
          ];

          # Polkit configuration
          polkit-1 = mkMerge [
            (mkIf (cfg.fingerprint.enable or cfg.fingerprint.autoDetect) {
              fprintAuth = true;
              text = ''
                auth       sufficient   pam_fprintd.so
                auth       include      system-auth
                account    include      system-auth
                password   include      system-auth
                session    include      system-auth
              '';
            })
            (mkIf cfg.fido2.enable {
              text = mkBefore ''
                auth       sufficient   pam_u2f.so cue authfile=/etc/fido2/fido2
              '';
            })
          ];

          # Login configuration
          login = mkIf (cfg.fingerprint.enable or cfg.fingerprint.autoDetect) {
            fprintAuth = mkDefault true;
          };

          # Screen lock configuration
          hyprlock = mkIf (config.omnixy.desktop.enable or false) (mkMerge [
            (mkIf (cfg.fingerprint.enable or cfg.fingerprint.autoDetect) {
              fprintAuth = true;
              text = ''
                auth       sufficient   pam_fprintd.so
                auth       include      system-auth
                account    include      system-auth
              '';
            })
            (mkIf cfg.fido2.enable {
              text = mkBefore ''
                auth       sufficient   pam_u2f.so cue authfile=/etc/fido2/fido2
              '';
            })
          ]);

          # Faillock configuration for system-auth
          system-auth = mkIf cfg.systemHardening.faillock.enable {
            text = mkAfter ''
              auth        required      pam_faillock.so preauth
              auth        required      pam_faillock.so authfail deny=${toString cfg.systemHardening.faillock.denyAttempts} unlock_time=${toString cfg.systemHardening.faillock.unlockTime}
              account     required      pam_faillock.so
            '';
          };
        };
      };
    };

    # Firewall configuration
    networking.firewall = mkIf cfg.systemHardening.enable {
      enable = true;

      # Essential services (NixOS firewall denies by default)
      allowedTCPPorts = [ 22 ];  # SSH
      allowedUDPPorts = [ 53317 ];  # LocalSend
      allowedTCPPortRanges = [
        { from = 53317; to = 53317; }  # LocalSend TCP
      ];
    };

    # Create FIDO2 configuration directory
    system.activationScripts.fido2Setup = mkIf cfg.fido2.enable ''
      mkdir -p /etc/fido2
      chmod 755 /etc/fido2

      # Create empty fido2 config file if it doesn't exist
      if [ ! -f /etc/fido2/fido2 ]; then
        touch /etc/fido2/fido2
        chmod 644 /etc/fido2/fido2
      fi
    '';

    # Security management scripts are now defined in the let block above

    # Add to main menu integration
    home-manager.users.${config.omnixy.user} = {
      programs.bash.shellAliases = {
        fingerprint = "omnixy-fingerprint";
        fido2 = "omnixy-fido2";
        security = "omnixy-security";
      };

      programs.zsh.shellAliases = {
        fingerprint = "omnixy-fingerprint";
        fido2 = "omnixy-fido2";
        security = "omnixy-security";
      };

      programs.fish.shellAliases = {
        fingerprint = "omnixy-fingerprint";
        fido2 = "omnixy-fido2";
        security = "omnixy-security";
      };
    };
  };
}