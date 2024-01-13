# Example from: https://www.ertt.ca/nix/shell-scripts/
{
  description = "A simple test script";

  outputs = { self, nixpkgs }: {
    defaultPackage.x86_64-linux = self.packages.x86_64-linux.testscript;
    packages.x86_64-linux.testscript =

      let
        pkgs = import nixpkgs { system = "x86_64-linux"; };

        my-name = "testscript";
        my-src = builtins.readFile ./testscript.sh;
        my-script = (pkgs.writeScriptBin my-name my-src).overrideAttrs(old: {
          buildCommand = "${old.buildCommand}\n patchShebangs $out";
        });
        my-buildInputs = with pkgs; [ cowsay ddate ];

      in pkgs.symlinkJoin {
        name = my-name;
        paths = [ my-script ] ++ my-buildInputs;
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = "wrapProgram $out/bin/${my-name} --prefix PATH : $out/bin";
      };
  };
}