{
  inputs,
  lib,
  ...
}: {
  # Helper functions for creating nixos / home-manager configurations and others

  # This is for explicit type declaration and description and more helpful
  # error messages.
  #
  # These should also be seen as containers of other submodules.
  options.flake.lib = lib.mkOption {
    type = lib.types.attrsOf lib.types.unspecified;
    default = {};
  };

  # Factory is for flake modules which will accept parameters.
  options.flake.factory = lib.mkOption {
    type = lib.types.attrsOf lib.types.unspecified;
    default = {};
  };

  # This is for helper functions which are used for defining nixos
  # hosts and user homeManager configurations.
  config.flake.lib = {
    mkNixos = system: name: {
      ${name} = inputs.nixpkgs.lib.nixosSystem {
        modules = [
          inputs.self.modules.nixos.${name}
          {nixpkgs.hostPlatform = lib.mkDefault system;}
        ];
      };
    };

    mkHomeManager = system: name: {
      ${name} = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = inputs.nixpkgs.legacyPackages.${system};
        modules = [
          inputs.self.modules.homeManager.${name}
          {nixpkgs.config.allowUnfree = true;}
        ];
      };
    };
  };
}
