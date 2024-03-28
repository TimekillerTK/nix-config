{ ... }: 
{

  # ZFS Specific settings
  boot.supportedFilesystems = [ "zfs" ];
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
  boot.zfs.devNodes = lib.mkDefault "/dev/disk/by-id";

  # Automatic Scrub schedule
  services.zfs.autoScrub = {
    enable = true;
    interval = "Sat, 10:00";
  };

  # Automatic Snapshotting
  # NOTE: To target specific datasets, set in disko.nix!
  services.zfs.autoSnapshot = {
    enable = true;
    flags = "-k -p --utc";
  };

}