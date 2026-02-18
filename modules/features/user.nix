{self, ...}: {
  # Convenient factory function for creating users with default settings
  config.flake.factory.user = username: isAdmin: {
    nixos."${username}" = {
      lib,
      pkgs,
      ...
    }: {
      # User settings with default initial password, optionally
      # added to wheel group if Admin
      users.users."${username}" = {
        isNormalUser = true;
        shell = pkgs.zsh;
        initialPassword = "Hello123!";
        home = "/home/${username}";
        extraGroups = lib.optionals isAdmin [
          "wheel"
        ];
      };

      # Passwordless Sudo for Admin
      security.sudo.extraRules = lib.optionals isAdmin [
        {
          users = ["${username}"];
          commands = [
            {
              command = "ALL";
              options = ["NOPASSWD"];
            }
          ];
        }
      ];

      # Needed since it's our users default shell
      programs.zsh.enable = true;

      # Mandatory part to make home-manager work with our configuration
      home-manager.users."${username}" = {
        imports = [
          self.modules.homeManager."${username}"
        ];
      };
    };
  };
}
