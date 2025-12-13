{
  pkgs,
  lib,
  ...
}:
pkgs.rustPlatform.buildRustPackage {
  pname = "nix-auto-update";
  version = "0.1.15";

  src = pkgs.fetchFromGitLab {
    owner = "TimekillerTK";
    repo = "nix-auto-update";
    rev = "159828bfb324fbb19755b5e12c48bac26fdf02d5";
    sha256 = "sha256-YCVKG3N4d/W2Kgu7h3Kmaaa28JGHVAomtt4JvwXgcQE=";
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

  cargoHash = "sha256-T23xpegpw4hfSJJYz8puk0WvIqjOtCGTP5hvxf6/+lA=";
}
