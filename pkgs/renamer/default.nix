{ stdenv, pkgs, lib }:

pkgs.rustPlatform.buildRustPackage {
  pname = "renamer";
  version = "0.1.1";

  # cargoLock.lockFile = "./Cargo.lock"; # <- when local
  src = pkgs.fetchFromGitHub {
    owner = "TimekillerTK";
    repo = "renamer";
    rev = "main";
    sha256 = "sha256-FtxI7umh2VMsZqPCOQWqVGO2QbRnQbdD480NMFdYOms=";
  };

  # Required for building on MacOS
  buildInputs = [] ++ lib.optional stdenv.isDarwin pkgs.darwin.apple_sdk.frameworks.Security;

  # cargoHash = lib.fakeHash; # <- generate fake hash
  cargoHash = "sha256-YX98o9BTAqc1T8cRcjkLDFsHRcBrbYvf2WHZZPjHyWE=";
}