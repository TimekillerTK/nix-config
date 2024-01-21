{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [
    # If you want to use modules your own flake exports (from modules/nixos):
    # outputs.nixosModules.example

    # Or modules from other flakes (such as nixos-hardware):
    # inputs.hardware.nixosModules.common-cpu-amd
    # inputs.hardware.nixosModules.common-ssd
    inputs.vscode-server.nixosModules.default

    # Generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix 

    # Repo Modules
    ../common/global
    ../common/kde-plasma-x11
  ];

  nixpkgs = {
    overlays = [
      # Flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.other-packages

      # You can also add overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    config = {
      allowUnfree = true;
    };
  };

  # WIP!
  boot.loader.grub = {
    # efiSupport = true;
    # efiInstallAsRemovable = true;
    devices = [ "/dev/sda" ];
  };

  # VS Code Server Module (for VS Code Remote)
  services.vscode-server.enable = true;

  # Hostname & Network Manager
  networking.hostName = "nix-test";
  networking.networkmanager.enable = true;

  # Enable ZSH
  programs.zsh.enable = true;

  # Configure your system-wide user settings (groups, etc), add more users as needed.
  users.users = {
    tk = {
      initialPassword = "Hello123!";
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
        (builtins.readFile ../common/ssh/mbp.pub)
        (builtins.readFile ../common/ssh/anya.pub)
      ];
      extraGroups = [ "networkmanager" "wheel" ];
    };
  };

  # Passwordless Sudo
  security.sudo.extraRules = [
    {
      users = ["tk"];
      commands = [
        {
          command = "ALL";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];

  # SSH Config
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # System Packages
  environment.systemPackages = with pkgs; [
    # pkgs.spaget # Custom package from /pkgs
    vim
  ];

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";

}
