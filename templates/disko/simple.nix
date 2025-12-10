# Simple Disko Template
# 1GB FAT32 boot + ext4 root (100%)
# No encryption - for simple/testing setups
{...}: {
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/sda"; # Change this to your target disk
      content = {
        type = "gpt";
        partitions = {
          boot = {
            size = "1G";
            type = "EF00"; # EFI System Partition
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = ["defaults" "umask=0077"];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}
