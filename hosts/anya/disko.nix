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
          acltype = "posixacl";
          canmount = "off";
          checksum = "edonr";
          compression = "lz4";
          dnodesize = "auto";
          # encryption does not appear to work in vm test; only use on real system
          encryption = "aes-256-gcm";
          keyformat = "passphrase";
          keylocation = "prompt";
          normalization = "formD";
          relatime = "on";
          xattr = "sa";
        };

        mountpoint = null;
        options = {
          ashift = "12";     # 4096 sector size
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
