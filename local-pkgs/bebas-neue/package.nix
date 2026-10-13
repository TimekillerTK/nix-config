{
  lib,
  stdenvNoCC,
}: stdenvNoCC.mkDerivation {
  pname = "bebas-neue";
  version = "2018-02-15";

  src = ./.;

  installPhase = ''
    install -Dm644 BebasNeue-Regular.ttf "$out/share/fonts/truetype/BebasNeue-Regular.ttf"
  '';

  meta = with lib; {
    description = "Bebas Neue font";
    license = licenses.ofl;
    platforms = platforms.all;
  };
}
