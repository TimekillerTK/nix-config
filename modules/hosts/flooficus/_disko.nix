{
  disko.devices = {
    disk = {
      disk1 = {
        type = "disk";
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G"; # Recommended @ ArchWiki
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                # NOTE: We need nofail here because if one disk drops, the OS
                # will still be expecting the OTHER boot partition otherwise
                mountOptions = ["nofail"];
              };
            };
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zroot";
              };
            };
            swap = {
              size = "16G";
              type = "8200";
              content = {
                type = "swap";
              };
            };
          };
        };
      };
      disk2 = {
        type = "disk";
        device = "/dev/sdb";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G"; # Recommended @ ArchWiki
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot-fallback";
                # NOTE: We need nofail here because if one disk drops, the OS
                # will still be expecting the OTHER boot partition otherwise
                mountOptions = ["nofail"];
              };
            };
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zroot";
              };
            };
          };
        };
      };
    };
    zpool = {
      zroot = {
        type = "zpool";
        mode = "mirror";
        rootFsOptions = {
          # ZFS Tuning Options
          # https://jrs-s.net/2018/08/17/zfs-tuning-cheat-sheet/
          # https://openzfs.github.io/openzfs-docs/Basic%20Concepts/Checksums.html
          # https://www.high-availability.com/docs/ZFS-Tuning-Guide/#
          xattr = "sa"; # set Extended Attributes directly in Inodes (+perf)
          dnodesize = "auto"; # recommended with xattr = "sa"
          compression = "lz4"; # (+perf & +space)
          atime = "off"; # disables last file/directory access time updates
          acltype = "posixacl"; # support for POSIX ACLs
          canmount = "off"; # don't mount the pool by default, mount datasets instead
          checksum = "edonr"; # most performant checksum for zfs
          normalization = "formD"; # recommended default
        };

        mountpoint = null;
        options = {
          ashift = "12"; # 4096 sector size (recommended)
          autotrim = "on";
        };

        datasets = {
          local = {
            type = "zfs_fs";
            options.canmount = "off";
          };

          "local/root" = {
            type = "zfs_fs";
            mountpoint = "/";
            options.mountpoint = "/";
            options."com.sun:auto-snapshot" = "true";
          };

          "local/home" = {
            type = "zfs_fs";
            mountpoint = "/home";
            options.mountpoint = "/home";
            options."com.sun:auto-snapshot" = "true";
          };

          "local/nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options.mountpoint = "/nix";
            options."com.sun:auto-snapshot" = "false";
          };

          "local/data" = {
            type = "zfs_fs";
            mountpoint = "/data";
            options.mountpoint = "/data";
            options."com.sun:auto-snapshot" = "false";
          };
        };
      };
    };
  };
}
