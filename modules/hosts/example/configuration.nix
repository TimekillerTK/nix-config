{inputs, ...}: {
  # Using our elsewhere defined functions mkNixos and mkHomeManager
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "example";

  flake.modules.nixos.example = {pkgs, ...}: {
    imports = [
      inputs.self.modules.nixos.system-cli
      inputs.self.modules.nixos.secrets

      inputs.self.modules.nixos.home-manager
      inputs.self.modules.nixos.usr
    ];

    # Example SOPS Secret
    sops = {
      defaultSopsFile = ../../../secrets/example.yml;
      secrets.hello = {};
    };

    networking.hostName = "example"; # Define your hostname.

    environment.systemPackages = with pkgs; [
      local.renamer
    ];
  };
}
