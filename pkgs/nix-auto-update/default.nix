{
  stdenv,
  pkgs,
  lib,
}:
pkgs.rustPlatform.buildRustPackage {
  pname = "nix-auto-update";
  version = "0.1.3";

  src = pkgs.fetchFromGitLab {
    owner = "TimekillerTK";
    repo = "nix-auto-update";
    rev = "0931b2349e044e79e5cfb9d1e6879376a5dd0a96";
    sha256 = "sha256-EKQcopy7oLZEXlUeuTgE8Sbgm4Lk9Drn+O5+a1OLVVM=";
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

  cargoHash = "sha256-fxPea9PrIW04wP+p1etXzNsUkZtYpnUnNv/LaFRFg2M=";
}
