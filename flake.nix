{
  description = "TK's Nix Configs";

  inputs = {
    # Nixpkgs Stable - https://github.com/NixOS/nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";

    # Nixpkgs Version 2305 - https://github.com/NixOS/nixpkgs
    nixpkgs-v2305.url = "github:nixos/nixpkgs/nixos-23.05";

    # Nixpkgs Unstable
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";

    # Disko (Disk Config)
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    # Home Manager - https://github.com/nix-community/home-manager
    home-manager.url = "github:nix-community/home-manager/release-23.11"; 
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Atomic, declarative, and reproducible secret provisioning for NixOS based on sops.
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    # For VS Code Remote to work on NixOS
    vscode-server.url = "github:nix-community/nixos-vscode-server";

    # Community VS Code Extensions
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";

    # For managing KDE Plasma
    plasma-manager.url = "github:pjones/plasma-manager";
    plasma-manager.inputs.nixpkgs.follows = "nixpkgs";
    plasma-manager.inputs.home-manager.follows = "home-manager";

    # Deploy-rs
    deploy-rs.url = "github:serokell/deploy-rs";
  };

  outputs = { self, nixpkgs, home-manager, ... } @ inputs:
  let
    inherit (self) outputs;
    lib = nixpkgs.lib // home-manager.lib;

    # Supported systems for your flake packages, shell, etc.
    systems = [
      "aarch64-linux"
      "i686-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];

    # This is a function that generates an attribute by calling a function you
    # pass to it, with each system as an argument
    forEachSystem = f: lib.genAttrs systems (system: f pkgsFor.${system});
    pkgsFor = lib.genAttrs systems (system: import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    });
  in
  {
    inherit lib;

    # Reusable nixos modules you might want to export (shareable)
    nixosModules = import ./modules/nixos;
    homeManagerModules = import ./modules/home-manager;

    # Your custom packages and modifications, exported as overlays
    overlays = import ./overlays {inherit inputs;};

    # Your custom packages
    # Accessible through 'nix build', 'nix shell', etc
    packages = forEachSystem (pkgs: import ./pkgs { inherit pkgs; });

    # Formatter for your nix files, available through 'nix fmt'
    formatter = forEachSystem (pkgs: pkgs.alejandra);

    # DevShells for each system
    devShells = forEachSystem (pkgs: import ./shell.nix { inherit pkgs; });

    # Available through 'nixos-rebuild --flake .#your-hostname'
    nixosConfigurations = {
      deployme = lib.nixosSystem {
        modules = [ ./hosts/deployme ];
        specialArgs = {inherit inputs outputs;};
      };
      nix-test = lib.nixosSystem {
        modules = [ ./hosts/nix-test ];
        specialArgs = {inherit inputs outputs;};
      };
      router = lib.nixosSystem {
        modules = [ ./hosts/router ];
        specialArgs = {inherit inputs outputs;};
      };
      dockerhost = lib.nixosSystem {
        modules = [ ./hosts/dockerhost ];
        specialArgs = {inherit inputs outputs;};
      };
    };

    # Available through 'home-manager --flake .#your-username@your-hostname'
    # NOTE: Home-manager requires a 'pkgs' instance
    homeConfigurations = {
      "tk@nix-test" = lib.homeManagerConfiguration {
        modules = [ ./home/tk/nix-test.nix ];
        pkgs = pkgsFor.x86_64-linux;
        extraSpecialArgs = {inherit inputs outputs;};
      };
    };

    deploy.nodes = {
      nix-test = { 
        hostname = "nix-test.cyn.local";
        profiles.system = {
          sshUser = "tk";
          user = "root";
          path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.nix-test;
        };
      };
      deployme = { 
        hostname = "deployme.cyn.local";
        profiles.system = {
          sshUser = "tk";
          user = "root";
          path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.deployme;
        };
        profiles.tk = {
          sshUser = "tk";
          user = "tk";
          path = inputs.deploy-rs.lib.x86_64-linux.activate.custom self.homeConfigurations."tk@nix-test".activationPackage "$PROFILE/activate";
        };
      };
      router = {
        hostname = "router.cyn.local";
        profiles.system = {
          sshUser = "tk";
          user = "root";
          path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.router;
        };
      };
      dockerhost = {
        hostname = "dev-dockerhost.cyn.local";
        profiles.system = {
          sshUser = "tk";
          user = "root";
          path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.dockerhost;
        };
      };
    };

    # (deploy-rs) This is highly advised, and will prevent many possible mistakes
    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) inputs.deploy-rs.lib;
  };
}
