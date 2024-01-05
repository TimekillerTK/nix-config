{lib, ...}: {
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = lib.mkDefault "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              name = "boot";
              size = "1M";
              type = "EF02"; # for grub MBR
            };
            ESP = {
              name = "ESP";
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              name = "root";
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
            # plainSwap = {
            #   size = "100%";
            #   content = {
            #     type = "swap";
            #     resumeDevice = true; # resume from hiberation from this device
            #   };
            # }; # plainSwap
          }; # partitions
        }; # content 
      }; # main
    }; # disk
  }; # disko.devices
}