{
  description = "TK's Nix Configs";

  inputs = {
    # Nixpkgs Stable - https://github.com/NixOS/nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

    # Nixpkgs Version 2411 - https://github.com/NixOS/nixpkgs
    nixpkgs-v2411.url = "github:nixos/nixpkgs/nixos-24.11";

    # Nixpkgs Version 2405 - https://github.com/NixOS/nixpkgs
    nixpkgs-v2405.url = "github:nixos/nixpkgs/nixos-24.05";

    # Nixpkgs Unstable
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";

    # Nixpkgs Caddy Pin to 2.8.4 due to issues with 2.10
    nixpkgs-caddy.url = "github:NixOS/nixpkgs/a880f49904d68b5e53338d1e8c7bf80f59903928";

    # Disko (Disk Config)
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    # Home Manager - https://github.com/nix-community/home-manager
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Atomic, declarative, and reproducible secret provisioning for NixOS based on sops.
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    # For VS Code Remote to work on NixOS
    vscode-server.url = "github:nix-community/nixos-vscode-server";

    # NOTE: Disabled because unused
    # # Community VS Code Extensions
    # nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";

    # For managing KDE Plasma 6
    plasma-manager6.url = "github:nix-community/plasma-manager";
    plasma-manager6.inputs.nixpkgs.follows = "nixpkgs";
    plasma-manager6.inputs.home-manager.follows = "home-manager";

    # Deploy-rs
    deploy-rs.url = "github:serokell/deploy-rs";

    # NixOS Hardware
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Managing flatpaks declartively
    nix-flatpak.url = "github:gmodena/nix-flatpak";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nix-flatpak,
    ...
  } @ inputs: let
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
    pkgsFor = lib.genAttrs systems (system:
      import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      });
  in {
    inherit lib;

    # Reusable nixos modules you might want to export (shareable)
    nixosModules = import ./modules/nixos;
    homeManagerModules = import ./modules/home-manager;

    # Your custom packages and modifications, exported as overlays
    overlays = import ./overlays {inherit inputs;};

    # Your custom packages
    # Accessible through 'nix build', 'nix shell', etc
    packages = forEachSystem (pkgs: import ./pkgs {inherit pkgs;});

    # Formatter for your nix files, available through 'nix fmt'
    formatter = forEachSystem (pkgs: pkgs.alejandra);

    # DevShells for each system
    devShells = forEachSystem (pkgs: import ./shell.nix {inherit pkgs;});

    # Available through 'nixos-rebuild --flake .#your-hostname'
    nixosConfigurations = {
      router = lib.nixosSystem {
        modules = [./hosts/router];
        specialArgs = {inherit inputs outputs;};
      };
      dockerhost = lib.nixosSystem {
        modules = [./hosts/dockerhost];
        specialArgs = {inherit inputs outputs;};
      };
      beltanimal = lib.nixosSystem {
        modules = [./hosts/beltanimal];
        specialArgs = {inherit inputs outputs;};
      };
      anya = lib.nixosSystem {
        modules = [./hosts/anya];
        specialArgs = {inherit inputs outputs;};
      };
      hummingbird = lib.nixosSystem {
        modules = [./hosts/hummingbird];
        specialArgs = {inherit inputs outputs;};
      };
      tailscale = lib.nixosSystem {
        modules = [./hosts/tailscale];
        specialArgs = {inherit inputs outputs;};
      };
      ca = lib.nixosSystem {
        modules = [./hosts/ca];
        specialArgs = {inherit inputs outputs;};
      };
      jellyfin = lib.nixosSystem {
        modules = [./hosts/jellyfin];
        specialArgs = {inherit inputs outputs;};
      };
    };

    # Available through 'home-manager --flake .#your-username@your-hostname'
    # NOTE: Home-manager requires a 'pkgs' instance
    homeConfigurations = {
      # For Testing
      "tk@nix-test" = lib.homeManagerConfiguration {
        modules = [./home/tk/nix-test.nix];
        pkgs = pkgsFor.x86_64-linux;
        extraSpecialArgs = {
          username = "tk";
          gitUser = "TimekillerTK";
          gitEmail = "38417175+TimekillerTK@users.noreply.github.com";
          inherit inputs outputs;
        };
      };

      # Laptop
      "tk@beltanimal" = lib.homeManagerConfiguration {
        modules = [./home/tk/beltanimal.nix];
        pkgs = pkgsFor.x86_64-linux;
        extraSpecialArgs = {
          username = "tk";
          gitUser = "TimekillerTK";
          gitEmail = "38417175+TimekillerTK@users.noreply.github.com";
          inherit inputs outputs;
        };
      };
      "astra@beltanimal" = lib.homeManagerConfiguration {
        modules = [./home/astra/beltanimal.nix];
        pkgs = pkgsFor.x86_64-linux;
        extraSpecialArgs = {
          username = "astra";
          gitUser = "Astram00n";
          gitEmail = "39217853+Astram00n@users.noreply.github.com";
          inherit inputs outputs;
        };
      };
      "bb@beltanimal" = lib.homeManagerConfiguration {
        modules = [./home/bb/beltanimal.nix];
        pkgs = pkgsFor.x86_64-linux;
        extraSpecialArgs = {
          username = "bb";
          inherit inputs outputs;
        };
      };

      # Desktop 1
      "tk@anya" = lib.homeManagerConfiguration {
        modules = [./home/tk/anya.nix];
        pkgs = pkgsFor.x86_64-linux;
        extraSpecialArgs = {
          username = "tk";
          gitUser = "TimekillerTK";
          gitEmail = "38417175+TimekillerTK@users.noreply.github.com";
          inherit inputs outputs;
        };
      };

      # Desktop 2
      "astra@hummingbird" = lib.homeManagerConfiguration {
        modules = [./home/astra/hummingbird.nix];
        pkgs = pkgsFor.x86_64-linux;
        extraSpecialArgs = {
          username = "astra";
          gitUser = "Astram00n";
          gitEmail = "39217853+Astram00n@users.noreply.github.com";
          inherit inputs outputs;
        };
      };
    };

    deploy.nodes = {
      # Desktop
      anya = {
        hostname = "anya.cyn.internal";
        profiles.system = {
          sshUser = "tk";
          user = "root";
          path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.anya;
        };
        profiles.tk = {
          sshUser = "tk";
          user = "tk";
          path = inputs.deploy-rs.lib.x86_64-linux.activate.custom self.homeConfigurations."tk@anya".activationPackage "$PROFILE/activate";
        };
      };
      # Laptop
      beltanimal = {
        hostname = "beltanimal.cyn.internal";
        profiles.system = {
          sshUser = "tk";
          user = "root";
          path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.beltanimal;
        };
        profiles.tk = {
          sshUser = "tk";
          user = "tk";
          path = inputs.deploy-rs.lib.x86_64-linux.activate.custom self.homeConfigurations."tk@beltanimal".activationPackage "$PROFILE/activate";
        };
      };
      # Router
      router = {
        hostname = "router.cyn.internal";
        profiles.system = {
          sshUser = "tk";
          user = "root";
          path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.router;
        };
      };
      # Dockerhost
      dockerhost = {
        hostname = "dockerhost.cyn.internal";
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
