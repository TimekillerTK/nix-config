{inputs, ...}: {
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "vh-server";

  flake.modules.nixos.vh-server = {pkgs, ...}: {
    imports = [
      # Filesystems on this host are defined with disko
      inputs.disko.nixosModules.default
      ./_disko.nix

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

    networking.firewall.allowedTCPPorts = [80 3000 9090 9000];

    # Hostname
    networking.hostName = "vh-server";
  };
}
