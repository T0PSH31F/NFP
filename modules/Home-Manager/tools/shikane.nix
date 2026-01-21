{ pkgs, ... }:
{
  home.packages = [ pkgs.shikane ];

  xdg.configFile."shikane/config.toml".text = ''
    [[profile]]
    name = "triple"
    # Samsung 60" TV (Top, spanning width)
    [[profile.output]]
    search = "DP-2"
    enable = true
    mode = "1920x1080@60"
    position = "0,0"
    scale = 1.0

    # Acer Predator 27" (Bottom-Left under Samsung)
    [[profile.output]]
    search = "HDMI-A-1"
    enable = true
    mode = "3840x2160@30"
    position = "0,1080"
    scale = 2.0

    # Laptop (Bottom-Right, next to Acer)
    [[profile.output]]
    search = "eDP-1"
    enable = true
    mode = "2560x1600@60"
    position = "1920,1080"
    scale = 1.6

    [[profile]]
    name = "clamshell"
    # Samsung 60" TV (Top)
    [[profile.output]]
    search = "DP-2"
    enable = true
    mode = "1920x1080@60"
    position = "0,0"
    scale = 1.0

    # Acer Predator 27" (Bottom)
    [[profile.output]]
    search = "HDMI-A-1"
    enable = true
    mode = "3840x2160@30"
    position = "0,1080"
    scale = 2.0

    [[profile]]
    name = "laptop"
    [[profile.output]]
    search = "eDP-1"
    enable = true
    mode = "2560x1600@60"
    position = "0,0"
    scale = 1.6
  '';

  systemd.user.services.shikane = {
    Unit = {
      Description = "Dynamic output configuration for Wayland";
      Documentation = "https://gitlab.com/w0rp/shikane";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.shikane}/bin/shikane";
      Restart = "always";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
