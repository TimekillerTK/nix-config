{inputs, ...}: {
  # ^^^^ NOTE: inputs should ONLY be imported AND used here, but not in
  # flake.nixosModules, otherwise there will be errors:
  #
  #      … while evaluating the module argument `pkgs' in "/nix/store/kgp2lkqawayipws2p64flyp06sgzzf0r-source/nixos/modules/services/hardware/bluetooth.nix":

  #      … noting that argument `pkgs` is not externally provided, so querying `_module.args` instead, requiring `config`

  #      … while evaluating definitions from `/nix/store/d7dlhyafrb6prmscpx4qmpqqnh10i985-source/modules/examplehw.nix, via option flake.nixosModules.examplehw':

  #      … while evaluating the module argument `inputs' in ":anon-1974:anon-1:anon-1:anon-1:anon-1":

  #      … noting that argument `inputs` is not externally provided, so querying `_module.args` instead, requiring `config`

  #      (stack trace truncated; use '--show-trace' to show the full, detailed trace)

  #      error: attribute 'inputs' missing
  #      at /nix/store/kgp2lkqawayipws2p64flyp06sgzzf0r-source/lib/modules.nix:685:13:
  #         684|             "noting that argument `${name}` is not externally provided, so querying `_module.args` instead, requiring `config`"
  #         685|             config._module.args.${name}
  #            |             ^
  #         686|           )
  #
  # ------ ------ ------ ------ ------ ------ ------ ------ ------ ------ ------ ------ ------
  #
  #        … while evaluating a branch condition
  #          at /nix/store/kgp2lkqawayipws2p64flyp06sgzzf0r-source/lib/lists.nix:142:18:
  #           141|       len = length list;
  #           142|       fold' = n: if n == len then nul else op (elemat list n) (fold' (n + 1));
  #              |                  ^
  #           143|     in

  #        … while calling the 'length' builtin
  #          at /nix/store/kgp2lkqawayipws2p64flyp06sgzzf0r-source/lib/lists.nix:141:13:
  #           140|     let
  #           141|       len = length list;
  #              |             ^
  #           142|       fold' = n: if n == len then nul else op (elemat list n) (fold' (n + 1));

  #        … while evaluating the module argument `inputs' in ":anon-1:anon-1:anon-1:anon-1:anon-1":

  #        … noting that argument `inputs` is not externally provided, so querying `_module.args` instead, requiring `config`

  #        … if you get an infinite recursion here, you probably reference `config` in `imports`. if you are trying to achieve a conditional import behavior dependent on `config`, consider importing unconditionally, and using `mkenableoption` and `mkif` to control its effect.

  #        (stack trace truncated; use '--show-trace' to show the full, detailed trace)

  #        error: infinite recursion encountered

  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "example";
  flake.homeConfigurations = inputs.self.lib.mkHomeManager "x86_64-linux" "example";

  flake.modules.homeManager.example = {
    imports = with inputs.self.modules.homeManager; [
      git
    ];
  };

  flake.modules.nixos.example = {
    pkgs,
    # config,
    ...
  }: {
    imports = with inputs.self.modules.nixos;
      [
        examplehw
      ]
      ++ (with inputs.self.modules.generic; [
        systemConstants
      ]);

    nix.settings.experimental-features = ["nix-command" "flakes"];
    networking.hostName = "dendritic"; # Define your hostname.

    # Enable networking
    networking.networkmanager.enable = true;

    # Set your time zone.
    time.timeZone = "Europe/Amsterdam";

    # Select internationalisation properties.
    i18n.defaultLocale = "en_US.UTF-8";

    i18n.extraLocaleSettings = {
      LC_ADDRESS = "nl_NL.UTF-8";
      LC_IDENTIFICATION = "nl_NL.UTF-8";
      LC_MEASUREMENT = "nl_NL.UTF-8";
      LC_MONETARY = "nl_NL.UTF-8";
      LC_NAME = "nl_NL.UTF-8";
      LC_NUMERIC = "nl_NL.UTF-8";
      LC_PAPER = "nl_NL.UTF-8";
      LC_TELEPHONE = "nl_NL.UTF-8";
      LC_TIME = "nl_NL.UTF-8";
    };

    # Configure keymap in X11
    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };

    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.users.tk = {
      isNormalUser = true;
      description = "tk";
      extraGroups = ["networkmanager" "wheel"];
      packages = with pkgs; [];
    };

    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;

    environment.systemPackages = with pkgs; [
      vim
      # unstable.yazi
    ];
    # Enable the OpenSSH daemon.
    services.openssh.enable = true;

    system.stateVersion = "25.05";
  };
}
