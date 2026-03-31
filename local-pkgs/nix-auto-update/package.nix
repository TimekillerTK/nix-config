{
  pkgs ? import <nixpkgs> {},
  lib,
  ...
}:
pkgs.rustPlatform.buildRustPackage {
  pname = "nix-auto-update";
  version = "0.1.18";

  src = pkgs.fetchFromGitLab {
    owner = "TimekillerTK";
    repo = "nix-auto-update";
    rev = "c403471fe46ad343909987e8026614db935f2c26";
    sha256 = "sha256-yc2XHX8Dg2YRGXbOS/BxIxzjSu8c9uEmpYJ+SBvq2zs=";
  };

  # Required for building the binary
  buildInputs = [
    pkgs.openssl
  ];

  # Skips running `cargo test` which is currently broken because
  # the test checks hostname - this is unavailable in the sandbox
  # envvironment where nix build runs, so we need to skip it.
  #
  # Better solution => test which doesn't need hostname to succeed
  doCheck = false;

  # Environment Variables required for the build
  env = {
    # for openssl
    OPENSSL_DIR = "${pkgs.openssl.dev}";
    OPENSSL_LIB_DIR = "${pkgs.openssl.out}/lib";
    PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
  };

  cargoFeatures = ["desktop-environment"];
  cargoHash = "sha256-9DcHmOMJHqmXLSxmUbcg4/a7eEfyM2j+RnbT1KMb/wU=";
}
