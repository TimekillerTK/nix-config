{
  flake.modules.nixos.flooficus = {
    modulesPath,
    lib,
    ...
  }: {
    imports = [
      (modulesPath + "/profiles/qemu-guest.nix")
    ];

    boot.initrd.availableKernelModules = ["ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod"];
    boot.kernelModules = [];
    boot.extraModulePackages = [];

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  };
}
