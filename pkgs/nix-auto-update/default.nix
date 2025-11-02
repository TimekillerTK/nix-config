{
  stdenv,
  pkgs,
  lib,
}:
pkgs.rustPlatform.buildRustPackage {
  pname = "nix-auto-update";
  version = "0.1.6";

  src = pkgs.fetchFromGitLab {
    owner = "TimekillerTK";
    repo = "nix-auto-update";
    rev = "959dfecc53eeced1de4d6ecb5a71e02721781ae5";
    sha256 = "sha256-liYprnTP5G6N6ggskHFEg/7b7QWtJxzSwe9o9iEu+mU=";
  };

  # Required for building the binary
  buildInputs = [
    pkgs.openssl
  ];

  # Environment Variables required for the build
  env = {
    # for openssl
    OPENSSL_DIR = "${pkgs.openssl.dev}";
    OPENSSL_LIB_DIR = "${pkgs.openssl.out}/lib";
    PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
  };

  cargoHash = "sha256-JnBz8A3ueKMTCHAkUrwj6tYDwYqBSz5H/MFXCv89NIk=";
}
