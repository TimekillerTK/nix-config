{
  pkgs ? import <nixpkgs> {},
  lib,
  ...
}:
pkgs.rustPlatform.buildRustPackage {
  pname = "nix-auto-update";
  version = "0.1.16";

  src = pkgs.fetchFromGitLab {
    owner = "TimekillerTK";
    repo = "nix-auto-update";
    rev = "ba4946aadb4e9efc2ad599763b893baf7ed06226";
    sha256 = "sha256-MIB6i6Bjlis3l9afjok8oIpJMtKwhO6qJOvudn0Pt2A=";
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
  cargoHash = "sha256-Pv8bmjlOAzEjKoUhNMncjNmyIio9HTHHIpoh+QDFDeE=";
}
