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
    rev = "0f3c223b9c7b7b21e72d35b943f7f10483caee61";
    sha256 = "sha256-bKDpozK/6bFfl8J33RY0uXCPItdCDcqYaKaLN7qw6Bw=";
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

  cargoHash = "sha256-6mSQ8/9RTQQYLO/xfu0lLrt5F+nd+/OWfR+mkxYc2TM=";
}
