
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Media servers/downloaders
    # (most are services, not packages)

    # Media processing
    ffmpeg-full
    imagemagick

    # Downloaders
    yt-dlp
    transmission
    deluge

    # Streaming tools
    obs-studio
  ];
}
