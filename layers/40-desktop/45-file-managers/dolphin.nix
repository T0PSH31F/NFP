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

  home =
    let
      isLuffy = config.networking.hostName == "luffy";
      placesScript = pkgs.writeScript "sync-dolphin-places" ''
        #!${pkgs.python3}/bin/python3
        import os
        import time
        import xml.etree.ElementTree as ET
        from pathlib import Path

        ET.register_namespace("bookmark", "http://www.freedesktop.org/standards/desktop-bookmarks")
        ET.register_namespace("kdepriv", "http://www.kde.org/kdepriv")
        ET.register_namespace("mime", "http://www.freedesktop.org/standards/shared-mime-info")

        xbel_path = Path(os.path.expanduser("~/.local/share/user-places.xbel"))
        xbel_path.parent.mkdir(parents=True, exist_ok=True)

        if xbel_path.exists() and xbel_path.stat().st_size > 0:
            tree = ET.parse(xbel_path)
            root = tree.getroot()
        else:
            root = ET.Element("xbel", {
                "xmlns:bookmark": "http://www.freedesktop.org/standards/desktop-bookmarks",
                "xmlns:kdepriv": "http://www.kde.org/kdepriv",
                "xmlns:mime": "http://www.freedesktop.org/standards/shared-mime-info",
            })
            tree = ET.ElementTree(root)

        desired = [
            ("file:///Storage", "Storage NAS (luffy)", "folder-network"),
            ("file:///Storage/CalibreLibrary", "Calibre Library", "accessories-ebook-reader"),
            ("file:///Storage/Media", "Media Library", "folder-videos"),
            ("file:///home/t0psh31f/Private", "Private Vault (Encrypted)", "folder-locked"),
            ("file:///mnt/NAS1", "NAS1 (2TB)", "folder-network"),
            ("file:///mnt/NAS2", "NAS2 (1TB)", "folder-network"),
        ]
        ${lib.optionalString isLuffy ''
          desired.extend([
              ("file:///mnt/drives/backup-1", "Backup_1 (932GB)", "drive-harddisk"),
          ])
        ''}

        existing = {elem.get("href"): elem for elem in root.findall("bookmark")}
        now_id = int(time.time())
        changed = False

        for idx, (href, title, icon_name) in enumerate(desired):
            if href in existing:
                bm = existing[href]
                t_el = bm.find("title")
                if t_el is not None and t_el.text != title:
                    t_el.text = title
                    changed = True
                continue
            bm = ET.SubElement(root, "bookmark", {"href": href})
            t_el = ET.SubElement(bm, "title")
            t_el.text = title
            info = ET.SubElement(bm, "info")
            m_fdo = ET.SubElement(info, "metadata", {"owner": "http://freedesktop.org"})
            ET.SubElement(m_fdo, "{http://www.freedesktop.org/standards/desktop-bookmarks}icon", {"name": icon_name})
            m_kde = ET.SubElement(info, "metadata", {"owner": "http://www.kde.org"})
            id_el = ET.SubElement(m_kde, "ID")
            id_el.text = f"{now_id}/{900 + idx}"
            changed = True

        if changed or not xbel_path.exists():
            ET.indent(tree, space=" ")
            xml_bytes = ET.tostring(root, encoding="utf-8", xml_declaration=True)
            xbel_path.write_bytes(xml_bytes + b"\n")
      '';
    in
    lib.mkIf config.layers.layer-40.desktop.dolphin.enable {
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

      home.activation = {
        dolphinPlaces = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          $DRY_RUN_CMD ${placesScript} || true
        '';
        kbuildsycoca = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          $DRY_RUN_CMD ${pkgs.kdePackages.kservice}/bin/kbuildsycoca6 --noincremental || true
        '';
      };
    };
}
