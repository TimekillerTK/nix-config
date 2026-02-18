{self, ...}: {
  # Convenient factory function for creating users with default settings
  config.flake.factory.user = username: isAdmin: {
    nixos."${username}" = {
      lib,
      pkgs,
      ...
    }: {
      users.users."${username}" = {
        isNormalUser = true;
        shell = pkgs.zsh;
        initialPassword = "Hello123!";
        home = "/home/${username}";
        extraGroups = lib.optionals isAdmin [
          "wheel"
        ];
      };
      programs.zsh.enable = true;

      home-manager.users."${username}" = {
        imports = [
          self.modules.homeManager."${username}"
        ];
      };
    };
  };
}
