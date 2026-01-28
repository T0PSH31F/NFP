{
  pkgs,
  inputs,
  ...
}:
{
  nixpkgs = {
    overlays = [
      inputs.anifetch.overlays.anifetch
    ];
  };

  environment.systemPackages = with pkgs; [
    # Development tools
    antigravity-fhs
    binutils
    cmake
    devenv
    gitFull
    libgcc
    poetry
    uv
    typescript

    # System Utilities (that need root/system level)
    aria2
    gparted
    ntfs3g
    sops
    parted
    exfatprogs
    btrfs-progs

    # Hardware/Drivers
    logitech-udev-rules
    solaar

    # Pentest (System integration)
    aircrack-ng
    hcxdumptool
    hcxtools
    hashcat
    wireshark
    wireshark-cli
    bettercap
    kismet

    # Other Essentials
    imagemagick
    img2pdf
    poppler-utils
    qpdf
    p7zip
    unrar
    bubblewrap
  ];

  # Enable nix-ld for running non-NixOS binaries
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    zlib
    fuse3
    icu
    nss
    openssl
    curl
    expat
  ];
  programs.starship.enable = true;
}
