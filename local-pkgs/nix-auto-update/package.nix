{
  pkgs ? import <nixpkgs> {},
  lib,
  ...
}:
pkgs.rustPlatform.buildRustPackage {
  pname = "nix-auto-update";
  version = "0.1.19";

  src = pkgs.fetchFromGitLab {
    owner = "TimekillerTK";
    repo = "nix-auto-update";
    rev = "e455874d5302fc476a8438057a73e5511f27f2bf";
    sha256 = "sha256-W5Q9tPus5J2e+q1alD91qqFlN/Mc8NGaWJO+5SIGHjU=";
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
  cargoHash = "sha256-Euj2NQ3BAq/IqrI8JwP3yth77GAt7O5iAwIiFhH8BPQ=";
}
