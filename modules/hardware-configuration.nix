{
  flake.nixosModules.example = {
    inputs,
    config,
    lib,
    pkgs,
    modulesPath,
    ...
  }: {
    # imports = [
    #   (modulesPath + "/profiles/qemu-guest.nix")
    # ];

    boot.initrd.availableKernelModules = ["ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod"];
    boot.initrd.kernelModules = [];
    boot.kernelModules = [];
    boot.extraModulePackages = [];

    boot.loader.grub = {
      devices = ["/dev/sda"];
    };

    fileSystems."/" = {
      device = "/dev/disk/by-uuid/0119ab10-0458-4582-bb94-2a67176abcf2";
      fsType = "ext4";
    };

    swapDevices = [
      {device = "/dev/disk/by-uuid/cdf37e71-63a7-473e-9047-ba08b706f6ef";}
    ];

    # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
    # (the default) this is the recommended approach. When using systemd-networkd it's
    # still possible to use this option, but it's recommended to use it in conjunction
    # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
    networking.useDHCP = lib.mkDefault true;
    # networking.interfaces.ens18.useDHCP = lib.mkDefault true;

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  };
}
