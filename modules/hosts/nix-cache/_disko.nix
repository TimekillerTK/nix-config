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
            swap = {
              size = "2G";
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
  };
}
