# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
{ pkgs ? import <nixpkgs> { }, ... }: {
  # spaget = pkgs.callPackage ./spaget { target = "everyone"; };
  # xivlauncher = pkgs.callPackage ./xivlauncher { };
  # wip = pkgs.callPackage ./wip {};
}
