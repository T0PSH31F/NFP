# ZFS Disko Template
# Designed for servers: NAS, FTP, Web Servers
# Features: LUKS encryption, ZFS with datasets, snapshots
{config, ...}: {
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
          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "crypted-zfs";
              # Password handling - same as impermanence template
              passwordFile = "/tmp/secret.key";

              settings = {
                allowDiscards = true;
                bypassWorkqueues = true;
              };

              content = {
                type = "zfs";
                pool = "zroot";

                # ZFS pool options for server use
                options = {
                  ashift = "12"; # 4K sectors
                  autotrim = "on"; # Automatic TRIM for SSDs
                };

                # Root filesystem options
                rootFsOptions = {
                  compression = "zstd"; # Better compression than lz4
                  acltype = "posixacl"; # POSIX ACLs for file permissions
                  xattr = "sa"; # Extended attributes
                  relatime = "on"; # Performance optimization
                  normalization = "formD"; # Unicode normalization
                  dnodesize = "auto"; # Automatic dnode sizing

                  # Encryption (optional - adds layer on top of LUKS)
                  # encryption = "aes-256-gcm";
                  # keyformat = "passphrase";
                  # keylocation = "prompt";
                };

                # ZFS datasets
                datasets = {
                  # Root dataset
                  root = {
                    type = "zfs_fs";
                    mountpoint = "/";
                    options.mountpoint = "/";
                  };

                  # Nix store - no snapshots needed
                  nix = {
                    type = "zfs_fs";
                    mountpoint = "/nix";
                    options = {
                      atime = "off";
                      canmount = "on";
                      "com.sun:auto-snapshot" = "false";
                    };
                  };

                  # Home directories
                  home = {
                    type = "zfs_fs";
                    mountpoint = "/home";
                    options = {
                      "com.sun:auto-snapshot" = "true";
                      quota = "500G"; # Example quota
                    };
                  };

                  # Server data - for web content, databases, etc.
                  srv = {
                    type = "zfs_fs";
                    mountpoint = "/srv";
                    options = {
                      recordsize = "128K"; # Optimal for databases
                      "com.sun:auto-snapshot" = "true";
                      compression = "zstd-3"; # Higher compression for data
                    };
                  };

                  # NAS/File sharing dataset
                  nas = {
                    type = "zfs_fs";
                    mountpoint = "/nas";
                    options = {
                      recordsize = "1M"; # Optimal for large files
                      "com.sun:auto-snapshot" = "true";
                      compression = "lz4"; # Faster for large files
                    };
                  };

                  # Database storage (PostgreSQL, etc.)
                  database = {
                    type = "zfs_fs";
                    mountpoint = "/var/lib/databases";
                    options = {
                      recordsize = "16K"; # Optimal for databases
                      logbias = "latency"; # Prefer latency over throughput
                      primarycache = "metadata"; # Cache only metadata
                      "com.sun:auto-snapshot" = "true";
                      compression = "lz4"; # Light compression for DB
                    };
                  };

                  # Container/VM storage
                  containers = {
                    type = "zfs_fs";
                    mountpoint = "/var/lib/containers";
                    options = {
                      "com.sun:auto-snapshot" = "false"; # Handle snapshots per-container
                    };
                  };

                  # Backups dataset
                  backup = {
                    type = "zfs_fs";
                    mountpoint = "/backup";
                    options = {
                      compression = "zstd-9"; # Maximum compression for backups
                      "com.sun:auto-snapshot" = "false";
                    };
                  };

                  # Reserved dataset for emergency situations
                  reserved = {
                    type = "zfs_fs";
                    options = {
                      mountpoint = "none";
                      reservation = "10G"; # Keep 10GB reserved
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };

  # Additional ZFS configuration for NixOS
  # Add this to your machine configuration:
  # boot.supportedFilesystems = [ "zfs" ];
  # boot.zfs.forceImportRoot = false;
  # networking.hostId = "12345678"; # Generate with: head -c 8 /etc/machine-id

  # Enable ZFS auto-snapshot service
  # services.zfs.autoSnapshot.enable = true;
  # services.zfs.autoSnapshot.frequent = 4; # Keep 4 15-minute snapshots
  # services.zfs.autoSnapshot.hourly = 24;
  # services.zfs.autoSnapshot.daily = 7;
  # services.zfs.autoSnapshot.weekly = 4;
  # services.zfs.autoSnapshot.monthly = 12;

  # ZFS scrub (data integrity check)
  # services.zfs.autoScrub.enable = true;
  # services.zfs.autoScrub.interval = "weekly";
}
