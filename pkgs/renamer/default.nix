{ stdenv, pkgs, lib }:

pkgs.rustPlatform.buildRustPackage {
  pname = "renamer";
  version = "0.1.0";

  # cargoLock.lockFile = "./Cargo.lock"; # <- when local
  src = pkgs.fetchFromGitHub {
    owner = "TimekillerTK";
    repo = "renamer";
    rev = "main";
    sha256 = "sha256-8N3IOyLwz1gewrXtpjP2puHHCcaGRcLpPd2nRuUoKPk=";
  };

  # Required for building on MacOS
  buildInputs = [] ++ lib.optional stdenv.isDarwin pkgs.darwin.apple_sdk.frameworks.Security;

  # cargoHash = lib.fakeHash; # <- generate fake hash
  cargoHash = "sha256-vuczX9KLgnToiZlO3b1bCGV/TJwVQAt8oAL8mAeUKbo=";
}