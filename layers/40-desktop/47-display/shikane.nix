{
  config,
  pkgs,
  lib,
  osConfig ? config,
  ...
}:
let
  clanTags = osConfig.machine.tags or [ ];
in
{
  home.packages = lib.mkIf (builtins.elem "desktop" clanTags) [ pkgs.shikane ];

  xdg.configFile."shikane/config.toml" = lib.mkIf (builtins.elem "desktop" clanTags) {
    force = true;
    text = ''
      [[profile]]
      name = "triple"
      # Acer (Left), Laptop (Middle), HKC Curved (Right)
      [[profile.output]]
      search = "XB271HK"
      enable = true
      mode = "3840x2160@30"
      position = "0,0"
      scale = 2.0

      [[profile.output]]
      search = "0x06EA"
      enable = true
      mode = "2560x1600@60"
      position = "1920,0"
      scale = 1.6

      [[profile.output]]
      search = "27N5C"
      enable = true
      mode = "1920x1080@60"
      position = "3520,0"
      scale = 1.0

      [[profile]]
      name = "docked"
      # Acer (Left) and Laptop (Right)
      [[profile.output]]
      search = "XB271HK"
      enable = true
      mode = "3840x2160@30"
      position = "0,0"
      scale = 2.0

      [[profile.output]]
      search = "0x06EA"
      enable = true
      mode = "2560x1600@60"
      position = "1920,0"
      scale = 1.6

      [[profile]]
      name = "big-screen"
      # Samsung TV (Left) and Laptop (Right)
      [[profile.output]]
      search = "SAMSUNG"
      enable = true
      mode = "1920x1080@59.939"
      position = "0,0"
      scale = 1.0

      [[profile.output]]
      search = "0x1612"
      enable = true
      mode = "1920x1200@60"
      position = "1920,0"
      scale = 1.0

      [[profile]]
      name = "laptop"
      [[profile.output]]
      search = "0x06EA"
      enable = true
      mode = "2560x1600@60"
      position = "0,0"
      scale = 1.6
    '';
  };

  systemd.user.services.shikane = lib.mkIf (builtins.elem "desktop" clanTags) {
    Unit = {
      Description = "Dynamic output configuration for Wayland";
      Documentation = "https://gitlab.com/w0lff/shikane";
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
