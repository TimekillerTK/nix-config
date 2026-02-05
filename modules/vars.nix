{
  flake.modules.generic.systemConstants = {
    inputs,
    lib,
    ...
  }: {
    options.systemConstants = lib.mkOption {
      type = lib.types.attrsOf lib.types.unspecified;
      default = {};
    };

    config.systemConstants = {
      adminEmail = "admin@test.org";
      nixpkgs-unstable = inputs.nixpkgs-unstable;
    };
  };
}
