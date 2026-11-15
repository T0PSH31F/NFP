# Tier: 72-voice
# Module: hyprwhspr.nix
# Purpose: Global Wayland push-to-talk speech-to-text daemon (voxtype replacing broken hyprwhspr-rs paste route on umbriel)
# Option Path: layers.layer-72.voice.hyprwhspr
# Enabling Host Tags: desktop, ai-agent
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.layers.layer-72.voice.hyprwhspr;
  hasNvidia =
    (config.hardware.nvidia.enable or false)
    || elem "nvidia" (config.services.xserver.videoDrivers or [ ]);
in
{
  options.layers.layer-72.voice.hyprwhspr = {
    enable = mkEnableOption "Wayland global push-to-talk speech-to-text service (voxtype)";
  };

  config = mkIf cfg.enable {
    # hyprwhspr-rs relies on Hyprland activewindow IPC + clipboard paste and loses
    # injection on umbriel; voxtype types directly via wtype/ydotool everywhere.
    services.hyprwhspr-rs.enable = lib.mkForce false;

    environment.systemPackages = with pkgs; [
      wtype
      wl-clipboard
    ];

    systemd.user.services.voxtype = {
      description = "Voxtype global push-to-talk speech-to-text daemon";
      wantedBy = [ "graphical-session.target" ];
      after = [
        "graphical-session.target"
        "pipewire.service"
      ];
      partOf = [ "graphical-session.target" ];
      unitConfig.ConditionPathExists = "/run/current-system/sw/bin/voxtype";
      serviceConfig = {
        Environment = lib.optionals hasNvidia [
          "VOXTYPE_VULKAN_DEVICE=nvidia"
          "VK_DRIVER_FILES=/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.json"
        ];
        ExecStart = "/run/current-system/sw/bin/voxtype --flash-attention --eager-processing --threads 16 daemon";
        Restart = "on-failure";
        RestartSec = 3;
      };
    };
  };
}
