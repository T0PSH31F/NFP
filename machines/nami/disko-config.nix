{ config, lib, ... }:

{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/sda"; # IMPORTANT: Verify with lsblk on nami!
      content = {
        type = "gpt";
        partitions = {
          # Boot partition
          boot = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [
                "defaults"
                "umask=0077"
              ];
            };
          };

          # LUKS encrypted root
          root = {
            size = "100%";
            content = {
              type = "luks";
              name = "cryptroot";
              # Using clan secrets or manual password file during install
              passwordFile = "/tmp/luks-password";
              settings = {
                allowDiscards = true;
                bypassWorkqueues = true;
              };
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = {
                  # Root subvolume
                  "@" = {
                    mountpoint = "/";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  # Home subvolume
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  # Nix store subvolume
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  # Media storage (no compression for media files)
                  "@media" = {
                    mountpoint = "/srv/media";
                    mountOptions = [ "noatime" ];
                  };
                  # Snapshots subvolume
                  "@snapshots" = {
                    mountpoint = "/.snapshots";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
