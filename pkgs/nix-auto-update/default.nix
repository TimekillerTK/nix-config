{
  stdenv,
  pkgs,
  lib,
}:
pkgs.rustPlatform.buildRustPackage {
  pname = "nix-auto-update";
  version = "0.1.0";

  src = pkgs.fetchFromGitLab {
    owner = "TimekillerTK";
    repo = "nix-auto-update";
    rev = "e2624bc853b3634847fd279143b3376fc32612c0";
    sha256 = "sha256-UkCc07qeUuNC3qjJpH5pX6LNk/ykOjul7e6GkK9fgZk=";
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

  cargoHash = "sha256-hKWAgN/RZSe6UpOrm4fuR+j+9kiI18R0i4P7HKy0UvU=";
}
