{
  pkgs ? import <nixpkgs> {},
  lib,
  ...
}:
pkgs.rustPlatform.buildRustPackage {
  pname = "nix-auto-update";
  version = "0.1.17";

  src = pkgs.fetchFromGitLab {
    owner = "TimekillerTK";
    repo = "nix-auto-update";
    rev = "500e49a61057d7adba9e8ede71d66c057b57886c";
    sha256 = "sha256-eK9eS1LNEtn1WeAKVXfzgbeoaNDi7oyqdRE73SGiO1o=";
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
  cargoHash = "sha256-j1PAZj3apZmSRyVnRXGpDTG7Hb7GovpFqWdAn16CZ0Q=";
}
