{
  pkgs,
  pythonPkgs ? pkgs.python3Packages,
  fetchPypi,
}:
pythonPkgs.buildPythonApplication {
  pname = "numlockw";
  version = "0.1.2";

  src = pkgs.fetchFromGitHub {
    owner = "xz-dev";
    repo = "numlockw";
    rev = "1800a5072323bbc026c80bc737285d8ea363af78";
    sha256 = "sha256-Z4ymxTw+OLh1k2Ysh3HQ3IbgJ+GkDb4EoR4lQjFBM48=";
  };

  dontBuild = true; # Skip the setup phase since there is no setup.py
  format = "other"; # Since not setup-tools based, skip

  # List your Python dependencies here
  propagatedBuildInputs = with pythonPkgs; [
    evdev
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp ./src/numlockw/__main__.py $out/bin/numlockw
    chmod +x $out/bin/numlockw
  '';

  # Ensure the Python interpreter is in the PATH
  preFixup = ''
    wrapProgram $out/bin/numlockw --prefix PATH : ${pythonPkgs.python}/bin
  '';
}
