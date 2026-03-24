{inputs, ...}: {
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "nix-cache";

  flake.modules.nixos.nix-cache = {pkgs, ...}: {
    imports = [
      # Filesystems on this host are defined with disko
      inputs.disko.nixosModules.default
      ./_disko.nix

      inputs.self.modules.nixos.nix-binary-cache
      inputs.self.modules.nixos.system-minimal
      inputs.self.modules.nixos.home-manager
      inputs.self.modules.nixos.tk
    ];

    home-manager.users.tk = {
      imports = [
        inputs.self.modules.homeManager.system-minimal
      ];
      # Normal home-manager config stuff goes here
    };

    # Cache user to allow uploading stuff to the nix store
    #
    nix.settings.allowed-users = ["cache"];
    users.users.cache = {
      shell = pkgs.zsh;
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
        (builtins.readFile ../../../pub_keys/nix-cache-user.pub)
      ];
    };
    security.sudo.extraRules = [
      {
        users = ["cache"];
        commands = [
          {
            # for `sudo nix build`
            # command = "${pkgs.nix}/bin/nix";
            command = "ALL";
            options = ["NOPASSWD"];
          }
          # {
          #   # for old `nix-build`
          #   command = "${pkgs.nix}/bin/nix-build";
          #   options = ["NOPASSWD"];
          # }
        ];
      }
    ];

    # Hostname
    networking.hostName = "nix-cache";
  };
}
