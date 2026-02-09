{inputs, ...}: {
  # Using our elsewhere defined functions mkNixos and mkHomeManager
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "example";
  flake.homeConfigurations = inputs.self.lib.mkHomeManager "x86_64-linux" "example";

  flake.modules.homeManager.example = {pkgs, ...}: {
    imports = [
      inputs.self.modules.homeManager.git
      inputs.self.modules.generic.unstable
      inputs.self.modules.generic.local-pkgs
    ];

    # Using our locally defined (in this git repo)
    # custom package
    home.packages = with pkgs; [
      local.custompkg
    ];
  };

  flake.modules.nixos.example = {pkgs, ...}: {
    imports = [
      inputs.self.modules.nixos.examplehw
      inputs.self.modules.generic.unstable
      inputs.self.modules.generic.local-pkgs
    ];

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
      packages = with pkgs; [
      ];
    };

    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;

    environment.systemPackages = with pkgs; [
      vim
      unstable.yazi
      local.custompkg
      local.renamer
    ];
    # Enable the OpenSSH daemon.
    services.openssh.enable = true;

    system.stateVersion = "25.05";
  };
}
