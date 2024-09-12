{
  inputs,
  outputs,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    # Required for VS Code Remote
    inputs.vscode-server.nixosModules.default

    # Generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix

    # Repo Modules
    ../common/global
    ../common/users/tk

  ];

  # Overlays
  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.other-packages
    ];
    config = {
      allowUnfree = true;
    };
  };

  # use default bash
  # TODO: find a better way to do this
  users.users.tk.shell = lib.mkForce pkgs.bash;
  users.users.tk.extraGroups = lib.mkForce [ "networkmanager" "wheel" "docker" ];

  # VS Code Server Module (for VS Code Remote)
  services.vscode-server.enable = true;

  # Hostname & Network Manager
  networking.hostName = "ca";
  networking.networkmanager.enable = true;

  # System Packages
  environment.systemPackages = with pkgs; [
    vim
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
  # services.step-ca = {
  #   enable = true;
  #   port = 443;
  #   openFirewall = true;
  #   intermediatePasswordFile = /root/password.txt;
  #   address = "ca.cyn.internal";
  #   settings = builtins.fromJSON (builtins.readFile ../common/ca.json);
  # };

  # Adding CA root & intermediate certs
  security.pki.certificateFiles = [
    ../common/root-ca.pem
  ];

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
