{
  pkgs ? import <nixpkgs> {},
  lib,
  ...
}:
pkgs.rustPlatform.buildRustPackage {
  pname = "nix-auto-update";
  version = "0.1.21";

  src = pkgs.fetchFromGitLab {
    owner = "TimekillerTK";
    repo = "nix-auto-update";
    rev = "409891de59bf80bcdf16d450038d632f238045a5";
    sha256 = "sha256-es8EZ459WPuU+6Q481zmgB47FOVnA7yb3yBD5BC+dp4=";
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
  cargoHash = "sha256-BUgVecsE/6Rgq26bZD8B69QxxXmT/4U2kCinXWjy4Bg=";
}
