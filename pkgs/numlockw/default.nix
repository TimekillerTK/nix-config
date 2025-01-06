{
  pkgs,
  pythonPkgs ? pkgs.python3Packages,
}:
pythonPkgs.buildPythonApplication {
  pname = "numlockw";
  version = "0.1.2";

  # cargoLock.lockFile = "./Cargo.lock"; # <- when local
  src = pkgs.fetchFromGitHub {
    owner = "xz-dev";
    repo = "numlockw";
    rev = "1800a5072323bbc026c80bc737285d8ea363af78";
    sha256 = "sha256-Z4ymxTw+OLh1k2Ysh3HQ3IbgJ+GkDb4EoR4lQjFBM48=";
  };

  propagatedBuildInputs = with pythonPkgs; [
    # List your Python dependencies here
    evdev
  ];
}
