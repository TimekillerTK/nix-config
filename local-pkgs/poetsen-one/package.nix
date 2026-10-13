{
  lib,
  stdenvNoCC,
}: stdenvNoCC.mkDerivation {
  pname = "poetsen-one";
  version = "2013-04-07";

  src = ./.;

  installPhase = ''
    install -Dm644 PoetsenOne-Regular.ttf "$out/share/fonts/truetype/PoetsenOne-Regular.ttf"
  '';

  meta = with lib; {
    description = "Poetsen One font";
    license = licenses.ofl;
    platforms = platforms.all;
  };
}
