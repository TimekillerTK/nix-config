{pkgs ? import <nixpkgs> {}, ...}:
pkgs.stdenv.mkDerivation {
  pname = "kwin-toggleterminal";
  version = "v2.1.1";

  src = pkgs.fetchFromGitHub {
    owner = "DvdGiessen";
    repo = "kwin-toggleterminal";
    rev = "b7e9f823db8f85e93ab7aa3bbf3aa2df199233ca";
    sha256 = "sha256-IzWBxhBPb+fMkiyPC9f8cdxW6nf+FFPJPi99hDJ5Nkk=";
  };

  installPhase = ''
    mkdir -p $out/share/kwin/scripts
    cp -r . $out/share/kwin/scripts/toggleterminal
  '';
}
