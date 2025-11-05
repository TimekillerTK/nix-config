{
  stdenv,
  pkgs,
  lib,
}:
pkgs.rustPlatform.buildRustPackage {
  pname = "nix-auto-update";
  version = "0.1.7";

  src = pkgs.fetchFromGitLab {
    owner = "TimekillerTK";
    repo = "nix-auto-update";
    rev = "d4ebcc793fdc8b83a034b78709230b2ca69737e8";
    sha256 = "sha256-LbGpTBaX5JeGQUjmTYsxiMnl4HdNgVd3uY4R3QpeT5s=";
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

  cargoHash = "sha256-HNJvW1oN+m0t2LIzlUHNeQp/TQ5e17uOY2tY3vcLe0s=";
}
