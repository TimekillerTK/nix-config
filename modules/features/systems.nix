{inputs, ...}: {
  # Required to define systems, otherwise:
  #
  #  error: The option `systems' was accessed but has no value defined. Try setting the option.
  #
  systems = ["x86_64-linux" "aarch64-darwin"];

  # TODO: Look into this for nix configuration:
  # https://github.com/henrysipp/nix-setup/blob/48a93d0275eba0adf48977609fc100dce8f9b49c/modules/base/nix.nix
  # ^^^ Fantastic defaults probably, but we need to first understand before we mindlessly
  # copy-paste

  # This is part of the setup guide in
  # https://github.com/Doc-Steve/dendritic-design-with-flake-parts/wiki/Basics#basics-for-usage-of-the-dendritic-pattern
  #
  # It is not required per se, but it is required to be imported with
  # the current way this repo is set up - if skipped:
  #
  # error: infinite recursion encountered
  #        at /nix/store/zdfpzgjrlxmdiiydiv3vqgvbzbg5fkx0-source/lib/modules.nix:1256:41:
  #          1255|
  #          1256|     optionalValue = if isDefined then { value = mergedValue; } else { };
  #              |                                         ^
  #          1257|   };
  #
  # If you want to skip these imports, see previous commits such as
  # https://github.com/TimekillerTK/nix-config/tree/63e62b07b214b92a0d6cfee9701bb8eaae068100
  imports = [
    inputs.flake-parts.flakeModules.modules
    inputs.home-manager.flakeModules.home-manager
    inputs.pkgs-by-name-for-flake-parts.flakeModule
  ];

  perSystem = {
    pkgs,
    system,
    ...
  }: let
    install_script = pkgs.writeShellScriptBin "install_script" ''
      ${builtins.readFile ../../scripts/disko-partition.sh}
    '';
    commonPackages = with pkgs; [
      install_script
      home-manager
      git
      sops
      ssh-to-age
      age
      disko # Nix disk partitioning/formatting
      nvd # Nix/NixOS package version diff tool
    ];
  in {
    # Dev environment with everything you need, to use
    # run `nix develop`
    devShells.default = pkgs.mkShell {
      packages = commonPackages;
      shellHook = ''
        export NIX_CONFIG="experimental-features = nix-command flakes"
        echo "Welcome to the default dev shell for ${system}"
      '';
    };

    # Package set for `nix shell`
    packages.default = pkgs.buildEnv {
      name = "default";
      paths = commonPackages;
    };
  };
}
