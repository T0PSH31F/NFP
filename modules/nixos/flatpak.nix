{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.flatpak;
in
{
  options.flatpak = {
    enable = mkEnableOption "Flatpak package manager";

    remotes = mkOption {
      type = types.listOf (types.submodule {
        options = {
          name = mkOption {
            type = types.str;
            description = "Name of the Flatpak remote";
          };
          location = mkOption {
            type = types.str;
            description = "URL of the Flatpak remote";
          };
        };
      });
      default = [
        {
          name = "flathub";
          location = "https://flathub.org/repo/flathub.flatpakrepo";
        }
      ];
      description = "List of Flatpak remotes to configure";
    };

    packages = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "com.spotify.Client"
        "org.mozilla.firefox"
        "com.discordapp.Discord"
      ];
      description = "List of Flatpak packages to install";
    };

    update = mkOption {
      type = types.submodule {
        options = {
          auto = mkOption {
            type = types.bool;
            default = true;
            description = "Enable automatic Flatpak updates";
          };
          onCalendar = mkOption {
            type = types.str;
            default = "weekly";
            description = "When to run automatic updates (systemd timer format)";
          };
        };
      };
      default = {
        auto = true;
        onCalendar = "weekly";
      };
      description = "Automatic update configuration";
    };

    overrides = mkOption {
      type = types.attrsOf (types.attrsOf types.str);
      default = { };
      example = {
        "com.spotify.Client" = {
          "Context" = "filesystems=/home/user/Music:ro";
        };
      };
      description = "Flatpak application overrides";
    };
  };

  config = mkIf cfg.enable {
    # Enable Flatpak service
    services.flatpak.enable = true;

    # XDG Desktop Portal (required for Flatpak)
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
      ];
    };

    # Add Flatpak to system packages
    environment.systemPackages = with pkgs; [
      flatpak
      gnome-software # Optional: GUI for managing Flatpaks
    ];

    # Configure Flatpak remotes
    systemd.services.flatpak-add-remotes = mkIf (cfg.remotes != [ ]) {
      description = "Add Flatpak remotes";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        ${concatMapStringsSep "\n" (remote: ''
          ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists ${remote.name} ${remote.location} || true
        '') cfg.remotes}
      '';
    };

    # Install Flatpak packages
    systemd.services.flatpak-install-packages = mkIf (cfg.packages != [ ]) {
      description = "Install Flatpak packages";
      wantedBy = [ "multi-user.target" ];
      after = [ "flatpak-add-remotes.service" ];
      wants = [ "flatpak-add-remotes.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        ${concatMapStringsSep "\n" (pkg: ''
          ${pkgs.flatpak}/bin/flatpak install -y flathub ${pkg} || true
        '') cfg.packages}
      '';
    };

    # Automatic updates
    systemd.services.flatpak-update = mkIf cfg.update.auto {
      description = "Update Flatpak packages";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.flatpak}/bin/flatpak update -y";
      };
    };

    systemd.timers.flatpak-update = mkIf cfg.update.auto {
      description = "Update Flatpak packages timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.update.onCalendar;
        Persistent = true;
      };
    };

    # Apply overrides
    system.activationScripts.flatpak-overrides = mkIf (cfg.overrides != { }) {
      text = ''
        ${concatStringsSep "\n" (mapAttrsToList (app: settings: ''
          ${concatStringsSep "\n" (mapAttrsToList (key: value: ''
            ${pkgs.flatpak}/bin/flatpak override --system ${app} --${key}=${value} || true
          '') settings)}
        '') cfg.overrides)}
      '';
    };
  };
}
