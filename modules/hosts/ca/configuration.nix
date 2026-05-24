{inputs, ...}: {
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "ca";

  flake.modules.nixos.ca = {pkgs, ...}: {
    imports = [
      inputs.self.modules.nixos.system-minimal
      (inputs.self.factory.nix-auto-update {})
      inputs.self.modules.nixos.home-manager
      inputs.self.modules.nixos.tk
      inputs.self.modules.generic.prometheusTargets
    ];
    home-manager.users.tk = {
      imports = [
        inputs.self.modules.homeManager.system-minimal
      ];
      # Normal home-manager config stuff goes here
    };

    boot.kernelPackages = pkgs.linuxPackages_latest;

    # Hostname & Network Manager
    networking.hostName = "ca";
    networking.networkmanager.enable = true;

    # System Packages
    environment.systemPackages = with pkgs; [
      openssl
      step-cli
    ];

    # CA Config
    #
    # NOTE: Need to run `sudo step ca init` first to generate:
    #  - root CA key+cert
    #  - intermediate CA key+cert
    #  - ca.json file
    #
    # Next:
    #  - create `/root/password.txt` file
    #  - add ACME provisioner:
    #    - `step ca provisioner add acme --type ACME`
    #  - move /root/.step -> /etc/step-ca
    #  - fix paths @ /etc/step-ca/config/ca.json
    #  - fix paths @ /etc/step-ca/config/defaults.json
    #
    # Also required:
    #  - add CA root/intermediate certs to Nix config @ `security.pki/certificateFiles`

    # TODO: Uncomment this before running, it works,
    # temporarily commented out for -> nix flake check
    services.step-ca = {
      enable = true;
      port = 443;
      openFirewall = true;
      intermediatePasswordFile = "/root/password.txt";
      address = "ca.cyn.internal";
      settings = builtins.fromJSON (builtins.readFile ../common/ca.json);
    };
  };
}
