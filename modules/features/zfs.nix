{
  flake.modules.nixos.zfs = {
    lib,
    pkgs,
    ...
  }: {
    # ZFS Specific settings
    boot.supportedFilesystems = ["zfs"];

    # ZFS-compatible kernel here
    boot.kernelPackages = pkgs.linuxPackages_6_18;

    # NOTE: Temporarily set to 2_4 on unstable because it's needed
    # for linux 6.18 at this time.
    #
    # In the future this line below for zfs_2_4 pinning needs to
    # be commented out/removed.
    boot.zfs.package = pkgs.unstable.zfs_2_4;

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
  };
}
