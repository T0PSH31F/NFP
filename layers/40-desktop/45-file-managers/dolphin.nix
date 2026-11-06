{
  pkgs,
  lib,
  config,
  ...
}:
{
  options.layers.layer-40.desktop.dolphin = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Dolphin file manager";
    };
  };

  home = lib.mkIf config.layers.layer-40.desktop.dolphin.enable {
    home.packages = with pkgs; [
      kdePackages.dolphin
      kdePackages.dolphin-plugins
      kdePackages.konsole # Embedded terminal panel (F4) & konsolepart
      kdePackages.ark # Archive manager & context menu compression/extraction
      kdePackages.kio-admin # Admin actions (Open/Edit as Root)
      kdePackages.kio-extras # Advanced protocols (SFTP, MTP, SMB)
      kdePackages.kdegraphics-thumbnailers # Graphics/photo previews
      kdePackages.ffmpegthumbs # Video thumbnails (mp4, mkv, webm)
      kdePackages.kimageformats # Additional image formats (AVIF, HEIF, WebP, JXL)
      kdePackages.svgpart # Vector SVG preview panel
      kdePackages.kservice
    ];

    home.activation.kbuildsycoca = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD ${pkgs.kdePackages.kservice}/bin/kbuildsycoca6 --noincremental || true
    '';
  };
}
