# hypridle — DPMS screen-off for Hyprland (replaces noctalia's buggy idle)
#
# Noctalia's native idle system triggers DPMS screen-off internally, but on
# Intel Iris Xe (Alder Lake) the Wayland compositor connection breaks when
# the display wakes, causing noctalia to crash with "Broken pipe" and kill
# all running programs. hypridle is Hyprland-native and handles DPMS
# transitions cleanly without the connection-breaking behaviour.
{
  osConfig ? config,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = osConfig.layers.layer-40.desktop.noctalia;
  idleCfg =
    cfg.idle or {
      enable = true;
      dpmsTimeout = 600;
      lockTimeout = 660;
      dpmsIgnoreAc = false;
    };
  dpmsOffCmd =
    if idleCfg.dpmsIgnoreAc then
      "${pkgs.writeShellScript "hypridle-dpms-off" ''
        # If AC power supply is online, do not shut display off
        if [ -d /sys/class/power_supply ] && ${pkgs.gnugrep}/bin/grep -q 1 /sys/class/power_supply/*/online 2>/dev/null; then
          exit 0
        fi
        ${pkgs.hyprland}/bin/hyprctl dispatch dpms off
      ''}"
    else
      "${pkgs.hyprland}/bin/hyprctl dispatch dpms off";
in
{
  config = lib.mkIf (cfg.enable && cfg.backend == "hyprland" && idleCfg.enable) {
    home.packages = [ pkgs.hypridle ];

    xdg.configFile."hypr/hypridle.conf" = {
      text = ''
                # hypridle — idle management for Hyprland
                #
                # Replaces noctalia's built-in idle handler which caused DPMS-related
                # Wayland crashes on Intel Iris Xe. See layers/40-desktop/43-noctalia/hypridle.nix.

                general {
                    lock_cmd = pidof hyprlock || hyprlock;  # lock if hyprlock installed
                    before_sleep_cmd = loginctl lock-session; # lock before system suspend
                    after_sleep_cmd = hyprctl dispatch dpms on; # wake display after suspend
                }
        ${lib.optionalString (idleCfg.dpmsTimeout != null) ''

          listener {
              timeout = ${toString idleCfg.dpmsTimeout};
              on-timeout = ${dpmsOffCmd};
              on-resume = hyprctl dispatch dpms on;
          }
        ''}
        ${lib.optionalString (idleCfg.lockTimeout != null) ''

          listener {
              timeout = ${toString idleCfg.lockTimeout};
              on-timeout = loginctl lock-session;
          }
        ''}
      '';
    };

    systemd.user.services.hypridle = {
      Unit = {
        Description = "Hyprland idle daemon (DPMS + lock)";
        Documentation = "https://github.com/hyprwm/hypridle";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.hypridle}/bin/hypridle";
        Restart = "on-failure";
        RestartSec = "5s";
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
