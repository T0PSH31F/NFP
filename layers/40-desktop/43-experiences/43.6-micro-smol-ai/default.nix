# Micro Smol-AI Desktop Experience Adapter
# Activates when: layers.desktop.experience = "micro-smol-ai"
#
# Purpose: Ultra-lightweight Wayland GUI for low-power AI inference laptops.
# Minimizes compositor overhead so all CPU/RAM is available for inference.
#
# Compositor: cage (kiosk-mode) or dwl (wlroots/dwm-like, <15MB RAM).
# Display sleep: wlopm turns off LCD backlight after 60s — CPU keeps running.
# Clamshell: logind ignores lid switch so docked inference is uninterrupted.
# Theming: None — bare terminal aesthetic only. No Noctalia, no Matugen.
# Greeter: tuigreet (TTY, zero GL dependency).
#
# Zero bleed: no Noctalia socket, no noctalia-colors, no ~/.cache/noctalia.
{
  config,
  lib,
  pkgs,
  osConfig ? config,
  ...
}:
let
  exp = osConfig.layers.desktop.experience or "none";
  isEnabled = exp == "micro-smol-ai";
in
{
  nixos = lib.mkIf isEnabled {
    # ── Clamshell mode — keep inference running when lid closes ──────────
    services.logind = {
      lidSwitch = "ignore";
      lidSwitchDocked = "ignore";
      lidSwitchExternalPower = "ignore";
    };

    # ── dwl + cage — tiny compositor suite ──────────────────────────────
    environment.systemPackages = [
      pkgs.dwl # wlroots/dwm-like, ~10MB RAM
      pkgs.cage # Wayland kiosk compositor
      pkgs.wlopm # Display power management (backlight off, CPU stays on)
      pkgs.foot # Lightweight GPU-accelerated terminal
      pkgs.wl-clipboard
    ];

    # Register lightweight session for DM session picker
    services.displayManager.sessionPackages = [
      (
        (pkgs.writeTextFile {
          name = "micro-smol-ai-wayland-session";
          destination = "/share/wayland-sessions/micro-smol-ai.desktop";
          passthru.providedSessions = [ "micro-smol-ai" ];
          text = ''
            [Desktop Entry]
            Name=Micro Smol-AI
            Comment=Minimal Wayland session for low-power AI inference
            Exec=dwl
            Type=Application
            DesktopNames=dwl
          '';
        })
        // {
          providedSessions = [ "micro-smol-ai" ];
        }
      )
    ];
  };

  home =
    { config, lib, ... }:
    {
      config = lib.mkIf isEnabled {
        services.swayidle = {
          enable = true;
          events = [ ];
          timeouts = [
            {
              timeout = 60;
              command = "${pkgs.wlopm}/bin/wlopm --off '*'";
              resumeCommand = "${pkgs.wlopm}/bin/wlopm --on '*'";
            }
          ];
        };

        # Minimal foot terminal config for micro host
        programs.foot = {
          enable = true;
          settings = {
            main = {
              font = "monospace:size=11";
              pad = "4x4";
            };
            colors = {
              foreground = "cdd6f4";
              background = "1e1e2e";
            };
          };
        };
      };
    };
}
