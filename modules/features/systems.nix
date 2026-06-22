{inputs, ...}: {
  # Required to define systems, otherwise:
  #
  #  error: The option `systems' was accessed but has no value defined. Try setting the option.
  #
  systems = ["x86_64-linux" "aarch64-darwin" "aarch64-linux"];

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
    install-os = pkgs.writeShellScriptBin "install-os" ''
      ${builtins.readFile ../../scripts/install-os.sh}
    '';
    hostNames = builtins.attrNames inputs.self.nixosConfigurations;
    checkAllScript = builtins.replaceStrings ["@hosts@"] [
      (builtins.concatStringsSep " " hostNames)
    ] (builtins.readFile ../../scripts/check-all.sh);
    check-all = pkgs.writeShellScriptBin "check-all" checkAllScript;
    commonPackages = with pkgs;
      [
        git
        sops
        ssh-to-age
        age
        nvd # Nix/NixOS package version diff tool
        check-all
      ]
      ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
        disko # Nix disk partitioning/formatting
        install-os
      ];
  in {
    # Dev environment with everything you need, to use
    # run `nix develop`
    devShells.default = pkgs.mkShell {
      packages = commonPackages;
      shellHook = ''
        export NIX_CONFIG="experimental-features = nix-command flakes"
        echo "Welcome to the default dev shell for ${system}!"
        echo ""
        echo "To validate all nixosConfigurations, run 'check-all'."
        echo ""
        echo "To install NixOS on the current computer, use the"
        echo "'sudo install-os' command."
        echo ""
        echo "NOTE: ONLY AVAILABLE ON NIXOS INSTALLER (!)"
      '';
    };

    # Package set for `nix shell`
    packages.default = pkgs.buildEnv {
      name = "default";
      paths = commonPackages;
    };
  };
}
