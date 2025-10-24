{
  stdenv,
  pkgs,
  lib,
}:
pkgs.rustPlatform.buildRustPackage {
  pname = "nix-auto-update";
  version = "0.0.1";

  src = pkgs.fetchFromGitLab {
    owner = "TimekillerTK";
    repo = "nix-auto-update";
    rev = "dev";
    sha256 = "sha256-G1FyT4uFNbbuRFHf47Y0sq2bqgWtgwsGNuRwYaOdX2A=";
  };

  # Required for building the binary
  buildInputs = [
    pkgs.openssl
  ];

  # cargoHash = lib.fakeHash; # <- generate fake hash
  cargoHash = "sha256-WQsdR02+KT5qrV+WHBONt+Su5SNLzQjFPnHyN5Vhxoc=";
}
