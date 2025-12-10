{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./mpv.nix
  ];

  home.packages = with pkgs;
    [
      age # encryption tool
      asciinema # record the terminal
      baobab # disk usage utility
      blahaj
      #bruno # IDE for exploring/testing APIs (Postman/Insomnia alternative)
      buildah # build OCI images (alternative to docker build)
      ctop # top-like interface for container metrics
      cpufetch
      curl
      dbeaver-bin # GUI for many SQL databases https://dbeaver.io/about/
      ddrescue # data recovery tool (I also use it to burn an ISO to a USB flash drive)
      ddrescueview # Graphical viewer for GNU ddrescue mapfiles
      difftastic # syntax-aware diff
      distrobox # Wrapper around podman or docker to create and start containers
      dive # explore the layers of a container image
      # emojione # open source emoji set TODO: this failed to build on 2024/07/25
      exif # read and manipulate EXIF data in digital photographs
      fd
      ffmpeg
      file # show the type of files
      filebot
      flameshot # Powerful yet simple to use screenshot software
      flyctl # Fly.io CLI
      fx # JSON viewer
      gh # GitHub CLI
      #gimp # image editor
      glow # terminal markdown viewer
      gnumake # GNU Make (build tool)
      go
      #google-chrome
      #google-cloud-sdk # Google Cloud Platform CLI (gcloud)
      graphviz
      gpufetch
      hyperfine # command-line benchmarking tool
      #imhex # HEX editor
      #inkscape # vector graphics editor
      killall # kill processes by name or list PIDs
      libreoffice # a variant of openoffice.org
      lm_sensors # tools for reading hardware sensors
      lshw # detailed information on the hardware configuration of the machine
      lsix # shows thumbnails in terminal using sixel graphics
      metasploit # Metasploit framework
      monolith # save a web page as a single HTML file
      mtr # network diagnostics tool (basically traceroute + ping)
      ncdu # disk usage utility
      neofetch
      nodePackages.node-gyp # Node.js native addon build tool
      nodePackages.wrangler # Cloudflare Workers CLI
      ocrmypdf # adds an OCR text layer to scanned PDF files, allowing them to be searched (e.g. with ripgrep-all)
      #openshot-qt # video editor
      ouch #  compress/decompress files and directories
      nodejs_22
      obsidian # knowledge base
      pgadmin4
      pgcli # Command-line interface for PostgreSQL
      #pinta # image editor
      #pitivi # video editor
      # postman # https://github.com/NixOS/nixpkgs/issues/259147
      prettyping # a nicer ping
      procs # a better `ps`
      pstree # show the set of running processes as a tree
      python3
      remmina # remote desktop client
      rm-improved
      rofi # application launcher & window switcher
      screenkey # shows keypresses on screen
      sd # sed alternative
      (writeShellApplication {
        name = "show-nixos-org";
        runtimeInputs = [curl w3m];
        text = ''
          curl -s 'https://nixos.org' | w3m -dump -T text/html
        '';
      })
      #simplescreenrecorder # screen recorder gui
      sqlite
      sqlitebrowser
      #steghide # steganography tool for images and audio files
      #stegseek # tool to crack steganography
      stripe-cli
      supabase-cli
      tealdeer # TLDR pages for commands
      thunderbird # email client
      toybox
      #tokei # display statistics about your code
      trash-cli # alternative to rm
      # trashy # alternative to rm and trash-cli (not working?)
      unzrip # unzip replacement with parallel decompression
      usbutils # tools for working with USB devices, such as lsusb
      visidata # CLI for Exploratory Data Analysis
      w3m # text-based web browser
      wget

      yarr # Yet another rss reader
      yt-dlp
      zeal # offline documentation browser

      # Terminal emulators
      alacritty # Open GL terminal emulator
      foot # GPU-accelerated terminal emulator
      ghostty
      kitty # GPU-based terminal emulator
      warp-terminal # GPU-accelerated terminal emulator

      # CLI tools and utilities
      cbonsai
      cmatrix
      eza # fork of exa, a better `ls`
      lsd # modern ls alternative
      fortune
      gotree
      sl
      toilet # print large text from a string
      figlet # print large text from a string
      neo-cowsay
      neohtop
      osdlyrics
      pricehist
      viu # Available in nixpkgs
      zfxtop
      # superfile - may need to be packaged or built from source

      # Document readers and viewers
      calibre
      foliate # Simple and modern GTK eBook reader
      librum
      koreader
      # calibre-web - typically a service
      zathura

      # Media players
      kodi
      vlc
      mpv
      feh
      spotify

      # Messaging and communication
      kotatogram-desktop # Telegram client
      caprine-bin # Facebook Messenger
      element-desktop # Matrix client
      betterdiscord-installer # Discord
      betterdiscordctl
      vesktop

      # Neofetch but animated
      fastfetch # Required for anifetch
    ]
    ++ lib.optionals (inputs ? anifetch && inputs.anifetch ? packages.${pkgs.stdenv.hostPlatform.system}.default) [
      inputs.anifetch.packages.${pkgs.stdenv.hostPlatform.system}.default
    ]
    ++ lib.optionals (inputs ? lobster && inputs.lobster ? packages.${pkgs.stdenv.hostPlatform.system}.default) [
      inputs.lobster.packages.${pkgs.stdenv.hostPlatform.system}.default
    ]
    ++ lib.optionals (inputs ? jerry && inputs.jerry ? packages.${pkgs.stdenv.hostPlatform.system}.default) [
      inputs.jerry.packages.${pkgs.stdenv.hostPlatform.system}.default
    ]
    ++ lib.optionals (inputs ? nix-ai-help && inputs.nix-ai-help ? packages.${pkgs.stdenv.hostPlatform.system}.default) [
      inputs.nix-ai-help.packages.${pkgs.stdenv.hostPlatform.system}.default
      # AI help tool if available
    ]
    ++ lib.optionals (inputs ? antigravity-nix && inputs.antigravity-nix ? packages.${pkgs.stdenv.hostPlatform.system}.default) [
      inputs.antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
      # Antigravity tool if available
    ];

  # Spicetify configuration
  programs.spicetify = let
    spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  in {
    enable = true;

    # Dribbblish theme
    theme = spicePkgs.themes.dribbblish;
    colorScheme = "nord-dark"; # Options: base, nord-dark, nord-light, etc.

    enabledExtensions = with spicePkgs.extensions; [
      adblock
      hidePodcasts
      shuffle # shuffle+
      keyboardShortcut
      fullAppDisplay
    ];
  };

  # Lazygit configuration
  programs.lazygit = {
    enable = true;
  };
}
