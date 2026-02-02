{ config, lib, pkgs, ... }:
let
  # In Home Manager context, we need to check if noctalia is enabled
  # We can access this through the noctalia-shell program config
  noctaliaEnabled = config.programs.noctalia-shell.enable or false;
  noctaliaBackend = config.programs.noctalia-shell.settings.backend or "hyprland";
in
{
  config = lib.mkIf (noctaliaEnabled && noctaliaBackend == "hyprland") {
    home-manager.users.t0psh31f.wayland.windowManager.hyprland.settings = {
      # Noctalia-specific keybinds (mkAfter to append without overriding your defaults)
      bind = lib.mkAfter [
        # Overview / App Launcher (Super + Space via Vicinae or direct)
        "SUPER, D, exec, noctalia-shell ipc overview"  # Overview mode[web:page]

        # Control Center (Quick Settings)
        "SUPER, X, exec, noctalia-shell ipc control-center"  # Toggle Control Center

        # Lock Screen
        "SUPER, L, exec, noctalia-shell ipc lock"  # Lock screen

        # Logout / Session Menu
        "SUPER SHIFT, E, exec, noctalia-shell ipc session-menu"  # Session actions

        # Notifications
        "SUPER SHIFT, N, exec, noctalia-shell ipc notification-center"  # Notification history

        # Brightness / Audio (IPC via noctalia-shell, overrides your dms if preferred)
        ", XF86MonBrightnessUp, exec, noctalia-shell ipc brightness +5"
        ", XF86MonBrightnessDown, exec, noctalia-shell ipc brightness -5"
        ", XF86AudioRaiseVolume, exec, noctalia-shell ipc volume +5"
        ", XF86AudioLowerVolume, exec, noctalia-shell ipc volume -5"
        ", XF86AudioMute, exec, noctalia-shell ipc volume mute"

        # Media Controls (if Noctalia handles MPRIS)
        ", XF86AudioPlay, exec, noctalia-shell ipc media play-pause"
        ", XF86AudioNext, exec, noctalia-shell ipc media next"
        ", XF86AudioPrev, exec, noctalia-shell ipc media previous"

        # Screenshot (integrate with Noctalia OSD)
        ", Print, exec, noctalia-shell ipc screenshot"

        # Workspace / Overview integration
        "SUPER SHIFT, Tab, exec, noctalia-shell ipc overview"  # Alt-Tab like overview
      

      # Bind mouse/release for gestures if supported
      # Mouse wheel workspace switching
#"SUPER, mouse_up, exec, noctalia-shell ipc workspace +1"
#"SUPER, mouse_down, exec, noctalia-shell ipc workspace -1"
      ];
    };
  };
}
