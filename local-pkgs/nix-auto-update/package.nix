{pkgs ? import <nixpkgs> {}, ...}:
pkgs.rustPlatform.buildRustPackage {
  pname = "nix-auto-update";
  version = "0.1.15";

  src = pkgs.fetchFromGitLab {
    owner = "TimekillerTK";
    repo = "nix-auto-update";
    rev = "a24ef465edf563c6e324db2b10484ce7b60ca336";
    sha256 = "sha256-eJfGl/bPimuHNbRAJD4GivnArrFtK8rFALEvFAyWwro=";
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

  cargoFeatures = ["desktop-environment"];
  cargoHash = "sha256-T23xpegpw4hfSJJYz8puk0WvIqjOtCGTP5hvxf6/+lA=";
}
