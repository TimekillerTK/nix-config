# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
{ pkgs ? import <nixpkgs> { } }: {
  brother-mfcl3750cdw = pkgs.callPackage ./brother-mfcl3750cdw {};
  renamer = pkgs.callPackage ./renamer {};
  andromeda-kde = pkgs.callPackage ./sddm/Andromeda {};
  # spaget = pkgs.callPackage ./spaget { target = "everyone"; };
  # xivlauncher = pkgs.callPackage ./xivlauncher { };
  # wip = pkgs.callPackage ./wip {};
  # "4kvideodownloaderplus" = pkgs.callPackage ./4kvideodownloaderplus {};
}
