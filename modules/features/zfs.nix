{
  flake.modules.nixos.zfs = {
    lib,
    pkgs,
    ...
  }: let
    # NOTE: In case you need to pin a specific version of the linux kernel, EXAMPLE:
    # linux_7_0_14 = pkgs.linux_7_0.override {
    #   argsOverride = rec {
    #     version = "7.0.14";
    #     modDirVersion = version;
    #     src = pkgs.fetchurl {
    #       url = "mirror://kernel/linux/kernel/v7.x/linux-${version}.tar.xz";
    #       hash = lib.fakeHash;
    #     };
    #   };
    # };
  in {
    # ZFS Specific settings
    boot.supportedFilesystems = ["zfs"];

    # ZFS-compatible kernel here
    boot.kernelPackages = pkgs.linuxPackages_7_2;

    boot.zfs = {
      forceImportRoot = lib.mkDefault false;
      devNodes = lib.mkDefault "/dev/disk/by-id";
    };

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
