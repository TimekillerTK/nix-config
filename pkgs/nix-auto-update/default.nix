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
    rev = "c4c1715c7202b14f309fbae8566122d4c1080c5a";
    sha256 = "sha256-WDkVcx0aYu557dRciN7iFwDxmRhdGQhWzaozmCoHbak=";
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
