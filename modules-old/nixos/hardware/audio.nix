{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options.hardware.audio.pipewire.enable = mkEnableOption "PipeWire audio system";

  config = mkIf config.hardware.audio.pipewire.enable {
    # PipeWire configuration
    security.rtkit.enable = true;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
    };

    # Audio packages
    environment.systemPackages = with pkgs; [
      # Audio control
      pavucontrol
      pulsemixer
      alsamixer

      # Audio tools
      audacity
      pulseaudio

      # Bluetooth audio
      bluez
      bluez-tools
    ];

    # Disable PulseAudio (conflicts with PipeWire)
    services.pulseaudio.enable = false;

    # Audio group for user
    users.groups.audio = {};
  };
}
