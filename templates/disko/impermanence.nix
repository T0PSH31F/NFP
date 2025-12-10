# Impermanence Disko Template
# 4GB FAT32 boot + LUKS encrypted btrfs with subvolumes
# Designed for NixOS impermanence ("delete your darlings")
{config, ...}: {
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/sda"; # Change this to your target disk
      content = {
        type = "gpt";
        partitions = {
          boot = {
            size = "4G";
            type = "EF00"; # EFI System Partition
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = ["defaults" "umask=0077"];
            };
          };
          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "crypted";
              # Password handling options:
              # Option 1: Manual password file (for installation)
              passwordFile = "/tmp/secret.key"; # echo "password" > /tmp/secret.key before install

              # Option 2: Use clan secrets (recommended for production)
              # passwordFile = config.clan.core.facts.services.disk-password.secret."disk-password".path;

              settings = {
                allowDiscards = true; # Enables TRIM for SSDs
                bypassWorkqueues = true; # Performance optimization
              };

              content = {
                type = "btrfs";
                extraArgs = ["-f"]; # Force formatting

                subvolumes = {
                  # Root subvolume - wiped on every boot for impermanence
                  "@root" = {
                    mountpoint = "/";
                    mountOptions = ["compress=zstd" "noatime"];
                  };

                  # Nix store - persisted (obviously!)
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = ["compress=zstd" "noatime"];
                  };

                  # Persistent data - survives reboots
                  "@persist" = {
                    mountpoint = "/persist";
                    mountOptions = ["compress=zstd" "noatime"];
                  };

                  # Home directories - optional: can be impermanent or persistent
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = ["compress=zstd" "noatime"];
                  };

                  # Backups subvolume
                  "@backup" = {
                    mountpoint = "/backup";
                    mountOptions = ["compress=zstd" "noatime"];
                  };

                  # Logs - persisted
                  "@log" = {
                    mountpoint = "/var/log";
                    mountOptions = ["compress=zstd" "noatime"];
                  };

                  # Swap subvolume (btrfs doesn't support swapfiles on /root)
                  "@swap" = {
                    mountpoint = "/swap";
                    swap.swapfile.size = "16G"; # Adjust to your needs
                  };
                };
              };
            };
          };
        };
      };
    };
  };

  # Impermanence configuration (add this to your machine config)
  # environment.persistence."/persist" = {
  #   directories = [
  #     "/var/lib/nixos"
  #     "/var/lib/systemd"
  #     "/etc/nixos"
  #     # Add other directories you want to persist
  #   ];
  #   files = [
  #     "/etc/machine-id"
  #     # Add other files you want to persist
  #   ];
  # };
}
