{
  flake.modules.nixos.zfs = {
    lib,
    pkgs,
    ...
  }: let
    # NOTE: Temporarily pinned since nixpkgs has version 7.0.9 which has a broken
    # mediatek bluetooth driver
    # https://community.frame.work/t/bluetooth-is-borked-cant-init-device-hci0-invalid-argument-22/82605/6
    linux_7_0_6 = pkgs.linux_7_0.override {
      argsOverride = rec {
        version = "7.0.6";
        modDirVersion = version;
        src = pkgs.fetchurl {
          url = "mirror://kernel/linux/kernel/v7.x/linux-${version}.tar.xz";
          hash = "sha256-y6REQKpXr/18ISQdxbwjSw31PEmfj/w+vCkN0zkKdSM=";
        };
      };
    };
  in {
    # ZFS Specific settings
    boot.supportedFilesystems = ["zfs"];

    # ZFS-compatible kernel here
    boot.kernelPackages = pkgs.linuxPackagesFor linux_7_0_6;

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
