{ pkgs }:

# This is for a SDDM theme specifically.
pkgs.stdenv.mkDerivation {
  pname = "andromeda-kde";
  version = "0.1.0";

  src = pkgs.fetchFromGitHub {
    owner = "EliverLara";
    repo = "Andromeda-KDE";
    rev = "8d7fe15d9df526367abfb8ed71e0f0bbaeb32344";
    sha256 = "013n7y1vyz7y86kdg7cx3j3jz27bb3799rr7q3bs4zx10gd12y4p";
  };

  installPhase = ''
    mkdir -p $out
    cp -R ./sddm/* $out/
  '';
}
