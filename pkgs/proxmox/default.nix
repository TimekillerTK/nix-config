{ pkgs, nixos-generators, ... }:
nixos-generators.nixosGenerate {
  # inherit system;
  specialArgs = {
    inherit pkgs;
    diskSize = 64 * 1024;
  };
  modules = [
    ../../hosts/anya
  ];
  format = "proxmox";
}
