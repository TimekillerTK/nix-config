{ stdenv, pkgs, lib }:

pkgs.rustPlatform.buildRustPackage {
  pname = "renamer";
  version = "0.1.2";

  # cargoLock.lockFile = "./Cargo.lock"; # <- when local
  src = pkgs.fetchFromGitHub {
    owner = "TimekillerTK";
    repo = "renamer";
    rev = "main";
    sha256 = "sha256-NVvUMCl35yInLllkzsXK5vnvZktu/beVnjN5vqwGw88=";
  };

  # Required for building on MacOS
  buildInputs = [] ++ lib.optional stdenv.isDarwin pkgs.darwin.apple_sdk.frameworks.Security;

  # cargoHash = lib.fakeHash; # <- generate fake hash
  cargoHash = "sha256-T4GNC/jDnKH4lZ8YIUcrN2gePD3C4ZYxnf/mzYitOxE=";
}
