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
  stdenv.mkDerivation rec {
    inherit src version;
    name = "${model}drv-${version}";

    nativeBuildInputs = [dpkg makeWrapper];

    unpackPhase = "dpkg-deb -x $src $out";

    installPhase = ''
        dir="$out/${reldir}"
        substituteInPlace $dir/lpd/filter_${model} \
          --replace /usr/bin/perl ${perl}/bin/perl \
          --replace "BR_PRT_PATH =~" "BR_PRT_PATH = \"$dir\"; #" \
          --replace "PRINTER =~" "PRINTER = \"${model}\"; #"
        wrapProgram $dir/lpd/filter_${model} \
          --prefix PATH : ${lib.makeBinPath [
        coreutils
        ghostscript
        gnugrep
        gnused
        which
      ]}
      # need to use i686 glibc here, these are 32bit proprietary binaries
      patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
        $dir/lpd/brmfcl3750cdwfilter
    '';

    meta = {
      description = "Brother ${lib.strings.toUpper model} driver";
      homepage = "http://www.brother.com/";
      sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
      license = lib.licenses.unfree;
      platforms = ["x86_64-linux"];
      maintainers = [];
    };
  }
