{
  pkgs ? import <nixpkgs> {},
  stdenv,
  fetchurl,
  dpkg,
  makeWrapper,
  coreutils,
  ghostscript,
  gnugrep,
  gnused,
  which,
  perl,
  lib,
}: let
  model = "mfcl3750cdw";
  version = "1.0.2-0";
  src = fetchurl {
    url = "https://download.brother.com/welcome/dlf103934/${model}pdrv-${version}.i386.deb";
    sha256 = "02srx2myyh8ix1xk5ymylk3r9hkf50vfyrl23gfqy835l84my39s";
  };
  reldir = "opt/brother/Printers/${model}/";
in
  stdenv.mkDerivation {
    inherit version src;
    name = "${model}cupswrapper-${version}";

    nativeBuildInputs = [dpkg makeWrapper];

    unpackPhase = "dpkg-deb -x $src $out";

    installPhase = ''
      basedir=$out/${reldir}
      dir=$out/${reldir}
      substituteInPlace $dir/cupswrapper/brother_lpdwrapper_${model} \
        --replace /usr/bin/perl ${perl}/bin/perl \
        --replace "basedir =~" "basedir = \"$basedir\"; #" \
        --replace "PRINTER =~" "PRINTER = \"${model}\"; #"
      wrapProgram $dir/cupswrapper/brother_lpdwrapper_${model} \
        --prefix PATH : ${lib.makeBinPath [coreutils gnugrep gnused]}
      mkdir -p $out/lib/cups/filter
      mkdir -p $out/share/cups/model
      ln $dir/cupswrapper/brother_lpdwrapper_${model} $out/lib/cups/filter
      ln $dir/cupswrapper/brother_${model}_printer_en.ppd $out/share/cups/model
    '';

    meta = {
      description = "Brother ${lib.strings.toUpper model} CUPS wrapper driver";
      homepage = "http://www.brother.com/";
      sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
      license = lib.licenses.gpl2;
      platforms = ["x86_64-linux"];
      maintainers = [];
    };
  }
