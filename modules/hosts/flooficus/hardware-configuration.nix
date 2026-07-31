{
  flake.modules.nixos.flooficus = {
    modulesPath,
    lib,
    ...
  }: {
    imports = [
      (modulesPath + "/profiles/qemu-guest.nix")
    ];

    boot.initrd.availableKernelModules = ["ata_piix" "uhci_hcd" "sr_mod"];
    boot.initrd.kernelModules = ["virtio_pci" "virtio_scsi" "sd_mod"];
    boot.kernelModules = [];
    boot.extraModulePackages = [];

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  };
}
