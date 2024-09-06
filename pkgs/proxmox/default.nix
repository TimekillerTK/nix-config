{ pkgs, nixos-generators, ... }:
nixos-generators.nixosGenerate {
  # inherit system;
  specialArgs = {
    inherit pkgs;
    diskSize = 20 * 1024;
  };
  modules = [
    ../../hosts/anya
  ];
  format = "proxmox";
}
