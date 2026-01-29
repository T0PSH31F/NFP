{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
let
  cfg = config.programs.anifetch;

  # Default Lain GIF path
  defaultGifPath = "/home/t0psh31f/.background/Giffees/Lain/oldScreen.gif";

  # Anifetch configuration file
  anifetchConfig = pkgs.writeText "anifetch.conf" ''
    # Anifetch Configuration
    # Based on neofetch configuration format
    # See: https://github.com/Notenlish/anifetch

    print_info() {
        prin "\n"
        prin "┌──────────────────────────────────────┐"
        info "\n  OS" distro
        info "\n  Host" model
        info "\n  Kernel" kernel
        info "\n  Uptime" uptime
        info "\n  Packages" packages
        info "\n  Shell" shell
        info "\n  Resolution" resolution
        info "\n  DE" de
        info "\n  WM" wm
        info "\n  Terminal" term
        info "\n  CPU" cpu
        info "\n  GPU" gpu
        info "\n  Memory" memory
        info "\n  Disk" disk
        info "\n  Battery" battery
        prin "└──────────────────────────────────────┘"
        prin "\n"
        prin "\n  ''${cl0}──''${cl1}────''${cl2}────''${cl3}────''${cl4}────''${cl5}────''${cl6}────''${cl7}──"
    }

    # Color definitions
    reset="\033[0m"
    gray="\033[1;90m"
    red="\033[1;31m"
    green="\033[1;32m"
    yellow="\033[1;33m"
    blue="\033[1;34m"
    magenta="\033[1;35m"
    cyan="\033[1;36m"
    white="\033[1;37m"

    cl0="''${gray}"
    cl1="''${red}"
    cl2="''${green}"
    cl3="''${yellow}"
    cl4="''${blue}"
    cl5="''${magenta}"
    cl6="''${cyan}"
    cl7="''${white}"

    # General options
    title_fqdn="off"
    kernel_shorthand="on"
    distro_shorthand="off"
    os_arch="on"
    uptime_shorthand="on"
    memory_percent="on"
    memory_unit="gib"
    package_managers="on"
    shell_path="off"
    shell_version="on"

    # CPU options
    speed_type="bios_limit"
    speed_shorthand="on"
    cpu_brand="on"
    cpu_speed="on"
    cpu_cores="logical"
    cpu_temp="off"

    # GPU options
    gpu_brand="on"
    gpu_type="all"

    # Display options
    refresh_rate="on"

    # Text options
    colors=(distro)
    bold="on"
    underline_enabled="on"
    underline_char="-"
    separator=":"

    # Color blocks
    block_range=(0 15)
    color_blocks="on"
    block_width=3
    block_height=1
    col_offset="auto"

    # Image backend - use ascii for terminal compatibility
    image_backend="ascii"
    image_source="auto"
    ascii_distro="auto"
    ascii_colors=(distro)
    ascii_bold="on"

    # Misc
    gap=2
    stdout="off"
  '';
in
{
  options.programs.anifetch = {
    enable = mkEnableOption "Anifetch - Animated neofetch alternative";

    runOnShellStart = mkOption {
      type = types.bool;
      default = true;
      description = "Run anifetch when opening a new shell";
    };

    gifPath = mkOption {
      type = types.str;
      default = defaultGifPath;
      description = "Path to the GIF/video file to display with anifetch";
      example = "/home/user/.background/Giffees/Lain/oldScreen.gif";
    };

    width = mkOption {
      type = types.int;
      default = 40;
      description = "Width of the animation in characters";
    };

    height = mkOption {
      type = types.int;
      default = 20;
      description = "Height of the animation in characters";
    };

    repeat = mkOption {
      type = types.int;
      default = 1;
      description = "Number of times to repeat the animation (0 = infinite)";
    };

    chafaArgs = mkOption {
      type = types.str;
      default = "--symbols wide --fg-only";
      description = "Additional arguments to pass to chafa";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      inputs.anifetch.packages.${pkgs.system}.default
    ];

    # Install anifetch config
    xdg.configFile."neofetch/config.conf".source = anifetchConfig;

    # Shell integration is handled separately in zsh.nix and bash.nix
  };
}
