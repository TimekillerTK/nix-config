{pkgs ? import <nixpkgs> {}, ...}:
pkgs.rustPlatform.buildRustPackage {
  pname = "renamer";
  version = "0.1.3";

  # cargoLock.lockFile = "./Cargo.lock"; # <- when local
  src = pkgs.fetchFromGitHub {
    owner = "TimekillerTK";
    repo = "renamer";
    rev = "main";
    sha256 = "sha256-7tSF4PmZp5VGSCIq/8dzPwHCJW4XJqdoKRzz81oBbSw=";
  };

  # # Required for building on MacOS
  # buildInputs = [] ++ lib.optional stdenv.isDarwin pkgs.darwin.apple_sdk.frameworks.Security;

  # cargoHash = lib.fakeHash; # <- generate fake hash
  cargoHash = "sha256-edKQbvLprErcv6YxzZlWw6V//8nmuPFA0MH/T0mITDA=";
}
