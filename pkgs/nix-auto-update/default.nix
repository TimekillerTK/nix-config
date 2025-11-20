{
  pkgs,
  lib,
  ...
}:
pkgs.rustPlatform.buildRustPackage {
  pname = "nix-auto-update";
  version = "0.1.13";

  src = pkgs.fetchFromGitLab {
    owner = "TimekillerTK";
    repo = "nix-auto-update";
    rev = "51b8f7b13a1af48481d21e2d9dc0754db4cd28f5";
    sha256 = "sha256-oKEgcxjR9mZ8NmiCmuRFS2eCiozt8AMVct2TlYqtrxo=";
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

  cargoHash = "sha256-UuvWEYy/4ki4BetxnzHPIDHwxRbyTl9zbRL72meqdrg=";
}
