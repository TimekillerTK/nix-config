{
  pkgs,
  lib,
  ...
}:
pkgs.rustPlatform.buildRustPackage {
  pname = "nix-auto-update";
  version = "0.1.10";

  src = pkgs.fetchFromGitLab {
    owner = "TimekillerTK";
    repo = "nix-auto-update";
    rev = "3e9a7081651373df194cfa319671da575e2bdde5";
    sha256 = "sha256-qnm9kCvGhoq9XmAc3O7UmaK7G8Gn8XhAtZYV+pQwWb0=";
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

  cargoHash = "sha256-Fjwb2zPDe1vWCt5YUpniAxc0izOY0PiMuiQmdQlp9e8=";
}
