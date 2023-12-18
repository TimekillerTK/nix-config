{ 
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  outputs = { self, nixpkgs }:
    let
      pkgs = import nixpkgs { system = "x86_64-linux";};
    in
    {
      # NOTE: This is busted - probably older poetry doesn't mesh well with newer Python versions
      x = pkgs.poetry.overrideAttrs (old: {
        src = pkgs.fetchFromGitHub {
          owner = "python-poetry";
          repo = "poetry"; 
          rev = "1.6.1";
          hash = "";
        };
      });
    };
}
