{
  pkgs ? import <nixpkgs> {},
  lib,
  ...
}:
pkgs.rustPlatform.buildRustPackage {
  pname = "renamer";
  version = "0.1.4";

  src = pkgs.fetchFromGitHub {
    owner = "TimekillerTK";
    repo = "renamer";
    rev = "f1b34156415f3099097b144dce0d52809530c0be";
    sha256 = "sha256-c5dhU8BN83azEyGhim5MprmIXh2nps6Cf3/PTQ8eiVg=";
  };

  # cargoHash = lib.fakeHash; # <- generate fake hash
  cargoHash = "sha256-TMw1e8cMpMX6woGxNeVHZ2QSiUFVx22tH9s/xbHpiKQ=";
}
