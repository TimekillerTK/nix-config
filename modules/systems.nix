{inputs, ...}: {
  # Required to define systems, otherwise:
  #
  #  error: The option `systems' was accessed but has no value defined. Try setting the option.
  #
  systems = ["x86_64-linux"];

  # TODO: Look into this for nix configuration:
  # https://github.com/henrysipp/nix-setup/blob/48a93d0275eba0adf48977609fc100dce8f9b49c/modules/base/nix.nix
  # ^^^ Fantastic defaults probably, but we need to first understand before we mindlessly
  # copy-paste

  # This is part of the setup guide in
  # https://github.com/Doc-Steve/dendritic-design-with-flake-parts/wiki/Basics#basics-for-usage-of-the-dendritic-pattern
  #
  # But is it really required? Need to check...
  imports = [
    inputs.flake-parts.flakeModules.modules
    # inputs.home-manager.flakeModules.home-manager
  ];
}
