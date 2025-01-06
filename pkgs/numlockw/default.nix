{
  pkgs,
  pythonPkgs ? pkgs.python3Packages,
  fetchPypi,
}:
pythonPkgs.buildPythonApplication rec {
  pname = "numlockw";
  version = "0.1.2";

  # src = pkgs.fetchFromGitHub {
  #   owner = "xz-dev";
  #   repo = "numlockw";
  #   rev = "1800a5072323bbc026c80bc737285d8ea363af78";
  #   sha256 = "sha256-Z4ymxTw+OLh1k2Ysh3HQ3IbgJ+GkDb4EoR4lQjFBM48=";
  # };
  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-b5/x9qC98Upd8z56ovTHi36DCAEz+PtNOjJTHnAfZcU=";
  };

  # If your app doesn't have tests, you can disable them
  doCheck = false;

  propagatedBuildInputs = with pythonPkgs; [
    # List your Python dependencies here
    evdev
  ];

  # installPhase = ''
  #   mkdir -p $out/bin
  #   cp your_main_script.py $out/bin/your-application
  #   chmod +x $out/bin/your-application
  # '';
}
