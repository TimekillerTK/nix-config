{
  disko.devices = {
    disk = {
      disk1 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-WDS100T1X0E-00AFY0_22163Y800073";
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
              size = "32G";
              type = "8200";
              content = {
                type = "swap";
                resumeDevice = true; # resume from hiberation
              };
            };
          };
        };
      };
    };
    zpool = {
      zroot = {
        type = "zpool";
        rootFsOptions = {
          xattr = "sa";            # set Extended Attributes directly in Inodes (+perf)
          dnodesize = "auto";      # recommended with xattr = "sa"
          compression = "lz4";     # (+perf & +space)
          atime = "off";           # disables last file/directory access time updates
          acltype = "posixacl";    # support for POSIX ACLs
          canmount = "off";        # don't mount the pool by default, mount datasets instead
          checksum = "edonr";      # most performant checksum for zfs
          normalization = "formD"; # recommended default
        };

        mountpoint = null;
        options = {
          ashift = "12";     # 4096 sector size (recommended)
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
