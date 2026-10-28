{
  pkgs ? import <nixpkgs> {},
  ...
}:
pkgs.writeScriptBin "wow-large-address-aware"
("#!${pkgs.python3}/bin/python3\n" + builtins.readFile ./wow-large-address-aware.py)
